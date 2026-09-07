# Deployment history

## Clear daily-selfie purpose and refreshed screenshots — live

The current website was deployed at **00:12:34 UTC on September 7, 2026** (**20:12:34 EDT on September 6**), deployment **`a220c401-cf84-464e-ba93-170405040f3f`**, Worker version **`98be3939-40f6-4d3b-ac65-8adfc77891df`**, serving 100% of traffic.

The shared headline is **“One selfie a day. Watch yourself change.”** The page now explains daily selfies, face-alignment guides before capture, and making a time-lapse video of real changes over months and years. Hero artwork, feature steps, support/privacy language, footers, and search/social metadata use the same concrete purpose. Refreshed native app screenshots include the current “Take today’s selfie” button. The website retains **Completely free. No subscriptions.** and **Coming soon** while external TestFlight review is pending.

Post-deployment verification confirmed:

- Root, privacy, and support return 200 with the current copy; support has external GitHub links and no submission form.
- `/assets/today.jpg` (690 × 1500) and `/assets/poses.jpg` (552 × 1200) return 200 and match the local release assets byte for byte.
- Retired feedback and telemetry intake still return 410; anonymous admin requests redirect to Cloudflare Access and public admin paths return 404.
- Worker observability, Workers.dev, and preview URLs remain disabled; the existing daily retention cron is unchanged.

The Wrangler package build passed. Temporary asset-upload credentials were removed after verification. Backend source, resource bindings, and native release status were unchanged by this website deployment.

## No-collection replacement — September 6, 2026

The replacement Worker and website were deployed successfully at **18:33:58 UTC on September 6, 2026**, deployment **`25b876f1-e1bd-4353-a997-1fb965456dd4`**, Worker version **`8686d2ac-d95c-4131-b412-ea3600c3a3aa`**.

The website now uses external GitHub support links and explains the no-collection build, private iCloud backups, ordinary website requests, and historical retention. Former intake is retired; protected historical administration and cleanup remain. Worker observability is disabled in the deployment response.

Verified after deployment:

- Root, privacy, and support pages return 200; support links to GitHub and contains no submission form.
- `POST {}` to both `/v1/feedback` and `/v1/telemetry` on the API host returns **410**, `collection_retired`.
- Anonymous admin access redirects to Cloudflare Access (302).
- Workers.dev and preview URLs remain disabled; cron `17 4 * * *` is preserved.

Local checks passed 12 backend runtime tests, type checking, packaging, HTML/local-asset checks, and public/admin JavaScript syntax checks. Native build-2 validation passed 49 unit tests, 6 iPhone UI tests, and 1 iPad UI test. Its signed archive succeeded. A later Xcode Organizer distribution successfully uploaded **1.0 (2)** after CLI account-credential errors; the build is now **Waiting for Review** for external TestFlight testing. The website deployment itself does not publish the native app.

The GitHub repository remains private until its owner changes visibility. The existing public TestFlight invitation is https://testflight.apple.com/join/ucGAbHsd; the latest build must pass beta review before it is available externally. See the remaining release steps in [App Store status](APP_STORE.md) and [TestFlight](TESTFLIGHT.md).

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
