export class HTTPError extends Error {
  constructor(readonly status: number, readonly code: string, message: string) { super(message); }
}

// Read-only shape of diagnostic attachments submitted before collection ended.
export type Status = "new" | "reviewing" | "resolved";
export interface Diagnostics { appVersion: string; osVersion: string; deviceClass: "phone" | "tablet" | "other"; events: { code: string; ageSeconds: number }[]; }

function invalid(message: string): never { throw new HTTPError(400, "invalid_request", message); }
export function object(value: unknown, keys: string[]): Record<string, unknown> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) invalid("Expected a JSON object.");
  const item = value as Record<string, unknown>;
  if (Object.keys(item).some(key => !keys.includes(key))) invalid("The request contains an unsupported field.");
  return item;
}
export function uuid(value: unknown): string {
  if (typeof value !== "string" || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)) invalid("Expected a UUID.");
  return value.toLowerCase();
}
export function choice<T extends string>(value: unknown, choices: readonly T[]): T {
  if (typeof value !== "string" || !choices.includes(value as T)) invalid("A selection is invalid.");
  return value as T;
}
export async function readJSON(request: Request, maximum = 32768): Promise<unknown> {
  if (request.headers.get("content-type")?.split(";")[0]?.trim().toLowerCase() !== "application/json") throw new HTTPError(415, "json_required", "Send application/json.");
  const length = request.headers.get("content-length");
  if (length && (!/^\d+$/.test(length) || Number(length) > maximum)) throw new HTTPError(413, "request_too_large", "The request is too large.");
  if (!request.body) invalid("A JSON body is required.");
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = []; let total = 0;
  try {
    while (true) {
      const { done, value } = await reader.read(); if (done) break;
      total += value.byteLength;
      if (total > maximum) { await reader.cancel(); throw new HTTPError(413, "request_too_large", "The request is too large."); }
      chunks.push(value);
    }
  } finally { reader.releaseLock(); }
  const bytes = new Uint8Array(total); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
  try { return JSON.parse(new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }).decode(bytes)); }
  catch { invalid("The request is not valid JSON."); }
}
