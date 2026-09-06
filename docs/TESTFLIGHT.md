# Selfie Journey — TestFlight release

Updated September 6, 2026. The earlier **1.0 (1)** build was signed and uploaded at **12:04 America/Toronto** and is selected in App Store Connect. The replacement **1.0 (2)** removes all app data collection and has a successful signed archive with an empty collected-data manifest. Export/upload failed with `exportArchive Failed to Use Accounts` and missing Xcode credential keys while the Mac was locked; build 2 has **not** been uploaded or selected. Use build 2 with the new Data Not Collected privacy label. External beta review has not been submitted; there is no public invitation link.

## Current release status

| Item | Verified result |
| --- | --- |
| App Store Connect record | Selfie Journey, app ID `6809197003` |
| Bundle ID | `com.strikethrough.PicaDay` |
| Uploaded version/build | `1.0 (1)` |
| Signed build-2 archive | `/Users/oliver/dev/picaday/PicaDay/build/releases/SelfieJourney-1.0-2.xcarchive` — verified, retained locally, gitignored |
| Historical build-1 archive | `build/releases/SelfieJourney-1.0-1.xcarchive` — retained separately |
| Distribution method | `app-store-connect`, with `testFlightInternalTestingOnly: false` |
| Build-1 upload | `Upload succeeded` and `EXPORT SUCCEEDED`, September 6, 2026 at 12:04 America/Toronto |
| Build-2 upload | **Failed before upload:** `exportArchive Failed to Use Accounts`, missing Xcode credential keys |
| Selected build | **1.0 (1)** remains selected. Build 2 must upload and process before replacement |
| Native validation | Build 2: 49 unit, 6 iPhone UI, and 1 iPad UI tests passed; signed archive verified with empty collected-data manifest and no old API host |
| Test information | Replacement build-2 copy is below; saved TestFlight text must be reconciled before review submission |
| Review phone number | Awaiting the user's actual contact number |
| External review / public link | Not submitted / not created |
| Website | No-collection support/privacy update live at 18:33:58 UTC; deployment `8686d2acd95c4131b412ea3600c3a3aa`. Free/no-subscription copy preserved; former intake returns 410 and admin remains protected |
| Connect privacy and description | New description saved; Data Not Collected draft saved and previewed, **not published** |
| Screenshots | Earlier 3 iPhone + 1 iPad images remain in Connect; six verified build-2 replacements ready locally |
| Access interruption | Mac/Safari locked; unlock requested and still pending at last check |

To finish this release:

1. Unlock the Mac and retry export/upload of the existing signed build-2 archive. Restore Xcode's Apple account session if the missing-credential error persists. Verify Apple processing, then replace selected build 1 with build 2.
2. Upload all six replacement screenshots. Complete the actual review contact phone number, save the no-collection Test Information below, set Sign-in Required to No, and attach build 2 to the intended tester group. Publish the verified privacy details and submit for TestFlight review only after those requirements are met.
3. After approval, enable and verify the external group's public invitation link, then add that exact URL to the website. The free/no-subscription wording is already live; the website retains “Coming soon” until the beta is installable.

## Beta App Description

Selfie Journey is completely free, with no subscriptions or in-app purchases.

One portrait a day. A little ritual. A life in motion. Capture yourself with a calm, native iPhone and iPad app, then watch those everyday moments become a beautiful lookback film.

Choose your preferred framing, follow gentle on-device face and lighting guidance, and use your previous portrait as an alignment overlay. Set a daily reminder, keep your streak going, and add a few words to remember the day.

Your portraits and journal stay on your device, with optional backup to your private iCloud Drive. No separate Selfie Journey account is needed. The app collects no data: there are no analytics, tracking identifiers, or diagnostic uploads.

Have an idea or find a bug? Settings can open GitHub Issues in your browser. You choose what to post, and the app attaches no logs or personal data. Please leave private information out of public issues.

## What to Test

Selfie Journey is completely free. There are no subscriptions or in-app purchases.

Please try the daily portrait routine and tell us what feels great, confusing, or unreliable:

- Choose a pose and daily reminder time during setup. Check that each can be changed later in Settings.
- Take a portrait in different lighting conditions. Try the framing guidance, previous-portrait overlay, and three-second timer. You can also choose an image using Library in the camera screen.
- Save a portrait with an optional note, then retake it. There should be one portrait per day, with a same-day retake replacing that day's image.
- Return on another day to build your streak. Once you have portraits from at least two days, try Lookback playback, pace and date options, and exporting a film.
- Enable iCloud backup in Settings and check backup and restore using devices signed into the same Apple Account with iCloud Drive enabled.
- Check the No data collected explanation in Settings and the external GitHub links. Confirm the app does not attach logs, device information, or journal content. If upgrading from build 1, verify portraits, reminders, and backups are preserved.

For issues, include what you were doing and what you expected. Please avoid putting private information in your message. Thank you for helping make this daily ritual better.

## Beta App Review notes — build 2

Selfie Journey is a daily portrait journal for iPhone and iPad, supporting iOS/iPadOS 18 or later. It is completely free, with no subscriptions, in-app purchases, advertising, or paid feature gates. No separate account, demo credentials, or sign-in is required.

Complete onboarding by choosing a portrait frame and optional reminder time. From Today, grant camera permission to try live capture and framing guidance, or choose Library in the camera screen to import a user-selected photo through Apple's Photos picker. Save a portrait with an optional note. Saving another portrait on the same day replaces that day's image.

Face, position, distance, and lighting guidance runs on device. The app does not identify people. Portraits and notes are stored locally. Optional iCloud Drive backups require iCloud Drive and available storage on the user's Apple Account; capture and the journal work without iCloud. We cannot access the user's private backups.

Journal shows saved portraits. Lookback can preview the collection; movie export requires portraits from at least two different days. A new installation therefore starts with an empty or one-frame state.

Build 2 removes the earlier feedback, diagnostics, and analytics implementation. The app collects no data, has no reporting identifier, and sends no analytics or log uploads. Settings can open GitHub Issues in the system browser without attaching content, identifiers, or logs. The user independently chooses whether to post on that external service.

Network-backed journal storage uses Apple's iCloud facilities. CryptoKit SHA-256 checks backup file integrity; the app implements no custom encryption. The privacy policy is https://selfiejourney.com/privacy/.

## App Store Connect fields

| Field | Value |
| --- | --- |
| App name | Selfie Journey |
| App Store Connect app ID | `6809197003` |
| Bundle ID | `com.strikethrough.PicaDay` — preserve the existing identifier |
| Feedback email | `oliver@strikethrough.com` |
| Marketing URL | <https://selfiejourney.com/> |
| Privacy policy URL | <https://selfiejourney.com/privacy/> |
| Support URL | <https://selfiejourney.com/support/> |
| Sign-in required | No |
| Review contact | Use the verified account-holder contact details already in App Store Connect; supply the actual phone number if required. Do not invent one. |
| Public beta URL | Pending verification of an actual TestFlight public invitation link |

## Release audit and distribution

The local project uses automatic signing, team `8U8LFWAQP6`, and the existing iCloud Drive container `iCloud.com.strikethrough.PicaDay`. Camera and photo-library-add purpose strings are present. Photos import uses `PhotosPicker`. The app contains no third-party package dependencies or StoreKit purchasing code. Build 2's privacy manifest declares app-only UserDefaults access and no collected data types; pair its Data Not Collected response with the new binary and [the operations documentation](OPERATIONS.md). Build 1's archived manifest reflected the earlier feedback/reporting features.

`ITSAppUsesNonExemptEncryption` is set to Boolean `false` in `SelfieJourney/Info.plist`. The reviewed implementation only uses Apple's system networking/iCloud and CryptoKit hashing. This is the classification implied by Apple's guidance for encryption limited to the operating system; it does not mean that HTTPS connections are unencrypted. [Apple's export documentation table](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption) and [Info.plist guidance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations).

The source app icon is 1024×1024. Its redundant alpha channel was removed losslessly before the release archive: every original alpha value was 255, every RGB value and color metadata were preserved, and `sips` confirms `hasAlpha: no`. The original build-1 signed archive and App Store Connect export/upload subsequently succeeded. Build 2 also has a successful archive, but its export/upload remains blocked as recorded above. The archived app passes `codesign --verify --deep --strict`; its privacy manifest validates and its bundled `ITSAppUsesNonExemptEncryption` value is `false`.

Upload with the **App Store Connect** distribution method so the build remains eligible for external testing. Do not choose **TestFlight Internal Only** for the public beta. Create an internal testing group first, then an external group, attach the build, and provide the beta description, feedback email, review contact, review notes, and What to Test text. The first external build needs Apple's TestFlight review. [Apple's external tester workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers) and [test information requirements](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information).

After approval, enable a public link on the external group, verify its actual enrollment page, then add that exact URL to the website. If Apple is still reviewing the build, the website should accurately describe the pending beta rather than implying visitors can install it immediately. [Apple's TestFlight overview](https://developer.apple.com/testflight/).

## Repeating the archive and upload

Run from the repository root with the intended Apple Developer account signed into Xcode. For a later upload, first set a new build number and use a new archive path; build `1` has already been uploaded. Keep the existing bundle and iCloud identifiers.

The successful **historical build-1** archive command is reproduced below. For build 2, use a new `SelfieJourney-1.0-2.xcarchive` path and new log/export paths; do not overwrite the build-1 evidence:

```sh
xcodebuild \
  -project SelfieJourney.xcodeproj \
  -scheme SelfieJourney \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/selfiejourney-device-build \
  -archivePath build/releases/SelfieJourney-1.0-1.xcarchive \
  -allowProvisioningUpdates \
  LD=/usr/bin/clang LDPLUSPLUS=/usr/bin/clang++ \
  archive
```

The upload's export options are retained in `build/releases/ExportOptions.plist` with these settings:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>upload</string>
  <key>signingStyle</key><string>automatic</string>
  <key>teamID</key><string>8U8LFWAQP6</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
  <key>testFlightInternalTestingOnly</key><false/>
  <key>uploadSymbols</key><true/>
</dict>
</plist>
```

```sh
xcodebuild -exportArchive \
  -archivePath build/releases/SelfieJourney-1.0-1.xcarchive \
  -exportPath build/releases/export \
  -exportOptionsPlist build/releases/ExportOptions.plist \
  -allowProvisioningUpdates
```

Retained local evidence: `build/releases/archive-1.0-1.log` ends with `ARCHIVE SUCCEEDED`; `build/releases/upload-1.0-1.log` records the successful upload and package processing. The archive, export options, and logs are retained together under `/Users/oliver/dev/picaday/PicaDay/build/releases/`, which is gitignored. The original archive was created at `/tmp/selfiejourney-testflight/SelfieJourney-1.0-1.xcarchive` before being copied to this directory.
