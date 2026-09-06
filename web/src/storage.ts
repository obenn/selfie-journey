import { HTTPError, choice, uuid, type Status, type Diagnostics } from "./validation";

const dayMilliseconds = 86400000;
export const retention = { feedbackDays: 180, telemetryDays: 30, aggregateDays: 365, diagnosticsDays: 30 } as const;
interface FeedbackRow extends Record<string, unknown> { id: string; created_at: number; source: string; category: string; status: string; message: string; contact_email: string | null; diagnostics_json: string | null; }
function summary(row: FeedbackRow) {
  return { id: row.id, createdAt: new Date(row.created_at).toISOString(), source: row.source, category: row.category, status: row.status, preview: row.message.slice(0, 180), hasDiagnostics: row.diagnostics_json !== null && row.created_at >= Date.now() - retention.diagnosticsDays * dayMilliseconds };
}
function detail(row: FeedbackRow) {
  return { id: row.id, createdAt: new Date(row.created_at).toISOString(), source: row.source, category: row.category, status: row.status, message: row.message, ...(row.contact_email ? { contactEmail: row.contact_email } : {}), ...(row.diagnostics_json ? { diagnostics: JSON.parse(row.diagnostics_json) as Diagnostics } : {}) };
}
export async function listFeedback(db: D1Database, params: URLSearchParams) {
  const clauses = ["created_at >= ?"], values: (string | number)[] = [Date.now() - retention.feedbackDays * dayMilliseconds];
  const status = params.get("status"), category = params.get("category"), query = params.get("q");
  if (status && status !== "all") { clauses.push("status = ?"); values.push(choice(status, ["new", "reviewing", "resolved"])); }
  if (category && category !== "all") { clauses.push("category = ?"); values.push(choice(category, ["bug", "idea", "other"])); }
  if (query) {
    if (query.length > 200) throw new HTTPError(400, "invalid_search", "Keep searches under 200 characters.");
    clauses.push("(message LIKE ? ESCAPE '\\' OR contact_email LIKE ? ESCAPE '\\')");
    const search = `%${query.replace(/[\\%_]/g, "\\$&")}%`; values.push(search, search);
  }
  const total = await db.prepare(`SELECT COUNT(*) AS count FROM feedback WHERE ${clauses.join(" AND ")}`).bind(...values).first<{ count: number }>();
  const cursor = params.get("cursor");
  if (cursor) {
    try {
      if (cursor.length > 200) throw new Error();
      const parsed: unknown = JSON.parse(atob(cursor));
      if (!Array.isArray(parsed) || parsed.length !== 2 || !Number.isSafeInteger(parsed[0]) || parsed[0] < 0) throw new Error();
      const id = uuid(parsed[1]);
      clauses.push("(created_at < ? OR (created_at = ? AND id < ?))"); values.push(parsed[0], parsed[0], id);
    } catch { throw new HTTPError(400, "invalid_cursor", "The page cursor is invalid."); }
  }
  const rawLimit = params.get("limit") ?? "25";
  if (!/^\d{1,2}$/.test(rawLimit) || Number(rawLimit) < 1 || Number(rawLimit) > 50) throw new HTTPError(400, "invalid_limit", "Choose a page size from 1 to 50.");
  const limit = Number(rawLimit);
  const results = await db.prepare(`SELECT * FROM feedback WHERE ${clauses.join(" AND ")} ORDER BY created_at DESC, id DESC LIMIT ?`).bind(...values, limit + 1).all<FeedbackRow>();
  const rows = results.results.slice(0, limit), last = rows.at(-1);
  return { items: rows.map(summary), total: total?.count ?? 0, nextCursor: results.results.length > limit && last ? btoa(JSON.stringify([last.created_at, last.id])) : null };
}
export async function getFeedback(db: D1Database, id: string) {
  const row = await db.prepare("SELECT * FROM feedback WHERE id = ? AND created_at >= ?").bind(uuid(id), Date.now() - retention.feedbackDays * dayMilliseconds).first<FeedbackRow>();
  if (!row) throw new HTTPError(404, "not_found", "Feedback was not found.");
  if (row.created_at < Date.now() - retention.diagnosticsDays * dayMilliseconds) row.diagnostics_json = null;
  return detail(row);
}
export async function updateFeedback(db: D1Database, id: string, status: Status) {
  const result = await db.prepare("UPDATE feedback SET status = ?, updated_at = ? WHERE id = ? AND created_at >= ? RETURNING id").bind(status, Date.now(), uuid(id), Date.now() - retention.feedbackDays * dayMilliseconds).first<{ id: string }>();
  if (!result) throw new HTTPError(404, "not_found", "Feedback was not found.");
  return { id: result.id, status };
}
export async function overview(db: D1Database, rangeDays: number) {
  if (![7, 30, 90].includes(rangeDays)) throw new HTTPError(400, "invalid_range", "Choose 7, 30, or 90 days.");
  const start = new Date(); start.setUTCHours(0, 0, 0, 0); start.setUTCDate(start.getUTCDate() - rangeDays + 1);
  const since = start.getTime(), day = start.toISOString().slice(0, 10);
  const [feedbackCounts, feedbackDaily, events, modes, dailyEvents, installations, versions, recent] = await db.batch<Record<string, unknown>>([
    db.prepare("SELECT COUNT(*) AS feedback, COALESCE(SUM(status = 'new'), 0) AS newFeedback, COALESCE(SUM(category = 'bug'), 0) AS bugReports FROM feedback WHERE created_at >= ?").bind(since),
    db.prepare("SELECT strftime('%Y-%m-%d', created_at / 1000, 'unixepoch') AS date, COUNT(*) AS count FROM feedback WHERE created_at >= ? GROUP BY date").bind(since),
    db.prepare("SELECT event_name AS name, SUM(count) AS count FROM telemetry_daily WHERE day >= ? GROUP BY event_name ORDER BY count DESC").bind(day),
    db.prepare("SELECT mode, SUM(count) AS count FROM telemetry_daily WHERE day >= ? GROUP BY mode").bind(day),
    db.prepare("SELECT day AS date, SUM(count) AS count FROM telemetry_daily WHERE day >= ? GROUP BY day ORDER BY day").bind(day),
    db.prepare("SELECT COUNT(DISTINCT installation_hash) AS count FROM telemetry_full WHERE created_at >= ?").bind(Math.max(since, Date.now() - retention.telemetryDays * dayMilliseconds)),
    db.prepare("SELECT app_version AS version, SUM(count) AS count FROM telemetry_full WHERE created_at >= ? GROUP BY app_version ORDER BY count DESC LIMIT 20").bind(Math.max(since, Date.now() - retention.telemetryDays * dayMilliseconds)),
    db.prepare("SELECT * FROM feedback WHERE created_at >= ? ORDER BY created_at DESC, id DESC LIMIT 5").bind(since),
  ]);
  const feedbackTotals = feedbackCounts.results[0];
  const eventCounts = events.results as { name: string; count: number }[];
  const feedbackByDay = new Map(feedbackDaily.results.map(row => [String(row.date), Number(row.count)]));
  const eventsByDay = new Map(dailyEvents.results.map(row => [String(row.date), Number(row.count)]));
  return {
    rangeDays, totals: { feedback: Number(feedbackTotals?.feedback ?? 0), newFeedback: Number(feedbackTotals?.newFeedback ?? 0), bugReports: Number(feedbackTotals?.bugReports ?? 0), events: eventCounts.reduce((sum, row) => sum + row.count, 0), fullInstallations: Number(installations.results[0]?.count ?? 0) },
    daily: Array.from({ length: rangeDays }, (_, index) => { const date = new Date(since + index * dayMilliseconds).toISOString().slice(0, 10); return { date, events: eventsByDay.get(date) ?? 0, feedback: feedbackByDay.get(date) ?? 0 }; }),
    eventCounts, telemetryModes: modes.results, versions: versions.results,
    recentFeedback: (recent.results as FeedbackRow[]).map(summary), retention,
  };
}
export async function cleanUp(db: D1Database, now = Date.now()) {
  await db.batch([
    db.prepare("DELETE FROM feedback WHERE created_at < ?").bind(now - retention.feedbackDays * dayMilliseconds),
    db.prepare("UPDATE feedback SET diagnostics_json = NULL WHERE created_at < ? AND diagnostics_json IS NOT NULL").bind(now - retention.diagnosticsDays * dayMilliseconds),
    db.prepare("DELETE FROM telemetry_full WHERE created_at < ?").bind(now - retention.telemetryDays * dayMilliseconds),
    db.prepare("DELETE FROM telemetry_batches WHERE created_at < ?").bind(now - retention.aggregateDays * dayMilliseconds),
    db.prepare("DELETE FROM telemetry_daily WHERE day < ?").bind(new Date(now - retention.aggregateDays * dayMilliseconds).toISOString().slice(0, 10)),
  ]);
}
