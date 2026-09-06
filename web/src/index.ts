import { authorizeAdmin } from "./auth";
import { HTTPError, choice, feedback, object, readJSON, telemetry } from "./validation";
import { cleanUp, getFeedback, listFeedback, overview, saveFeedback, saveTelemetry, updateFeedback } from "./storage";

const publicHost = "selfiejourney.com", apiHost = "api.selfiejourney.com", adminHost = "admin.selfiejourney.com";
const publicOrigin = `https://${publicHost}`, adminOrigin = `https://${adminHost}`;
const publicPaths = new Set(["/", "/index.html", "/privacy", "/privacy/", "/privacy/index.html", "/support", "/support/", "/support/index.html", "/favicon.svg", "/robots.txt", "/sitemap.xml"]);

function secured(response: Response, admin = false): Response {
  const result = new Response(response.body, response);
  result.headers.set("X-Content-Type-Options", "nosniff");
  result.headers.set("Referrer-Policy", "no-referrer");
  result.headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  result.headers.set("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
  result.headers.set("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'");
  if (admin || result.headers.get("content-type")?.includes("application/json")) result.headers.set("Cache-Control", "no-store");
  if (admin) result.headers.set("X-Robots-Tag", "noindex, nofollow, noarchive");
  return result;
}
function json(data: unknown, status = 200): Response { return Response.json(data, { status }); }
function cors(response: Response, request: Request): Response {
  if (new URL(request.url).hostname === apiHost && request.headers.get("origin") === publicOrigin) {
    response.headers.set("Access-Control-Allow-Origin", publicOrigin);
    response.headers.set("Vary", "Origin");
  }
  return response;
}
function notFound(): never { throw new HTTPError(404, "not_found", "This page was not found."); }
function requireMethod(request: Request, method: string): void {
  if (request.method !== method) throw new HTTPError(405, "method_not_allowed", `Use ${method} for this endpoint.`);
}
async function rateLimit(request: Request, binding: RateLimit): Promise<void> {
  // This edge-only, short-lived key is never written to D1 or application logs.
  const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
  if (!(await binding.limit({ key: ip })).success) throw new HTTPError(429, "rate_limited", "Please wait a minute and try again.");
}
function checkPublicOrigin(request: Request): void {
  const origin = request.headers.get("origin");
  if (origin !== null && origin !== publicOrigin) throw new HTTPError(403, "origin_denied", "This website cannot submit feedback here.");
}
async function admin(request: Request, env: WorkerEnv, url: URL): Promise<Response> {
  // Authenticate before handling ANY assets or API routes, including unknown paths.
  // Neither a forwarded email header nor an unverified JWT is an identity proof.
  await authorizeAdmin(request, env);
  if (url.pathname === "/api/admin/overview") {
    requireMethod(request, "GET");
    return json(await overview(env.DB, Number(url.searchParams.get("days") ?? "30")));
  }
  if (url.pathname === "/api/admin/feedback") {
    requireMethod(request, "GET"); return json(await listFeedback(env.DB, url.searchParams));
  }
  const detailPath = url.pathname.match(/^\/api\/admin\/feedback\/([a-fA-F0-9-]{36})$/);
  if (detailPath) {
    if (request.method === "GET") return json(await getFeedback(env.DB, detailPath[1]!));
    requireMethod(request, "PATCH");
    if (request.headers.get("origin") !== adminOrigin || request.headers.get("x-requested-with") !== "SelfieJourneyAdmin") throw new HTTPError(403, "origin_denied", "Make changes from the administrator dashboard.");
    const body = object(await readJSON(request, 1024), ["status"]);
    return json(await updateFeedback(env.DB, detailPath[1]!, choice(body.status, ["new", "reviewing", "resolved"])));
  }
  if (request.method !== "GET" && request.method !== "HEAD") notFound();
  // The assets binding serves folder indexes at a trailing slash. Fetching the
  // index.html path would redirect the browser instead of preserving this URL.
  if (url.pathname === "/") url.pathname = "/admin/";
  if (!url.pathname.startsWith("/admin/")) notFound();
  return env.ASSETS.fetch(new Request(url, request));
}
async function handle(request: Request, env: WorkerEnv): Promise<Response> {
  const url = new URL(request.url);
  if (![publicHost, apiHost, adminHost].includes(url.hostname) || url.port) notFound();
  if (url.protocol !== "https:") {
    url.protocol = "https:";
    return Response.redirect(url.toString(), 308);
  }
  // Reject ambiguous paths before delegating to the asset binding's normalization.
  if (/%(?:2f|5c|2e|25)/i.test(url.pathname) || url.pathname.includes("\\") || url.pathname.includes("//")) notFound();
  if (url.hostname === adminHost) return admin(request, env, url);
  if (url.pathname === "/v1/feedback" || (url.hostname === apiHost && url.pathname === "/v1/telemetry")) {
    checkPublicOrigin(request);
    if (request.method === "OPTIONS") {
      if (request.headers.get("origin") !== publicOrigin) throw new HTTPError(403, "origin_denied", "Origin is not allowed.");
      return new Response(null, { status: 204, headers: { "Access-Control-Allow-Origin": publicOrigin, "Access-Control-Allow-Methods": "POST", "Access-Control-Allow-Headers": "Content-Type", "Access-Control-Max-Age": "600", "Vary": "Origin" } });
    }
    requireMethod(request, "POST");
    if (url.pathname === "/v1/feedback") {
      await rateLimit(request, env.FEEDBACK_RATE_LIMITER);
      return json(await saveFeedback(env.DB, feedback(await readJSON(request))), 201);
    }
    await rateLimit(request, env.TELEMETRY_RATE_LIMITER);
    return json(await saveTelemetry(env.DB, telemetry(await readJSON(request))), 202);
  }
  if (url.hostname === apiHost && url.pathname === "/health" && request.method === "GET") return json({ status: "ok" });
  if (url.hostname !== publicHost) notFound();
  if (request.method !== "GET" && request.method !== "HEAD") notFound();
  if (!publicPaths.has(url.pathname) && !/^\/assets\/[a-zA-Z0-9_.-]+$/.test(url.pathname)) notFound();
  return env.ASSETS.fetch(request);
}
export default {
  async fetch(request, env) {
    const isAdmin = new URL(request.url).hostname === adminHost;
    try {
      const response = secured(await handle(request, env), isAdmin);
      return cors(response, request);
    } catch (error) {
      if (error instanceof HTTPError) {
        const response = secured(json({ error: { code: error.code, message: error.message } }, error.status), isAdmin);
        if (error.status === 429) response.headers.set("Retry-After", "60");
        return cors(response, request);
      }
      // Never log request bodies, contact emails, raw errors, URLs, or identifiers.
      console.error(JSON.stringify({ event: "request_failed" }));
      return cors(secured(json({ error: { code: "service_unavailable", message: "We could not complete that request. Please try again shortly." } }, 503), isAdmin), request);
    }
  },
  async scheduled(_controller, env) {
    await cleanUp(env.DB);
    console.info(JSON.stringify({ event: "retention_completed" }));
  },
} satisfies ExportedHandler<WorkerEnv>;
