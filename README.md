# Selfie Journey

**A moment today. A lifetime of you.**

A native iPhone and iPad journal for one portrait a day. Find a familiar frame, keep a small daily streak, and watch the ordinary moments become a film of your life.

Built with SwiftUI, SwiftData, AVFoundation, Vision, PhotosUI, UserNotifications, iCloud Drive, and CryptoKit. The iOS app has no third-party packages or separate account. A small Cloudflare service handles optional feedback and configurable usage and reliability reporting; portraits and journal notes stay outside that service.

## The experience

- **A personal start:** first-open setup chooses one of four portrait distances and a daily reminder time. Notification permission is requested from the Enable button; skipping is always available. Change both later in Your daily ritual.
- **A reason to return:** a prominent streak card, weekly completion marks, progress toward milestones, and a small save celebration. Missing a day never removes the portraits already collected.
- **A familiar frame:** a mirrored front camera with pose-specific guides and an optional three-second timer. An adjustable ghost overlay uses a previous portrait with the same pose.
- **Live guidance:** Apple's on-device Vision landmarks help with distance, centering, eye height, and head angle. Brightness checks suggest more frontal light or less backlighting. Hints are advisory; capture stays under the user's control.
- **A portrait journal:** review, retake, notes, month groups, sharing, and confirmed deletion. A same-day retake updates that day instead of adding extra streak credit.
- **A living lookback:** chronological playback, scrubbing, three speeds, optional dates, and on-device MP4 export through the native share sheet.
- **iCloud backups:** dated portrait-and-note snapshots, automatic and manual backup, upload status, and restore of missing days while preserving the journal already on the device.
- **A direct feedback channel:** send an idea or issue from settings, add an optional reply email, and choose whether to attach a previewable local diagnostic timeline. Failed sends preserve the open draft for retry.
- **Clear reporting choices:** Full, Limited, or Off in setup and settings. Full is the initial selection; Limited sends anonymous event totals. Photos, notes, and face measurements are excluded from reporting. Settings also clears local logs and resets the Full reporting identifier.
- **A companion website:** a responsive promotional page, support and privacy pages, plus an administrator dashboard for feedback and aggregate metrics, protected by Cloudflare Access.

Warm paper, sage, and terracotta follow system appearance. Capture has a quiet charcoal canvas; native controls, SF Symbols, typography, and restrained haptics keep the experience familiar.

## Build and run

Requires **iOS 18 or later**. Development uses **Xcode 26.6**, Swift 5 language mode, default MainActor isolation, and approachable concurrency.

1. Open `SelfieJourney.xcodeproj` and select the **SelfieJourney** scheme. The old `PicaDay.xcodeproj` and source-folder paths link to the renamed project and folders so existing Xcode shortcuts and saved editor tabs still resolve.
2. Choose an iPhone or iPad simulator and build. Complete onboarding or skip the reminder.
3. For a physical device, select your Apple Developer team in **Signing & Capabilities**. Keep the existing application identifier as explained below.
4. Camera access is requested when opening capture. A simulator without a front camera offers the native Photos picker instead.

The display name, project, and sources have changed to **Selfie Journey**. The bundle ID **`com.strikethrough.PicaDay`** is deliberately preserved so an update keeps the existing installation and local journal. The iCloud container is **`iCloud.com.strikethrough.PicaDay`**. Changing these identifiers creates a separate app/container and does not migrate existing data.

### iCloud signing setup

The repository includes the iCloud Documents capability and container entitlements. A local entitlement file alone cannot provision Apple's service:

1. In your Apple Developer account, register or select `iCloud.com.strikethrough.PicaDay` and associate it with the existing `com.strikethrough.PicaDay` App ID.
2. In Xcode **Signing & Capabilities → iCloud**, enable **iCloud Documents** and select that container. Ensure the configured team owns both identifiers and the signing profile includes them; regenerate the profile if necessary.
3. Run a signed build on a physical device signed in to an Apple Account with **iCloud Drive** enabled. Save a portrait, open **Your daily ritual**, and use **Back up now** and **Check iCloud status**.
4. Verify the uploaded snapshot can be discovered and restored on another signed installation using that account. An unsigned simulator build cannot establish this end-to-end result.

The journal remains local SwiftData (`cloudKitDatabase: .none`). iCloud Drive stores dated backup files; this is not live CloudKit synchronization. A prepared local backup is labeled **upload pending** until Apple's file metadata reports the manifest and all referenced photos uploaded. The app does not independently verify Apple's servers.

For a simulator build:

```sh
xcodebuild -project SelfieJourney.xcodeproj -scheme SelfieJourney \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/SelfieJourneyDerivedData \
  CODE_SIGNING_ALLOWED=NO LD=/usr/bin/clang LDPLUSPLUS=/usr/bin/clang++ build
```

To add an image to a booted simulator's photo library:

```sh
xcrun simctl addmedia booted /absolute/path/to/your-portrait.jpg
```

Imports belong to the day they are saved; EXIF dates do not backfill the journal. The decorative first-use portrait is an example and never becomes a journal entry or streak day.

## Tests and device checks

Run **Product → Test** in Xcode, or choose an installed simulator from `xcrun simctl list devices available`:

```sh
xcodebuild -project SelfieJourney.xcodeproj -scheme SelfieJourney \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /tmp/SelfieJourneyDerivedData \
  CODE_SIGNING_ALLOWED=NO LD=/usr/bin/clang LDPLUSPLUS=/usr/bin/clang++ test
```

Tests cover calendar streaks and milestones, reminder scheduling, onboarding preferences, portrait persistence, face-guidance geometry/policy, backup integrity and restore behavior, video export, and focused UI flows. Use the current Xcode test report for results; this document does not claim a fixed passing count.

The web project is in `web/`. Use `npm ci`, `npm run typecheck`, `npm test`, and `npm run build` there. See [operations and release notes](docs/OPERATIONS.md) for Cloudflare resources, deployment, API contracts, retention, and App Store privacy details.

Camera calibration across faces and devices, actual notification delivery, iCloud provisioning/upload/restore, system appearance, and sharing need physical-device QA. See [product and QA notes](docs/PRODUCT.md).

## Your photos

Portraits are normalized **1200 × 1600 JPEGs**. Films are **1080 × 1440, 30 fps H.264 MP4s**. Vision processes live frames on device without storing face templates or recognizing identity.

Automatic iCloud backups default on when iCloud Drive is available and can be disabled in settings. Versioned snapshots preserve capture dates, notes, pose choices, and immutable image revisions with SHA-256 checksums. Unchanged snapshots are reused. **Deleting a local portrait does not delete it from older backups.** Restore adds missing local-calendar days and keeps existing days; there is no automatic cross-device merge or backup-history deletion control.

Removing the app removes its local journal. A completed iCloud backup or independent shared copy is needed to recover that history. Uploads depend on the account, connection, and available iCloud storage.

More details: [product notes](docs/PRODUCT.md) and [operations](docs/OPERATIONS.md). Screenshots: [Today](docs/screenshots/today.png), [dark appearance](docs/screenshots/today-dark.png), [welcome](docs/screenshots/onboarding.png), [portrait frames](docs/screenshots/poses.png), and [reminder setup](docs/screenshots/reminder.png).
