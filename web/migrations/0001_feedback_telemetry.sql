CREATE TABLE feedback (
  id TEXT PRIMARY KEY NOT NULL,
  submission_id TEXT UNIQUE NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  source TEXT NOT NULL CHECK (source IN ('ios','web')),
  category TEXT NOT NULL CHECK (category IN ('bug','idea','other')),
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new','reviewing','resolved')),
  message TEXT NOT NULL,
  contact_email TEXT,
  diagnostics_json TEXT
);
CREATE INDEX feedback_created ON feedback(created_at DESC, id DESC);
CREATE INDEX feedback_status_created ON feedback(status, created_at DESC);

-- Idempotency receipts contain no installation, IP, device, or event information.
CREATE TABLE telemetry_batches (batch_id TEXT PRIMARY KEY NOT NULL, receipt_id TEXT NOT NULL, created_at INTEGER NOT NULL);
CREATE INDEX telemetry_batches_created ON telemetry_batches(created_at);

CREATE TABLE telemetry_daily (
  day TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('limited','full')),
  event_name TEXT NOT NULL,
  count INTEGER NOT NULL,
  PRIMARY KEY (day, mode, event_name)
);

CREATE TABLE telemetry_full (
  batch_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  installation_hash TEXT NOT NULL,
  app_version TEXT NOT NULL,
  os_version TEXT NOT NULL,
  device_class TEXT NOT NULL,
  event_name TEXT NOT NULL,
  count INTEGER NOT NULL,
  PRIMARY KEY (batch_id, event_name)
);
CREATE INDEX telemetry_full_created ON telemetry_full(created_at);
CREATE INDEX telemetry_full_installation ON telemetry_full(installation_hash, created_at);
