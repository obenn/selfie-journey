# Deployment history — 6 September 2026

## No-collection replacement — live

The replacement Worker and website were deployed successfully at **18:33:58 UTC on September 6, 2026**, deployment ID **`8686d2acd95c4131b412ea3600c3a3aa`**.

The website now uses external GitHub support links and explains the no-collection build, private iCloud backups, ordinary website requests, and historical retention. Former intake is retired; protected historical administration and cleanup remain. Worker observability is disabled in the deployment response.

Verified after deployment:

- Root, privacy, and support pages return 200; support links to GitHub and contains no submission form.
- `POST {}` to both `/v1/feedback` and `/v1/telemetry` on the API host returns **410**, `collection_retired`.
- Anonymous admin access redirects to Cloudflare Access (302).
- Workers.dev and preview URLs remain disabled; cron `17 4 * * *` is preserved.

Local checks passed 12 backend runtime tests, type checking, packaging, HTML/local-asset checks, and public/admin JavaScript syntax checks. Native build-2 validation passed 49 unit tests, 6 iPhone UI tests, and 1 iPad UI test. Its signed archive succeeded, but **build 2 has not uploaded to Apple**: export failed with `exportArchive Failed to Use Accounts` and missing Xcode credential keys while the Mac was locked. The website deployment does not publish the native app.

The GitHub repository remains private until its owner changes visibility. No public TestFlight invitation URL exists. See the exact remaining release steps in [App Store status](APP_STORE.md) and [TestFlight](TESTFLIGHT.md).

## Original service deployment — historical record

The public site, API, and protected admin dashboard were deployed to the Strikethrough Cloudflare account.

| Surface | Address |
| --- | --- |
| Promo | https://selfiejourney.com/ |
| Feedback | https://selfiejourney.com/support/ |
| Privacy | https://selfiejourney.com/privacy/ |
| Admin | https://admin.selfiejourney.com/ |
| API | https://api.selfiejourney.com/ |

The admin allows **oliver@strikethrough.com** through Cloudflare Access's existing email one-time PIN provider. No password or secret is embedded in the app or dashboard.

- Worker: `selfiejourney`; deployment `4e83b6d6e4704656a0ad71e113efad5e`.
- D1: `selfiejourney-data`, `65e6dddd-a004-4b7a-bb38-f4f9f05362d9`; migration `0001_feedback_telemetry.sql` applied and recorded.
- Access application: `85790c83-089f-4f54-8ccb-2510248d0e9a`.
- Reusable owner policy: `62944086-efae-4cd8-83f5-34a8c5fe715a`.
- Daily retention job: `17 4 * * *` (04:17 UTC).
- Workers.dev and preview URLs disabled. All static requests run through the Worker.
- Sampled logs/traces enabled, invocation logs disabled, query strings redacted.

Live checks returned 200 for public/support/privacy pages and API health. Anonymous admin HTML and API requests redirect to Access. Public/API requests for admin paths return 404. A website submission displayed a receipt; native-format feedback retained its selected fixed diagnostic event. Duplicate feedback returned one receipt. Full telemetry stored a hashed installation identifier; Limited created no Full-detail row. All synthetic feedback and telemetry from these checks were then removed.

Local validation passed: 15 backend runtime/security tests, TypeScript checking, Wrangler packaging, 62 iOS unit tests, and 8 UI test executions across full and targeted runs. An unsigned iPhone Release build also passed. The iOS privacy manifest is included in both simulator and Release app bundles and passes plist validation. The promo page was inspected in a browser at desktop and mobile widths; mobile horizontal overflow was fixed. Dashboard DOM checks cover rendering, safe text insertion, status updates, and expired sessions. Production admin sign-in requires the owner's email PIN and was not completed on their behalf.

After this original deployment, build 1 was uploaded to App Store Connect but no installable public beta link was created. The promo continues to use **Coming soon**. The original intake/reporting implementation described above is superseded by the no-collection replacement at the top of this document; keep this section only as deployment history.
