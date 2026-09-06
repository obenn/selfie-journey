import { createRemoteJWKSet, jwtVerify } from "jose";
import { HTTPError } from "./validation";

// Retain only public verification keys between requests. jose refreshes this
// bounded cache for key rotation; no token, cookie, or user state is retained.
let verificationKeys: { issuer: string; keys: ReturnType<typeof createRemoteJWKSet> } | undefined;

export async function authorizeAdmin(request: Request, env: WorkerEnv): Promise<void> {
  const domain = env.ACCESS_TEAM_DOMAIN.replace(/^https:\/\//, "").replace(/\/$/, "");
  if (!/^[a-z0-9-]+\.cloudflareaccess\.com$/.test(domain) || !env.ACCESS_AUDIENCE || env.ACCESS_AUDIENCE.startsWith("UNCONFIGURED") || !env.ADMIN_EMAIL) {
    throw new HTTPError(503, "admin_unavailable", "Administrator access is not configured yet.");
  }
  const token = request.headers.get("cf-access-jwt-assertion");
  if (!token || token.length > 16384) throw new HTTPError(403, "access_required", "Sign in through Cloudflare Access to continue.");
  try {
    const issuer = `https://${domain}`;
    if (verificationKeys?.issuer !== issuer) verificationKeys = { issuer, keys: createRemoteJWKSet(new URL(`${issuer}/cdn-cgi/access/certs`)) };
    const { payload } = await jwtVerify(token, verificationKeys.keys, { issuer, audience: env.ACCESS_AUDIENCE, algorithms: ["RS256"], requiredClaims: ["exp", "iat", "sub", "email"] });
    if (typeof payload.email !== "string" || payload.email.toLowerCase() !== env.ADMIN_EMAIL.toLowerCase()) throw new Error("email_not_allowed");
  } catch { throw new HTTPError(403, "access_denied", "Your administrator session is invalid or has expired."); }
}
