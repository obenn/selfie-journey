export class HTTPError extends Error {
  constructor(readonly status: number, readonly code: string, message: string) { super(message); }
}

export const eventNames = ["app_open", "portrait_saved", "portrait_retake", "camera_opened", "camera_error", "backup_completed", "backup_error", "export_completed", "export_error", "feedback_opened"] as const;
export type EventName = typeof eventNames[number];
export type Category = "bug" | "idea" | "other";
export type Status = "new" | "reviewing" | "resolved";
export type DeviceClass = "phone" | "tablet" | "other";
export interface Diagnostics { appVersion: string; osVersion: string; deviceClass: DeviceClass; events: { code: EventName; ageSeconds: number }[]; }
export interface Feedback { submissionId: string; source: "ios" | "web"; category: Category; message: string; contactEmail?: string; diagnostics?: Diagnostics; }
export interface Telemetry { batchId: string; mode: "limited" | "full"; events: { name: EventName; count: number }[]; installationId?: string; appVersion?: string; osVersion?: string; deviceClass?: DeviceClass; }

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
function shortVersion(value: unknown): string {
  if (typeof value !== "string" || !/^\d{1,3}(?:\.\d{1,3}){0,3}(?:\s?\(\d{1,8}\))?$/.test(value)) invalid("Expected a numeric app or OS version.");
  return value;
}
function osVersion(value: unknown): string {
  if (typeof value !== "string" || !/^\d{1,3}\.\d{1,3}$/.test(value)) invalid("Expected a major and minor OS version.");
  return value;
}
function integer(value: unknown, min: number, max: number): number {
  if (typeof value !== "number" || !Number.isSafeInteger(value) || value < min || value > max) invalid("A number is outside the accepted range.");
  return value;
}
function diagnostics(value: unknown): Diagnostics {
  const item = object(value, ["appVersion", "osVersion", "deviceClass", "events"]);
  if (!Array.isArray(item.events) || item.events.length > 80) invalid("Attach at most 80 diagnostic events.");
  return {
    appVersion: shortVersion(item.appVersion), osVersion: osVersion(item.osVersion),
    deviceClass: choice(item.deviceClass, ["phone", "tablet", "other"]),
    events: item.events.map(value => {
      const event = object(value, ["code", "ageSeconds"]);
      return { code: choice(event.code, eventNames), ageSeconds: integer(event.ageSeconds, 0, 604800) };
    }),
  };
}
export function feedback(value: unknown): Feedback {
  const item = object(value, ["submissionId", "source", "category", "message", "contactEmail", "diagnostics"]);
  if (typeof item.message !== "string" || item.message.trim().length < 1 || item.message.length > 4000 || /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/.test(item.message)) invalid("Feedback must contain between 1 and 4,000 characters.");
  const result: Feedback = { submissionId: uuid(item.submissionId), source: choice(item.source, ["ios", "web"]), category: choice(item.category, ["bug", "idea", "other"]), message: item.message.trim() };
  if (item.contactEmail !== undefined) {
    if (typeof item.contactEmail !== "string" || item.contactEmail.length > 254 || !/^[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+$/.test(item.contactEmail)) invalid("Enter a valid contact email.");
    result.contactEmail = item.contactEmail.trim();
  }
  if (item.diagnostics !== undefined) {
    if (result.source !== "ios") invalid("Web feedback cannot include device diagnostics.");
    result.diagnostics = diagnostics(item.diagnostics);
  }
  return result;
}
export function telemetry(value: unknown): Telemetry {
  const item = object(value, ["batchId", "mode", "events", "installationId", "appVersion", "osVersion", "deviceClass"]);
  const mode = choice(item.mode, ["limited", "full"]);
  if (!Array.isArray(item.events) || item.events.length < 1 || item.events.length > eventNames.length) invalid("Send between 1 and 10 event totals.");
  const result: Telemetry = {
    batchId: uuid(item.batchId), mode,
    events: item.events.map(value => {
      const event = object(value, ["name", "count"]);
      return { name: choice(event.name, eventNames), count: integer(event.count, 1, 100) };
    }),
  };
  if (new Set(result.events.map(event => event.name)).size !== result.events.length) invalid("Event names must be unique within a batch.");
  if (mode === "limited") {
    if (["installationId", "appVersion", "osVersion", "deviceClass"].some(key => key in item)) invalid("Limited telemetry cannot include identifying or device metadata.");
  } else {
    result.installationId = uuid(item.installationId);
    result.appVersion = shortVersion(item.appVersion); result.osVersion = osVersion(item.osVersion);
    result.deviceClass = choice(item.deviceClass, ["phone", "tablet", "other"] as const);
  }
  return result;
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
