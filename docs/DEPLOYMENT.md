# Deployment record — 6 September 2026

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

The app is not on the App Store or TestFlight yet. The promo uses **Coming soon** until a real release link is available. Rebuild and run the current Xcode project to install the new native settings and reporting flow. See [operations](OPERATIONS.md) for subsequent deployments and release privacy disclosures.
