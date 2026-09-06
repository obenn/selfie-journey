# Selfie Journey operations

This document describes the implemented service and release workflow. Successful local builds do not establish that a production deployment or App Store release has completed.

## Services and data flow

| Surface | Responsibility |
| --- | --- |
| `selfiejourney.com` | Static promotion, `/support/`, `/privacy/`, and same-origin web feedback. The download call to action remains Coming soon. |
| `api.selfiejourney.com` | Native app feedback and telemetry over HTTPS; `/health` reports Worker availability. |
| `admin.selfiejourney.com` | Cloudflare Access sign-in, feedback inbox, and reporting dashboard. |
| Cloudflare Worker `selfiejourney` | Host routing, authentication, validation, rate limiting, D1 queries, assets, daily retention job. |
| D1 `selfiejourney-data` | Feedback, ephemeral batch receipts, anonymous daily counts, and retained Full reporting details. |

Configuration is in `web/wrangler.jsonc`. Account: `eef43ffb7af8b4668e251f542e27d73d`. D1: `65e6dddd-a004-4b7a-bb38-f4f9f05362d9`. The Access team is `strikethrough.cloudflareaccess.com`; the intended administrator is `oliver@strikethrough.com`. `ACCESS_AUDIENCE` identifies this Access application. These resource identifiers are not credentials.

The native journal remains local SwiftData. Enabled backups send portraits and notes to the user's personal iCloud Drive, independently of Cloudflare. Cloudflare receives no portrait, journal note, face landmark, camera frame, location, or photo identifier through the app's reporting code. A user can voluntarily enter private information in a feedback message; handle those messages as private support data.

## App choices

Full is the initial selection. New-user setup explains it and allows Limited or Off before reporting starts. Existing installations receive a reporting-choice sheet before their first upload; a versioned acknowledgement gates automatic reporting. Settings can change the choice later, clear local diagnostic codes, or reset the Full identifier.

| Level | Automatic upload |
| --- | --- |
| Off | None. Explicit feedback remains available. |
| Limited | Allowlisted event totals and a random per-batch deduplication UUID. No persistent identifier or app/device metadata. |
| Full | Those totals plus a random installation UUID, app version, OS major/minor, and phone/tablet class. The server stores a SHA-256 digest of the installation UUID. |

Counts are buffered briefly in memory, capped at 100 per event per batch, and dropped after delivery failure. There is no persistent offline analytics queue. Changing the level cancels queued/in-flight work and discards unsent counts. Leaving Full removes its local identifier; re-enabling Full creates a new one. Cancellation cannot recall a request already received by the server. Resetting an identifier does not delete prior reports.

Feedback includes category, message, an optional email, and an optional reviewed diagnostic report. Logs default off. The local ring retains at most 80 fixed event codes for seven days; uploaded ages are rounded to minutes. It has no raw exception messages, stack traces, paths, or arbitrary logging text. Failed sends retain the currently open form; closing the form discards its draft. Retry an unchanged form with the same submission UUID to avoid duplicates.

## API contract

All writes use JSON. Request bodies are streamed with a 32 KiB maximum. Unsupported fields, invalid UUIDs, unknown event names, and excessive counts are rejected. API errors use `{ "error": { "code": "...", "message": "..." } }`.

| Endpoint | Contract |
| --- | --- |
| `POST /v1/feedback` | `submissionId`, `source` (`ios`/`web`), `category` (`bug`/`idea`/`other`), `message` (1–4,000 characters), optional `contactEmail`, optional iOS-only `diagnostics`. Returns 201 `{receiptId}`. |
| `POST /v1/telemetry` | `batchId`, `mode` (`limited`/`full`), 1–10 unique `{name,count}` events. Full requires `installationId`, `appVersion`, `osVersion`, `deviceClass`; Limited forbids them. Returns 202 `{accepted}` with the accepted count total. |
| `GET /api/admin/overview?days=7` | Allowed windows: 7, 30, 90. Daily counts, feedback totals, event/mode/version breakdowns, recent feedback, and observed Full installations. |
| `GET /api/admin/feedback` | `status`, `category`, literal-text `q`, `cursor`, `limit` (1–50). Returns items, total, next cursor. |
| `GET /api/admin/feedback/:id` | Private message details and any unexpired attached diagnostics. |
| `PATCH /api/admin/feedback/:id` | `{status: "new"|"reviewing"|"resolved"}` with exact admin Origin and `X-Requested-With: SelfieJourneyAdmin`. |

The event allowlist is `app_open`, `portrait_saved`, `portrait_retake`, `camera_opened`, `camera_error`, `backup_completed`, `backup_error`, `export_completed`, `export_error`, `feedback_opened`. Diagnostics use these same codes with `ageSeconds` rather than event counts.

Feedback retries return their original receipt. D1 batches atomically gate telemetry writes with a per-attempt receipt, so concurrent retries do not increment counts twice. Dashboard date buckets use server UTC. Full installation/version metrics cover at most the retained 30-day detail window, even for a 90-day chart; they are not an estimate of all users.

## Access and safeguards

Cloudflare Access uses an allow policy for the owner's email. The Worker also checks the Access JWT's RS256 signature, issuer, audience, expiration, required identity claims, and email. Public/API hosts cannot serve admin files or APIs. Missing Access configuration fails closed. Keep `assets.run_worker_first: true`, `workers_dev: false`, and `preview_urls: false` so asset delivery and alternate deployment URLs cannot bypass the host/authentication checks.

Public endpoints intentionally have no embedded app secret. Native rate-limit bindings use connection IP only as a transient key: feedback 5 requests/minute; telemetry 60/minute. Browser submission permits only the public website's Origin. Admin changes also require same-origin JSON and the custom header. SQL values are bound parameters. CSP, no-store admin responses, no-referrer, and HTTPS headers are applied by the Worker.

Application logs contain fixed operational event names, never request payloads, contact emails, identifiers, raw errors, or URLs. Cloudflare still processes connection information to deliver and secure requests; it is not added to the analytics database. Review provider logging and recovery settings when changing infrastructure.

## Retention and support handling

| Data | Operational retention |
| --- | --- |
| Feedback message and optional reply email | 180 days |
| Attached diagnostic report | 30 days |
| Full installation/version/event details | 30 days |
| Anonymous daily event totals and batch deduplication receipts | 365 days |
| Local diagnostic ring | 7 days, maximum 80 events |

The Worker cron runs daily at **04:17 UTC**. Admin reads exclude expired feedback and diagnostics even before the next cleanup. Cleanup removes expired operational rows; provider recovery copies follow their own retention. Marking a message resolved does not delete it. Handle deletion requests using the receipt or verified contact email and remove only the matching records; the dashboard currently has no deletion action. Anonymous aggregate totals cannot be traced back to a particular person.

## Development and deployment

Run from `web/` with the checked-in lockfile:

```sh
npm ci
npm run types
npm run typecheck
npm test
npm run build
```

`build` is Wrangler's dry-run packaging check. Tests use local Miniflare, ephemeral D1 databases, test signing keys, and fake outbound identity responses; they do not submit production feedback. Native automated tests/previews disable production support networking.

For local D1 development, run `npx wrangler d1 migrations apply selfiejourney-data --local`, then `npm run dev`. The production Worker rejects unknown hosts, so use a matching Host URL/header or the runtime tests for API verification. Do not remove the host guard to make a preview convenient.

Before deployment, verify `npx wrangler whoami`, the account/Worker/D1 IDs, the Access allow policy, and all three Worker custom domains. Preserve the configured audience and do not broaden the policy. With those targets confirmed:

```sh
npx wrangler d1 migrations apply selfiejourney-data --remote
npm run deploy
```

Keep credentials in Wrangler's authenticated profile or deployment secret store, outside source control. Apply schema changes as new migration files. Worker rollback does not undo D1 schema/data changes. After deployment, check public/support/privacy pages, API health, anonymous admin rejection or Access redirect, authenticated dashboard access, and one clearly identified feedback submission through to its receipt and admin detail. Remove that exact test record afterwards. Monitor fixed `request_failed` and `retention_completed` events without adding sensitive payload logging.

## App Store release privacy

`SelfieJourney/PrivacyInfo.xcprivacy` declares Device ID and Product Interaction for analytics, Other Diagnostic Data for analytics/support, and optional Email Address and Customer Support for app functionality. All are marked linked because Full groups events by an installation and submitted support data may include an email. None is used for advertising or cross-company tracking. These declarations describe the most data the app can collect, even when a particular user selects Limited or Off. Match the App Store Connect answers to the final build; the manifest does not replace those answers. [Apple's privacy detail guidance](https://developer.apple.com/app-store/app-privacy-details/).

The manifest's UserDefaults reason `CA92.1` covers app-only stored preferences, identifiers, and diagnostic codes. The reviewed code does not read other apps' defaults. Re-audit required-reason APIs and third-party packages when adding features. [Apple's required API reasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons).

Before submitting, validate the archive and bundled privacy manifest, generate Xcode's privacy report, and reconcile it with actual network payloads. Use `https://selfiejourney.com/privacy/` as the privacy-policy URL and `https://selfiejourney.com/support/` as support. Describe on-device face guidance and private iCloud backups separately from developer-accessible reporting. Confirm that reporting consent is presented on both fresh and upgraded installations and that every feature remains usable with reporting Off. [Apple's data collection requirements](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage).

Once an approved App Store or TestFlight link exists, update the Coming soon call to action in `web/public/index.html` and redeploy. Do not publish a placeholder store badge or invented download URL.
