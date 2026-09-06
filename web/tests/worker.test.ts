import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { build } from "esbuild";
import { Miniflare, convertV4MiniflareOptions } from "miniflare";
import { exportJWK, generateKeyPair, SignJWT } from "jose";
import { feedback, telemetry, HTTPError } from "../src/validation";

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
async function createRuntime(limit = 10000, audienceValue = audience, realAssets = false) {
  const runtime = new Miniflare(convertV4MiniflareOptions({
    name: "selfiejourney-test", modules: true, script, compatibilityDate: "2026-09-06",
    bindings: { ACCESS_TEAM_DOMAIN: "selfiejourney-test.cloudflareaccess.com", ACCESS_AUDIENCE: audienceValue, ADMIN_EMAIL: adminEmail },
    d1Databases: ["DB"],
    ...(realAssets
      ? { assets: { directory: assetDirectory, binding: "ASSETS", run_worker_first: true as const, routerConfig: { has_user_worker: true } } }
      : { serviceBindings: { ASSETS: async (request: Request) => new Response(`asset:${new URL(request.url).pathname}`, { headers: { "Content-Type": "text/html" } }) } }),
    outboundService: async request => new URL(request.url).href === `${issuer}/cdn-cgi/access/certs` ? Response.json({ keys: [key] }) : new Response(null, { status: 403 }),
    ratelimits: { FEEDBACK_RATE_LIMITER: { namespace_id: "10001", simple: { limit, period: 60 } }, TELEMETRY_RATE_LIMITER: { namespace_id: "10002", simple: { limit, period: 60 } } },
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
function submit(path: string, data: unknown, extra: Record<string, string> = {}, runtime = mf) {
  return runtime.dispatchFetch(`https://api.selfiejourney.com${path}`, { method: "POST", headers: { "Content-Type": "application/json", "CF-Connecting-IP": "192.0.2.10", ...extra }, body: JSON.stringify(data) });
}
function admin(path: string, headers: Record<string, string> = {}) { return mf.dispatchFetch(`https://admin.selfiejourney.com${path}`, { headers: { "cf-access-jwt-assertion": token, ...headers } }); }
function validFeedback() { return { submissionId: crypto.randomUUID(), source: "ios", category: "bug", message: "Camera closes when tapping save", diagnostics: { appVersion: "1.0 (2)", osVersion: "26.0", deviceClass: "phone", events: [{ code: "camera_error", ageSeconds: 12 }] } }; }
function limited() { return { batchId: crypto.randomUUID(), mode: "limited", events: [{ name: "app_open", count: 2 }] }; }

test("schema excludes raw logs, photos, and unrecognized metadata", () => {
  assert.throws(() => feedback({ ...validFeedback(), photos: "private" }), HTTPError);
  assert.throws(() => feedback({ ...validFeedback(), diagnostics: { ...validFeedback().diagnostics, events: [{ code: "raw_error", ageSeconds: 0 }] } }), HTTPError);
  assert.throws(() => feedback({ ...validFeedback(), diagnostics: { ...validFeedback().diagnostics, osVersion: "Oliver's iPhone" } }), HTTPError);
  assert.throws(() => feedback({ ...validFeedback(), source: "web" }), HTTPError);
  assert.throws(() => telemetry({ ...limited(), installationId: crypto.randomUUID() }), HTTPError);
  assert.throws(() => telemetry({ ...limited(), appVersion: "1.0" }), HTTPError);
  assert.throws(() => telemetry({ ...limited(), mode: "full" }), HTTPError);
  assert.throws(() => telemetry({ ...limited(), events: [{ name: "app_open", count: 101 }] }), HTTPError);
  assert.throws(() => telemetry({ ...limited(), events: [{ name: "app_open", count: 0 }] }), HTTPError);
  assert.throws(() => feedback({ ...validFeedback(), diagnostics: { ...validFeedback().diagnostics, osVersion: "26.0.12" } }), HTTPError);
});

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
  const runtime = await createRuntime(1000, "");
  try { assert.equal((await runtime.dispatchFetch("https://admin.selfiejourney.com/", { headers: { "cf-access-jwt-assertion": token } })).status, 503); }
  finally { await runtime.dispose(); }
});

test("feedback rejects malformed, oversized, non-JSON, and foreign-origin bodies", async () => {
  assert.equal((await submit("/v1/feedback", { ...validFeedback(), message: " " })).status, 400);
  assert.equal((await submit("/v1/feedback", { ...validFeedback(), message: "x".repeat(40000) })).status, 413);
  assert.equal((await submit("/v1/feedback", validFeedback(), { "Content-Type": "text/plain" })).status, 415);
  assert.equal((await submit("/v1/feedback", validFeedback(), { Origin: "https://evil.example" })).status, 403);
  const malformed = await mf.dispatchFetch("https://api.selfiejourney.com/v1/feedback", { method: "POST", headers: { "Content-Type": "application/json" }, body: "{" });
  assert.equal(malformed.status, 400);
  const invalidEncoding = await mf.dispatchFetch("https://api.selfiejourney.com/v1/feedback", { method: "POST", headers: { "Content-Type": "application/json" }, body: new Uint8Array([0xff, 0xfe]) });
  assert.equal(invalidEncoding.status, 400);
});

test("public browser CORS supports errors and never grants a foreign origin", async () => {
  const publicOrigin = "https://selfiejourney.com";
  const error = await submit("/v1/feedback", {}, { Origin: publicOrigin });
  assert.equal(error.status, 400); assert.equal(error.headers.get("Access-Control-Allow-Origin"), publicOrigin);
  const denied = await submit("/v1/feedback", validFeedback(), { Origin: "https://evil.example" });
  assert.equal(denied.status, 403); assert.equal(denied.headers.get("Access-Control-Allow-Origin"), null);
  const preflight = await mf.dispatchFetch("https://api.selfiejourney.com/v1/feedback", { method: "OPTIONS", headers: { Origin: publicOrigin, "Access-Control-Request-Method": "POST", "Access-Control-Request-Headers": "Content-Type" } });
  assert.equal(preflight.status, 204); assert.equal(preflight.headers.get("Access-Control-Allow-Origin"), publicOrigin);
});

test("feedback retries return one receipt and one stored row", async () => {
  const input = validFeedback();
  const responses = await Promise.all([submit("/v1/feedback", input), submit("/v1/feedback", input)]);
  const receipts = await Promise.all(responses.map(response => response.json() as Promise<{ receiptId: string }>));
  assert.equal(receipts[0]!.receiptId, receipts[1]!.receiptId);
  const db = await mf.getD1Database("DB");
  const result = await db.prepare("SELECT COUNT(*) AS count FROM feedback WHERE submission_id = ?").bind(input.submissionId).first<{ count: number }>();
  assert.equal(result!.count, 1);
  const detailResponse = await admin(`/api/admin/feedback/${receipts[0]!.receiptId}`);
  const detail = await detailResponse.json() as Record<string, unknown>;
  assert.equal(detail.message, input.message); assert.deepEqual(detail.diagnostics, input.diagnostics);
});

test("limited batches store only anonymous aggregates and deduplicate concurrent retries", async () => {
  const input = limited();
  assert.equal((await submit("/v1/telemetry", { ...input, installationId: crypto.randomUUID() })).status, 400);
  const responses = await Promise.all([submit("/v1/telemetry", input), submit("/v1/telemetry", input)]);
  assert(responses.every(response => response.status === 202));
  for (const response of responses) assert.deepEqual(await response.json(), { accepted: 2 });
  const db = await mf.getD1Database("DB");
  const count = await db.prepare("SELECT count FROM telemetry_daily WHERE mode = 'limited' AND event_name = 'app_open'").first<{ count: number }>();
  assert.equal(count!.count, 2);
  assert.equal((await db.prepare("SELECT COUNT(*) AS count FROM telemetry_full WHERE batch_id = ?").bind(input.batchId).first<{ count: number }>())!.count, 0);
  const receipt = await db.prepare("SELECT * FROM telemetry_batches WHERE batch_id = ?").bind(input.batchId).first();
  assert.deepEqual(Object.keys(receipt!).sort(), ["batch_id", "created_at", "receipt_id"]);
});

test("full telemetry hashes installation IDs and retains only validated context", async () => {
  const installationId = crypto.randomUUID();
  const input = { ...limited(), mode: "full", installationId, appVersion: "1.0", osVersion: "26.0", deviceClass: "phone" };
  assert.equal((await submit("/v1/telemetry", input)).status, 202);
  const db = await mf.getD1Database("DB");
  const row = await db.prepare("SELECT * FROM telemetry_full WHERE batch_id = ?").bind(input.batchId).first();
  assert.match(String(row!.installation_hash), /^[0-9a-f]{64}$/); assert(!JSON.stringify(row).includes(installationId));
  assert(!Object.keys(row!).some(key => /ip|email/.test(key)));
});

test("admin pagination and search handle literal wildcards and parameterize SQL", async () => {
  for (const message of ["literal 100% complete", "other completely different", "search quote ' OR 1=1 --"]) await submit("/v1/feedback", { ...validFeedback(), message });
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
  const receipt = await (await submit("/v1/feedback", validFeedback())).json() as { receiptId: string };
  const url = `https://admin.selfiejourney.com/api/admin/feedback/${receipt.receiptId}`;
  const options = { method: "PATCH", headers: { "cf-access-jwt-assertion": token, "Content-Type": "application/json", "X-Requested-With": "SelfieJourneyAdmin" }, body: JSON.stringify({ status: "resolved" }) };
  assert.equal((await mf.dispatchFetch(url, options)).status, 403);
  assert.equal((await mf.dispatchFetch(url, { ...options, headers: { ...options.headers, Origin: "https://evil.example" } })).status, 403);
  const response = await mf.dispatchFetch(url, { ...options, headers: { ...options.headers, Origin: "https://admin.selfiejourney.com" } });
  assert.equal(response.status, 200); assert.deepEqual(await response.json(), { id: receipt.receiptId, status: "resolved" });
});

test("overview returns actual totals, zero-filled dates, and bounded detail range", async () => {
  const response = await admin("/api/admin/overview?days=7");
  const data = await response.json() as { rangeDays: number; daily: unknown[]; totals: { events: number; feedback: number; fullInstallations: number }; retention: Record<string, number> };
  assert.equal(response.status, 200); assert.equal(data.rangeDays, 7); assert.equal(data.daily.length, 7);
  assert(data.totals.feedback > 0); assert.equal(data.totals.events, 4); assert.equal(data.totals.fullInstallations, 1);
  assert.equal(data.retention.diagnosticsDays, 30);
  assert.equal((await admin("/api/admin/overview?days=1000")).status, 400);
});

test("native rate limiter rejects repeated submissions", async () => {
  const runtime = await createRuntime(1);
  try {
    assert.equal((await submit("/v1/feedback", validFeedback(), {}, runtime)).status, 201);
    const second = await submit("/v1/feedback", validFeedback(), {}, runtime);
    assert.equal(second.status, 429); assert.equal(second.headers.get("Retry-After"), "60");
  } finally { await runtime.dispose(); }
});

test("real static assets keep the admin root at its URL and cannot bypass authorization", async () => {
  const runtime = await createRuntime(1000, audience, true);
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
      const receipt = await (await submit("/v1/feedback", validFeedback(), {}, runtime)).json() as { receiptId: string };
      ids.push(receipt.receiptId);
      await db.prepare("UPDATE feedback SET created_at = ? WHERE id = ?").bind(now - days * day, receipt.receiptId).run();
    }
    const beforeCleanup = await runtime.dispatchFetch(`https://admin.selfiejourney.com/api/admin/feedback/${ids[1]}`, { headers: { "cf-access-jwt-assertion": token } });
    assert.equal((await beforeCleanup.json() as Record<string, unknown>).diagnostics, undefined);
    const old = { ...limited(), mode: "full", installationId: crypto.randomUUID(), appVersion: "1.0", osVersion: "26.0", deviceClass: "phone" };
    await submit("/v1/telemetry", old, {}, runtime);
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
