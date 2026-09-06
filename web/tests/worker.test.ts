import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { build } from "esbuild";
import { Miniflare, convertV4MiniflareOptions } from "miniflare";
import { exportJWK, generateKeyPair, SignJWT } from "jose";
import worker from "../src/index";

const issuer = "https://selfiejourney-test.cloudflareaccess.com";
const audience = "test-only-audience";
const adminEmail = "oliver@strikethrough.com";
const keyPair = await generateKeyPair("RS256", { extractable: true });
const key = { ...await exportJWK(keyPair.publicKey), kid: "runtime-test-key", alg: "RS256", use: "sig" };
let mf: Miniflare;
let script: string;
let migration: string;
let token: string;
let assetDirectory: string;

async function signed(overrides: { email?: string; aud?: string; exp?: number; iss?: string } = {}) {
  return new SignJWT({ email: overrides.email ?? adminEmail }).setProtectedHeader({ alg: "RS256", kid: key.kid }).setSubject("test-admin")
    .setIssuedAt().setIssuer(overrides.iss ?? issuer).setAudience(overrides.aud ?? audience).setExpirationTime(overrides.exp ?? Math.floor(Date.now() / 1000) + 600).sign(keyPair.privateKey);
}
async function createRuntime(audienceValue = audience, realAssets = false) {
  const runtime = new Miniflare(convertV4MiniflareOptions({
    name: "selfiejourney-test", modules: true, script, compatibilityDate: "2026-09-06",
    bindings: { ACCESS_TEAM_DOMAIN: "selfiejourney-test.cloudflareaccess.com", ACCESS_AUDIENCE: audienceValue, ADMIN_EMAIL: adminEmail },
    d1Databases: ["DB"],
    ...(realAssets
      ? { assets: { directory: assetDirectory, binding: "ASSETS", run_worker_first: true as const, routerConfig: { has_user_worker: true } } }
      : { serviceBindings: { ASSETS: async (request: Request) => new Response(`asset:${new URL(request.url).pathname}`, { headers: { "Content-Type": "text/html" } }) } }),
    outboundService: async request => new URL(request.url).href === `${issuer}/cdn-cgi/access/certs` ? Response.json({ keys: [key] }) : new Response(null, { status: 403 }),
  }));
  const db = await runtime.getD1Database("DB");
  for (const statement of migration.replace(/--[^\n]*/g, "").split(";").filter(value => value.trim())) await db.prepare(statement).run();
  return runtime;
}
before(async () => {
  const output = await build({ entryPoints: ["src/index.ts"], bundle: true, write: false, format: "esm", target: "es2022", platform: "browser" });
  script = output.outputFiles[0]!.text;
  migration = await readFile("migrations/0001_feedback_telemetry.sql", "utf8");
  assetDirectory = await mkdtemp(join(tmpdir(), "selfiejourney-assets-test-"));
  await mkdir(join(assetDirectory, "admin"));
  await writeFile(join(assetDirectory, "index.html"), "<h1>Public test fixture</h1>");
  await writeFile(join(assetDirectory, "admin", "index.html"), "<h1>Private test fixture</h1>");
  await writeFile(join(assetDirectory, "admin", "admin.js"), "/* Private test script */");
  token = await signed(); mf = await createRuntime();
});
after(async () => { await mf?.dispose(); if (assetDirectory) await rm(assetDirectory, { recursive: true, force: true }); });
function admin(path: string, headers: Record<string, string> = {}) { return mf.dispatchFetch(`https://admin.selfiejourney.com${path}`, { headers: { "cf-access-jwt-assertion": token, ...headers } }); }
const legacyDiagnostics = { appVersion: "1.0 (1)", osVersion: "26.0", deviceClass: "phone", events: [{ code: "camera_error", ageSeconds: 12 }] };

// Fixtures represent data retained from earlier builds; production has no writers.
async function seedFeedback(runtime = mf, message = "Camera closes when tapping save", createdAt = Date.now()) {
  const db = await runtime.getD1Database("DB"), id = crypto.randomUUID();
  await db.prepare("INSERT INTO feedback (id, submission_id, created_at, updated_at, source, category, message, diagnostics_json) VALUES (?, ?, ?, ?, 'ios', 'bug', ?, ?)")
    .bind(id, crypto.randomUUID(), createdAt, createdAt, message, JSON.stringify(legacyDiagnostics)).run();
  return id;
}
async function seedTelemetry(runtime = mf, createdAt = Date.now()) {
  const db = await runtime.getD1Database("DB"), batch = crypto.randomUUID(), day = new Date(createdAt).toISOString().slice(0, 10);
  await db.prepare("INSERT INTO telemetry_batches VALUES (?, ?, ?)").bind(batch, crypto.randomUUID(), createdAt).run();
  await db.prepare("INSERT INTO telemetry_daily VALUES (?, 'full', 'app_open', 2)").bind(day).run();
  await db.prepare("INSERT INTO telemetry_full (batch_id, created_at, installation_hash, app_version, os_version, device_class, event_name, count) VALUES (?, ?, ?, '1.0', '26.0', 'phone', 'app_open', 2)")
    .bind(batch, createdAt, "a".repeat(64)).run();
}

test("public hosts cannot expose admin HTML, assets, APIs, or encoded routes", async () => {
  for (const host of ["selfiejourney.com", "api.selfiejourney.com", "selfiejourney.workers.dev", "preview.example.com"]) {
    for (const path of ["/admin/index.html", "/admin/admin.js", "/api/admin/feedback", "/%61dmin/index.html", "/admin%2findex.html"]) {
      const response = await mf.dispatchFetch(`https://${host}${path}`, { headers: { "cf-access-jwt-assertion": token } });
      assert.equal(response.status, 404, `${host}${path}`);
    }
  }
  assert.equal((await mf.dispatchFetch("https://selfiejourney.com/")).status, 200);
});

test("every admin route requires verified Access identity", async () => {
  for (const path of ["/", "/admin/admin.js", "/api/admin/overview", "/unknown"]) {
    const noToken = await mf.dispatchFetch(`https://admin.selfiejourney.com${path}`, { headers: { "Cf-Access-Authenticated-User-Email": adminEmail } });
    assert.equal(noToken.status, 403);
  }
  for (const bad of ["not.a.jwt", await signed({ email: "stranger@example.com" }), await signed({ aud: "other-app" }), await signed({ exp: 1 }), await signed({ iss: "https://other.cloudflareaccess.com" })]) {
    assert.equal((await admin("/", { "cf-access-jwt-assertion": bad })).status, 403);
  }
  const response = await admin("/");
  assert.equal(response.status, 200); assert.equal(await response.text(), "asset:/admin/");
  assert.equal(response.headers.get("Cache-Control"), "no-store");
  assert.match(response.headers.get("Content-Security-Policy")!, /frame-ancestors 'none'/);
});

test("missing Access configuration fails closed", async () => {
  const runtime = await createRuntime("");
  try { assert.equal((await runtime.dispatchFetch("https://admin.selfiejourney.com/", { headers: { "cf-access-jwt-assertion": token } })).status, 503); }
  finally { await runtime.dispose(); }
});

test("retired collection routes reject every method, body, and origin without storage", async () => {
  const db = await mf.getD1Database("DB");
  for (const host of ["selfiejourney.com", "api.selfiejourney.com"]) {
    for (const path of ["/v1/feedback", "/v1/telemetry"]) {
      for (const method of ["POST", "PUT", "GET", "OPTIONS"]) {
        const response = await mf.dispatchFetch(`https://${host}${path}`, {
          method, headers: { "Content-Type": "text/plain", "Origin": "https://evil.example" },
          ...(method === "POST" || method === "PUT" ? { body: "malformed and private payload" } : {}),
        });
        assert.equal(response.status, 410, `${method} ${host}${path}`);
        assert.equal((await response.json() as { error: { code: string } }).error.code, "collection_retired");
        assert.equal(response.headers.get("Access-Control-Allow-Origin"), null);
        assert.equal(response.headers.get("Cache-Control"), "no-store");
      }
    }
  }
  for (const table of ["feedback", "telemetry_batches", "telemetry_daily", "telemetry_full"]) {
    assert.equal((await db.prepare(`SELECT COUNT(*) AS count FROM ${table}`).first<{ count: number }>())?.count, 0);
  }
});

test("retired handlers never read bodies or access bindings, even if both are unavailable", async () => {
  const unavailableEnv: WorkerEnv = {
    get DB(): never { throw new Error("must not access storage"); },
    get ASSETS(): never { throw new Error("must not proxy a rejected body"); },
    get FEEDBACK_RATE_LIMITER(): never { throw new Error("must not process an IP"); },
    get TELEMETRY_RATE_LIMITER(): never { throw new Error("must not process an IP"); },
    get ACCESS_TEAM_DOMAIN(): never { throw new Error("must not call a service"); },
    get ACCESS_AUDIENCE(): never { throw new Error("must not call a service"); },
    get ADMIN_EMAIL(): never { throw new Error("must not call a service"); },
  };
  for (const path of ["/v1/feedback", "/v1/telemetry"]) {
    const request = new Request<unknown, IncomingRequestCfProperties>(`https://api.selfiejourney.com${path}`, { method: "POST", body: "private" });
    for (const property of ["body", "json", "text", "arrayBuffer", "formData", "blob"]) {
      Object.defineProperty(request, property, { get() { throw new Error("must not read the payload"); } });
    }
    const response = await worker.fetch(request, unavailableEnv);
    assert.equal(response.status, 410);
    assert.equal(request.bodyUsed, false);
  }
});

test("retirement response is readable by the old website but does not allow new submissions", async () => {
  for (const method of ["POST", "OPTIONS"]) {
    const response = await mf.dispatchFetch("https://api.selfiejourney.com/v1/feedback", {
      method, headers: { Origin: "https://selfiejourney.com", "Access-Control-Request-Method": "POST" },
    });
    assert.equal(response.status, 410);
    assert.equal(response.headers.get("Access-Control-Allow-Origin"), "https://selfiejourney.com");
    assert.equal(response.headers.get("Access-Control-Allow-Methods"), null);
  }
});

test("historical feedback remains readable only by the administrator", async () => {
  const id = await seedFeedback();
  const response = await admin(`/api/admin/feedback/${id}`);
  assert.equal(response.status, 200);
  const detail = await response.json() as Record<string, unknown>;
  assert.equal(detail.message, "Camera closes when tapping save");
  assert.deepEqual(detail.diagnostics, legacyDiagnostics);
});

test("admin pagination and search handle literal wildcards and parameterize SQL", async () => {
  for (const message of ["literal 100% complete", "other completely different", "search quote ' OR 1=1 --"]) await seedFeedback(mf, message);
  const search = await admin("/api/admin/feedback?q=%25");
  const found = await search.json() as { items: { id: string }[]; total: number };
  assert.equal(found.total, 1);
  const page1 = await (await admin("/api/admin/feedback?limit=1")).json() as { items: { id: string }[]; nextCursor: string; total: number };
  const page2 = await (await admin(`/api/admin/feedback?limit=1&cursor=${encodeURIComponent(page1.nextCursor)}`)).json() as { items: { id: string }[] };
  assert.notEqual(page1.items[0]!.id, page2.items[0]!.id);
  assert.equal((await admin("/api/admin/feedback?status=invalid")).status, 400);
  assert.equal((await admin("/api/admin/feedback?limit=10000")).status, 400);
});

test("admin mutations require same-origin CSRF headers", async () => {
  const id = await seedFeedback();
  const url = `https://admin.selfiejourney.com/api/admin/feedback/${id}`;
  const options = { method: "PATCH", headers: { "cf-access-jwt-assertion": token, "Content-Type": "application/json", "X-Requested-With": "SelfieJourneyAdmin" }, body: JSON.stringify({ status: "resolved" }) };
  assert.equal((await mf.dispatchFetch(url, options)).status, 403);
  assert.equal((await mf.dispatchFetch(url, { ...options, headers: { ...options.headers, Origin: "https://evil.example" } })).status, 403);
  const response = await mf.dispatchFetch(url, { ...options, headers: { ...options.headers, Origin: "https://admin.selfiejourney.com" } });
  assert.equal(response.status, 200); assert.deepEqual(await response.json(), { id, status: "resolved" });
});

test("overview returns historical totals, zero-filled dates, and bounded detail range", async () => {
  await seedTelemetry();
  const response = await admin("/api/admin/overview?days=7");
  const data = await response.json() as { rangeDays: number; daily: unknown[]; totals: { events: number; feedback: number; fullInstallations: number }; retention: Record<string, number> };
  assert.equal(response.status, 200); assert.equal(data.rangeDays, 7); assert.equal(data.daily.length, 7);
  assert(data.totals.feedback > 0); assert.equal(data.totals.events, 2); assert.equal(data.totals.fullInstallations, 1);
  assert.equal(data.retention.diagnosticsDays, 30);
  assert.equal((await admin("/api/admin/overview?days=1000")).status, 400);
});

test("real static assets keep the admin root at its URL and cannot bypass authorization", async () => {
  const runtime = await createRuntime(audience, true);
  try {
    for (const path of ["/", "/admin/", "/admin/index.html", "/admin/admin.js"]) {
      const blocked = await runtime.dispatchFetch(`https://admin.selfiejourney.com${path}`);
      assert.equal(blocked.status, 403, `${path}: ${await blocked.text()}`);
    }
    const response = await runtime.dispatchFetch("https://admin.selfiejourney.com/", { headers: { "cf-access-jwt-assertion": token }, redirect: "manual" });
    assert.equal(response.status, 200); assert.equal(response.headers.get("Location"), null);
    assert.match(await response.text(), /Private test fixture/);
    assert.equal((await runtime.dispatchFetch("https://selfiejourney.com/admin/")).status, 404);
    assert.equal((await runtime.dispatchFetch("https://selfiejourney.com/")).status, 200);
  } finally { await runtime.dispose(); }
});

test("retention hides expired diagnostics immediately and cron removes expired stored data", async () => {
  const runtime = await createRuntime();
  try {
    const db = await runtime.getD1Database("DB");
    const now = Date.now(), day = 86400000;
    const ids: string[] = [];
    for (const days of [7, 31, 181]) {
      ids.push(await seedFeedback(runtime, "Legacy report", now - days * day));
    }
    const beforeCleanup = await runtime.dispatchFetch(`https://admin.selfiejourney.com/api/admin/feedback/${ids[1]}`, { headers: { "cf-access-jwt-assertion": token } });
    assert.equal((await beforeCleanup.json() as Record<string, unknown>).diagnostics, undefined);
    await seedTelemetry(runtime);
    await db.prepare("UPDATE telemetry_full SET created_at = ?").bind(now - 31 * day).run();
    await db.prepare("UPDATE telemetry_batches SET created_at = ?").bind(now - 366 * day).run();
    await db.prepare("INSERT INTO telemetry_daily VALUES (?, 'limited', 'app_open', 1)").bind(new Date(now - 366 * day).toISOString().slice(0, 10)).run();
    const worker = await runtime.getWorker();
    await worker.scheduled({ scheduledTime: new Date(now), cron: "17 4 * * *" });
    assert.equal((await db.prepare("SELECT COUNT(*) AS count FROM feedback").first<{ count: number }>())?.count, 2);
    assert.equal((await db.prepare("SELECT diagnostics_json FROM feedback WHERE id = ?").bind(ids[1]).first<{ diagnostics_json: string | null }>())?.diagnostics_json, null);
    assert((await db.prepare("SELECT diagnostics_json FROM feedback WHERE id = ?").bind(ids[0]).first<{ diagnostics_json: string | null }>())?.diagnostics_json);
    for (const table of ["telemetry_full", "telemetry_batches"]) assert.equal((await db.prepare(`SELECT COUNT(*) AS count FROM ${table}`).first<{ count: number }>())?.count, 0);
    assert.equal((await db.prepare("SELECT COUNT(*) AS count FROM telemetry_daily").first<{ count: number }>())?.count, 1);
  } finally { await runtime.dispose(); }
});
