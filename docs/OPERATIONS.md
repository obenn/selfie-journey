# Selfie Journey operations

This document describes the no-collection implementation for **1.0 build 2**. The Worker/website replacement is live as deployment `8686d2acd95c4131b412ea3600c3a3aa`; build 2 has a signed archive but its Apple upload is blocked by Xcode account credentials while the Mac is locked. See [deployment history](DEPLOYMENT.md) and [release status](APP_STORE.md).

## Surfaces

| Surface | Responsibility |
| --- | --- |
| `selfiejourney.com` | Static promotion, external GitHub support links, and privacy notes. Download CTA stays Coming soon until a verified install URL exists. |
| `api.selfiejourney.com` | Health check and explicit rejection of retired collection routes; no current native app traffic. |
| `admin.selfiejourney.com` | Protected access to historical feedback and reporting records only. |
| Worker `selfiejourney` | Host routing, authentication, static assets, historical admin queries, and retention cleanup. |
| D1 `selfiejourney-data` | Retained historical records until their original retention periods expire. |

Configuration is in `web/wrangler.jsonc`. Account: `eef43ffb7af8b4668e251f542e27d73d`. D1: `65e6dddd-a004-4b7a-bb38-f4f9f05362d9`. Access team: `strikethrough.cloudflareaccess.com`. The only allowed administrator is `oliver@strikethrough.com`; preserve the configured audience. These resource identifiers are not credentials.

The native journal remains local SwiftData. Optional backups use the user's private iCloud Drive, with no developer access. The app has no analytics client, installation identifier, diagnostic ring, feedback uploader, or server push. Upgrade migration removes only obsolete reporting/log defaults. Settings opens `https://github.com/obenn/selfie-journey/issues` in the system browser without attaching any app data.

The GitHub repository is currently private; its owner plans to make it public. A link does not change repository visibility. Verify public accessibility after that owner action before describing GitHub support as publicly available.

## Retired collection routes

`/v1/feedback` and `/v1/telemetry` on both public and API hosts return **410 Gone for every HTTP method**. Response JSON uses `error.code = "collection_retired"` and explains that feedback and analytics collection has ended, directing users to the GitHub project.

These branches do not read request bodies, access IP rate-limit bindings, persist data, or emit application logs. Intake validators and storage writers are removed. Old installed builds can attempt requests but cannot add collection records after this Worker version is deployed. Do not restore the old handlers when changing unrelated routing.

## Historical administrator APIs

| Endpoint | Purpose |
| --- | --- |
| `GET /api/admin/overview?days=7` | Historical activity for 7, 30, or 90 days. Retained Full detail covers at most 30 days. |
| `GET /api/admin/feedback` | Historical status/category/search filters, cursor, and page limit. |
| `GET /api/admin/feedback/:id` | Historical message and any unexpired diagnostics. |
| `PATCH /api/admin/feedback/:id` | Update status to new, reviewing, or resolved; exact admin Origin and `X-Requested-With: SelfieJourneyAdmin` required. |

No historical database or remote resource is deleted as part of disabling intake. The old dashboard reflects past reports rather than current app use. Resolved status does not delete a record.

Cloudflare Access restricts sign-in to the owner. The Worker independently checks the Access JWT signature, issuer, audience, expiry, and email. Public/API hosts cannot serve admin files or APIs. Missing Access configuration fails closed. Keep `assets.run_worker_first: true`, `workers_dev: false`, and `preview_urls: false` so alternate paths cannot bypass protection. Admin reads are no-store, and SQL parameters remain bound.

## Retention

| Historical data | Retention |
| --- | --- |
| Feedback message and optional email | 180 days |
| Diagnostic attachment | 30 days |
| Installation-linked usage/version details | 30 days |
| Anonymous aggregate totals and deduplication receipts | 365 days |

The daily job remains **04:17 UTC**, cron `17 4 * * *`. Admin reads exclude expired messages/diagnostics before cleanup. Provider recovery copies follow their provider retention. Deletion requests should be handled privately using a verified contact or feedback reference, removing only matching records. Do not ask users to post private deletion requests on GitHub.

Worker Logs and Traces are disabled explicitly, including persisted logs/traces. Cloudflare still processes ordinary connection information to deliver and secure website requests. Historical administrator sign-in uses Access and its session cookies. These website operations are separate from the native app's no-collection behavior.

## Validation and deployment

Run from `web/`:

```sh
npm ci
npm run types
npm run typecheck
npm test
npm run build
```

The retirement change passed **12 runtime tests**, type generation, TypeScript checking, and Wrangler dry-run packaging. Tests exercise real local Worker/D1 behavior, protected historical routes, retention, and retired routes that must never read bodies or bindings. They do not mutate production data.

Before deployment, verify the account/Worker/D1 targets and preserve Access rules, audience, domains, and retention schedule. No new database migration is required for retirement. Use an authorized Cloudflare connection or an authenticated Wrangler profile, with credentials outside the repository. Worker rollback must not re-enable intake unintentionally.

After deployment, verify public/support/privacy pages, health, 410 on both retired paths and both hosts, absence of new D1 records, anonymous admin rejection, and intact historical retention. Do not submit synthetic feedback expecting a receipt; successful ingestion would now be a regression. Confirm public pages no longer load `support.js` or contain a feedback form.

## App Store privacy

The replacement build's `PrivacyInfo.xcprivacy` has no collected data types, `NSPrivacyTracking = false`, and app-only UserDefaults reason `CA92.1`. App Store Connect's **Data Not Collected** answer must be paired with **build 2**, not the earlier collection-enabled build 1. The manifest does not replace the Connect form. Validate the bundled manifest and absence of collection transport before archive/upload. [Apple's privacy details guidance](https://developer.apple.com/app-store/app-privacy-details/).

Use `https://selfiejourney.com/privacy/` for privacy policy and choices, and `https://selfiejourney.com/support/` for support. The privacy policy distinguishes local/on-device work, private iCloud backups, voluntary external GitHub activity, website hosting, and historical retention. Keep every feature usable without an app account or a support submission.
