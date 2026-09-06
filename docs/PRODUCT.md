# Selfie Journey: product and implementation

## A small ritual with a long horizon

One ordinary portrait each day makes the small changes visible over years. The daily action should take seconds; the reward is a growing record of a life. The tone is encouraging, with no score for appearance. A streak measures showing up, and the collection remains valuable when a streak ends.

Warm paper, sage, terracotta, restrained serif headlines, native SF Symbols, and subtle haptics frame the journal. The camera uses an uncluttered dark canvas. The rest of the app follows system appearance, with native light and dark color variants.

## Shipped experience

### First-open setup and framing

Setup introduces the journal and its no-data-collection design, asks for a portrait distance, and offers a daily reminder time. Notification permission is requested only after **Enable my daily reminder** is tapped. **Maybe later** preserves the chosen time with reminders off; denial provides a Settings route and a way to continue. Completion and pose choice persist across launches.

Four illustrated choices control the camera guide and live distance advice:

| Pose | Intent | Target face height within the 3:4 preview |
| --- | --- | ---: |
| Close-up | Every little detail | 62% |
| Classic, recommended default | Face and shoulders | 50% |
| Relaxed | A little breathing room | 39% |
| Wide | More of your world | 30% |

These are relative framing targets, not measured physical distances. Targets refer to Vision face bounds; the decorative oval includes forehead room. Settings offers the same choices. Each portrait records its pose, and the ghost overlay chooses the latest portrait with the current pose to avoid contradictory framing advice.

### Today and motivation

Today presents the current portrait, one capture/retake action, a prominent streak card, a seven-day completion strip, and progress toward the next milestone. Milestones are 3, 7, 14, 30, 100, and 365 days, then yearly increments. A restrained save celebration acknowledges a new day or milestone. Retakes have their own acknowledgement and do not add streak credit.

There is one portrait per current local calendar day. Retaking updates image, note, pose, and image revision while preserving the record's identity and original capture date. Imports belong to the day they are saved, regardless of EXIF date.

Streaks deduplicate local days and ignore future dates. A run ending yesterday stays active until today ends. A missed full day resets the current run while preserving the longest streak and collection. Calendar arithmetic handles daylight-saving changes; boundaries follow the device's current time zone, without a fixed home-zone setting.

### Camera and on-device guidance

AVFoundation provides mirrored front-camera preview and capture in a centered upright 3:4 crop. Its rotation coordinator pairs preview and capture orientation, including supported iPad layouts. Guides show the selected face oval, dotted eye line, center line, and shoulder marks. The same-pose ghost overlay has adjustable opacity and can be switched off.

Apple Vision landmarks and face observations drive one actionable hint at a time: bring a face into view, leave room for one person, move closer/farther, center left/right, raise/lower eye height, face forward, level the head, or adjust chin angle. Face, position, and light indicators complement the hint. Advice is stabilized across samples to reduce flicker.

Brightness sampling checks the visible scene and face region for low light or a bright background behind a dark face. These are image-exposure heuristics, not a light meter: automatic exposure, complexion, glasses, occlusion, and strong contrast can affect results. Framing and angle thresholds also need physical-device calibration across varied faces and camera orientations. Unavailable analysis falls back to the manual guide.

Analysis runs on device. Preview images, face templates, identity, and landmark history are not saved or uploaded. There is no beauty scoring, skin retouching, automatic capture, face recognition, or synthesized pose correction. The user can take the photo when ready even if a hint remains.

The optional timer counts down from three with haptics; tapping again cancels it. Review supports retake, a note, and save. Persistence failure retains the image for retry. The session stops when capture closes or the app becomes inactive. Permission denial, unavailable hardware, interruptions, and capture errors have recoverable states; PhotosPicker remains an alternative. The simulator never fabricates a shutter result.

### Journal and lookback

The Journal groups real portraits by month. A portrait opens its date, editable note, sharing, and confirmed deletion. Capture notes are limited to 280 characters; later editing preserves the entered note. Cancel leaves the stored record unchanged. Startup storage errors are shown explicitly instead of replacing the journal with an empty store.

Lookback orders portraits chronologically, provides play/pause and a scrubber, and optionally displays dates. One portrait can be previewed; export requires at least two.

| Pace | Seconds per portrait | Frames at 30 fps |
| --- | ---: | ---: |
| Slow | 0.8 | 24 |
| Balanced | 0.4 | 12 |
| Quick | 0.2 | 6 |

Export is a silent **1080 × 1440 H.264 MP4 at 30 fps**, rendered on device with direct cuts. Progress and cancellation are available. The exporter decodes one portrait at a time; image revisions invalidate older films after retakes. Errors and cancellation remove incomplete outputs. A completed film is temporary until saved through the share sheet and does not replace a journal backup.

### Daily reminders

Reminders are optional during setup or later in settings. The app prepares individual local notifications within a rolling **30-calendar-day horizon**, omitting completed days and times already passed. Activation, portrait changes, and settings updates renew the schedule and remove delivered app reminders. Today's nudge is removed after a portrait is saved.

If the app is not opened for more than 30 days, reminders stop until the next refresh. There is no server push or promised background execution. A daylight-saving skipped time moves to the next available time that day; a repeated time uses its first occurrence. Reopening after a time-zone change rebuilds the local schedule.

## iCloud Drive backup and restore

The active journal remains local SwiftData with `cloudKitDatabase: .none`. The app uses **iCloud Documents**, not live CloudKit database sync. The bundle ID remains `com.strikethrough.PicaDay` so existing installations keep their data after the Selfie Journey rename. The container remains `iCloud.com.strikethrough.PicaDay`.

Automatic backups default on and can be disabled in **Your daily ritual**. The app checks availability and backs up changes while running; settings offers **Back up now**, **Check iCloud status**, and dated restore history. Work while the app is closed is not guaranteed. UI testing does not contact the production iCloud container.

Backups use `Documents/Backups` inside the app's ubiquity container:

- `Photos/`: immutable JPEGs named with portrait UUID and image revision. Snapshots share unchanged images; retaking creates another revision.
- `Snapshots/`: versioned, dated JSON manifests containing portrait IDs, capture dates, notes, pose identifiers, image revisions, filenames, and SHA-256 checksums. A manifest is published after its referenced files exist locally. An unchanged collection reuses the previous snapshot.

Reads and writes use `NSFileCoordinator`; iCloud metadata queries discover snapshots from other installations. Restore requests downloads, validates manifest shape and filenames, verifies checksums, and checks image decoding. A malformed filename cannot navigate outside the backup photo directory.

**Backup prepared · iCloud upload pending** means files were written locally into the iCloud container. **Backed up to iCloud** appears only when Apple's ubiquitous-file metadata reports the manifest and every referenced photo uploaded. This is an operating-system status check, not independent server verification. Offline operation, insufficient iCloud storage, account changes, and pending downloads can require retry.

Restore is an explicit **missing-day merge**. It preserves the current journal, skips days and IDs already present, and inserts missing days with their notes and poses. Conflicts favor the current local portrait; an older image does not replace a newer local retake. Already restored entries remain if a later download fails, and the UI reports progress so retry is safe.

**Deleting a portrait locally does not erase earlier snapshots or image revisions.** Retained history enables recovery and consumes iCloud storage. There is no in-app history pruning or permanent backup-deletion control yet. Preferences such as reminder time are local settings rather than archive contents. There is no separate app-managed encryption layer or password-protected archive format.

### Required developer configuration

1. Use the configured Apple Developer team, or a team that owns the existing bundle ID and container. Register/select `iCloud.com.strikethrough.PicaDay` and associate it with the `com.strikethrough.PicaDay` App ID in the developer account.
2. In Xcode **Signing & Capabilities**, enable **iCloud Documents**, select the container, and ensure the signing profile includes iCloud. Refresh provisioning if needed. Repository entitlements alone cannot register the service.
3. Install a signed build on an iPhone/iPad with an Apple Account, iCloud Drive enabled, and available storage. Validate upload completion and discovery/restore on another installation using that account.

Unsigned simulator builds and local archive tests validate app behavior, not Apple's provisioning or remote durability. Changing the bundle ID or container requires a separate migration plan for existing users.

## Native architecture

| Area | Files in `SelfieJourney/` | Responsibility |
| --- | --- | --- |
| App and data | `SelfieJourneyApp.swift`, `ContentView.swift`, `Portrait.swift`, `PortraitStore.swift` | Local SwiftData, daily save, presentation, lifecycle refresh. |
| Setup | `OnboardingView.swift`, `JourneyPreferences.swift`, `PortraitPose.swift`, `RitualSettingsView.swift` | Persistent setup, native illustrations, frame and reminder settings. |
| Motivation | `TodayView.swift`, `StreakCalculator.swift`, `StreakProgress.swift`, `StreakCelebrationView.swift` | Calendar streaks, weekly progress, milestones, save acknowledgement. |
| Camera | `CaptureView.swift`, `CameraService.swift`, `FaceGuidance.swift` | AVFoundation, Vision sampling, hint policy, timer, ghost overlay, PhotosPicker. |
| Journal | `PortraitImageProcessor.swift`, `LibraryView.swift` | Normalized 1200 × 1600 JPEGs, ImageIO thumbnails, notes, sharing, deletion. |
| Backup | `CloudBackupManager.swift`, `BackupArchive.swift`, `CloudBackupSection.swift` | iCloud snapshots, integrity, upload state, merge restore. |
| Film | `LookbackView.swift`, `VideoExporter.swift` | Playback, AVAssetWriter export, native sharing. |
| Reminders | `ReminderManager.swift` | Authorization and serialized UserNotifications scheduling. |
| Privacy and external support | `CommunitySettingsSection.swift`, `PrivacyMigration.swift` | No-collection explanation, browser links to GitHub, removal of obsolete reporting defaults on upgrade. |
| Appearance | `JourneyTheme.swift`, `Assets.xcassets` | Adaptive colors, common controls, type, icon, inspiration image. |

`Portrait` stores UUID, capture date, image bytes, image revision, note, and pose. SwiftData manages external image storage when appropriate. Preferences use UserDefaults. The app targets iOS 18 for iPhone/iPad, using Xcode 26.6, Swift 5 language mode, default MainActor isolation, and approachable concurrency. There are no third-party packages.

## Privacy and assets

Camera permission is requested when opening capture. PhotosPicker grants access only to the selected image, without unrestricted library reading. Notifications are local and require an Enable action. Sharing uses the system share sheet. Enabled backups copy the journal to the user's iCloud Drive with the status and retention behavior described above.

There is no separate app account, analytics SDK, microphone capture, location request, identity recognition, or cloud image processing. The operating system manages normal app-sandbox and iCloud protections. Deleting the app removes the local journal; recovery requires an available completed backup or independent exported copy.

### Privacy and external support

Starting with 1.0 build 2, the app collects no data. The native analytics service, reporting choices, persistent installation identifier, local diagnostic ring, and feedback transport have been removed. `PrivacyMigration` deletes only the four obsolete telemetry/log defaults on upgrade; portraits, notes, reminder choices, and backups are preserved.

Settings shows **No data collected** and links to the privacy policy. **Suggest a change or report a bug** opens the project's GitHub Issues page in the system browser. **Selfie Journey on GitHub** opens the repository. Neither URL contains user/device identifiers, app content, or logs. GitHub is a separate service; the user decides whether and what to post. Public issues should not contain private portraits or notes.

### Website and historical administrator tools

The public site presents the daily portrait ritual, real interface examples, external GitHub support, and the current privacy policy. It says **Coming soon** until a verified installable App Store or TestFlight URL exists. The site has no product analytics scripts or feedback submission form.

The previous feedback/telemetry intake is retired. The admin site remains protected by Cloudflare Access and independent Worker JWT verification to manage historical records only. Original retention cleanup continues; upgrading the app does not erase previously received service data. Ordinary Cloudflare website delivery and external GitHub activity are separate from the native app's data practices.

See [operations](OPERATIONS.md) for exact data boundaries, retention, deployment, and release privacy checks.

The framing example at `SelfieJourney/Assets.xcassets/PortraitInspiration.imageset/portrait.png` was generated with ImageGen: a natural vertical 3:4 adult portrait, neutral expression, centered face, eye-level lens, plain warm background, and soft frontal daylight. It is decorative, never inserted as user data, counted toward a streak, or included in a film. Setup pose previews are native abstract illustrations.

## Validation and device QA

Automated sources are in `SelfieJourneyTests` and `SelfieJourneyUITests`. They cover calendar streaks/milestones, reminders, preferences, portrait storage, Vision geometry/guidance, archive integrity/reuse/restore, and encoded video output. UI tests exercise setup, pose selection, reminder skip, settings changes, relaunch persistence, and journal/camera flows. Current results belong in the Xcode test report rather than a permanent count here.

`--uitesting` uses an in-memory journal and isolated preferences. Add `--onboarding` to exercise setup; add `--reset-onboarding` for a fresh setup state. Reset is DEBUG-only, touches only the test suite, and runs once per process. These flags do not manufacture camera hardware or iCloud upload results.

- [ ] Clean-install setup: all four frames, chosen time, Enable, denial, Settings recovery, and skip. Relaunch and change frame/time in settings.
- [ ] Signed iCloud setup: unavailable account/Drive, automatic/manual backups, pending vs uploaded, poor network, storage-full, account changes, cancellation, and second-device discovery.
- [ ] Restore: empty journal, missing days, preservation of newer local retakes, recovery of a deleted day from older history, partial-download retry, and restored notes/poses.
- [ ] Camera: preview/review/save/ghost/export mirroring and orientation on iPhone/iPad, supported rotations, landscape capture, and multitasking.
- [ ] Guidance: every distance, left/right and eye-height correction, yaw/roll/pitch, multiple/no faces, glasses, occlusion, varied complexions, and frontal/low/backlit conditions. Calibrate without restricting manual capture.
- [ ] Lifecycle: timer cancel, rapid taps, leaving capture, backgrounding, interruptions, denied permission/recovery, unavailable-camera retry, and rotated imports.
- [ ] Journal: one record per day, retakes, relaunch persistence, note cancel/save, deletion, and streak changes. Check midnight/time-zone/DST behavior.
- [ ] Notifications: actual delivery, cancellation after saving, changed times, disabled reminders, permission changes, and time-zone refresh.
- [ ] Film: every pace, chronology, captions, crop, resolution, duration, cancellation, low-storage errors, and native sharing destinations.
- [ ] Accessibility: VoiceOver, large Dynamic Type, Reduce Motion, light/dark switching, small screens, and iPad. Verify controls remain reachable.
- [ ] Privacy upgrade: confirm obsolete telemetry identifiers/log defaults are removed while portraits, reminders, and backups remain. Confirm no analytics or feedback requests occur during normal use.
- [ ] External support: verify GitHub links open in the browser with no appended identifiers, logs, or user content; privacy messaging matches the empty collected-data manifest.
- [ ] Web: small-screen layout, keyboard navigation, GitHub support links, absence of the old feedback form, retired intake rejection, admin sign-in/out, historical record controls, and retention cleanup.
- [ ] Scale: multi-year fixtures for scrolling, backup size, export memory, duration, and thermals before making long-term performance claims.

## Next refinements

Widgets and App Intents could place capture beside an existing morning routine. Film date ranges, first/last comparisons, localization, and explicit backup retention/deletion controls would extend the experience. Cross-device live sync and a password-protected portable archive remain separate future projects with their own conflict and recovery designs.

Each addition should preserve the central action: open, frame, keep today's moment, and get on with the day.
