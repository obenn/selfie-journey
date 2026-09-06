# Selfie Journey — TestFlight release

Updated September 6, 2026. **Selfie Journey 1.0 (2) uploaded successfully and is Waiting for Review for external TestFlight testing.** The existing external group contains one tester and build 2, with automatic notification enabled. Build 1 is expired. The internal group also has build 2 through automatic distribution, but has no testers yet.

## Current release status

| Item | Verified result |
| --- | --- |
| App Store Connect record | Selfie Journey, app ID `6809197003` |
| Bundle ID | `com.strikethrough.PicaDay` |
| Uploaded version/build | **1.0 (2)**; processed successfully |
| Signed archive | `build/releases/SelfieJourney-1.0-2.xcarchive` — verified, retained locally, gitignored |
| Upload evidence | Xcode Organizer explicitly reported upload complete. Connect lists September 6 at approximately **3:21–3:22 PM America/Toronto** |
| Upload method | Existing signed archive opened in Xcode Organizer; **App Store Connect** distribution, eligible for external testing |
| Earlier upload failure | CLI retry still failed on stale account credential keys even after unlock; the valid active Xcode account and Organizer upload resolved delivery without rebuilding |
| Native validation | 49 unit, 6 iPhone UI, and 1 iPad UI tests passed; archived manifest has no collected data and tracking off; old API host and collection code absent |
| Beta information | No-collection beta description and build-2 review notes saved; complete review contact provided and saved privately; Sign-in Required = No |
| External group | Existing group: **1 tester, 1 build**, build **1.0 (2)**, **Waiting for Review**, 90-day testing window |
| External notification | **Automatically notify testers** selected when submitting build 2 |
| Public invitation link | Existing link: https://testflight.apple.com/join/ucGAbHsd. Connect warns that testers **cannot join until the group has an approved build** |
| Internal group | Automatic distribution added build 2; **0 testers**. Account-owner invitation was not sent; specific recipient authorization is pending |
| Previous build | **1.0 (1) Expired** |
| Website | No-collection website is live, deployment `8686d2acd95c4131b412ea3600c3a3aa`; free/no-subscription copy preserved |
| App Store-only work | Store privacy label remains a saved draft; replacement store screenshots are local and not yet uploaded. These do not block this submitted TestFlight beta |

## Remaining TestFlight actions

1. Await Apple's external beta review. Automatic notification is enabled, so existing external testers can receive the approved build without another manual distribution step. Verify the group's status changes to Testing/Ready to Test and the public link offers the build before advertising immediate installation.
2. If the owner authorizes the pending internal invitation, add that eligible Connect account to the internal group and verify the invitation. No invitation has been sent yet. Internal testing does not require external beta review.
3. Once the external build is available, verify the existing public invitation link and add that exact link to the website with accurate availability wording.

App Store screenshots, App Store version build selection, and publication of the store privacy label are separate App Store release work. They are not prerequisites for adding a processed build to a TestFlight group or submitting its beta review. TestFlight uses its own beta description, What to Test, feedback email, and review contact details; invitation screenshots are optional. [Apple's TestFlight information workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/) and [build statuses](https://developer.apple.com/help/app-store-connect/reference/app-uploads/app-build-statuses/).

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
| Review contact | Complete and saved in TestFlight; the actual phone number is intentionally not stored in this repository |
| Public beta URL | https://testflight.apple.com/join/ucGAbHsd — existing link; build 2 is Waiting for Review |

## Release audit and distribution

The local project uses automatic signing, team `8U8LFWAQP6`, and the existing iCloud Drive container `iCloud.com.strikethrough.PicaDay`. Camera and photo-library-add purpose strings are present. Photos import uses `PhotosPicker`. The app contains no third-party package dependencies or StoreKit purchasing code. Build 2's privacy manifest declares app-only UserDefaults access and no collected data types; pair its Data Not Collected response with the new binary and [the operations documentation](OPERATIONS.md). Build 1's archived manifest reflected the earlier feedback/reporting features.

`ITSAppUsesNonExemptEncryption` is set to Boolean `false` in `SelfieJourney/Info.plist`. The reviewed implementation only uses Apple's system networking/iCloud and CryptoKit hashing. This is the classification implied by Apple's guidance for encryption limited to the operating system; it does not mean that HTTPS connections are unencrypted. [Apple's export documentation table](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption) and [Info.plist guidance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations).

The source app icon is 1024×1024. Its redundant alpha channel was removed losslessly before the release archive: every original alpha value was 255, every RGB value and color metadata were preserved, and `sips` confirms `hasAlpha: no`. The original build-1 signed archive and App Store Connect export/upload subsequently succeeded. Build 2 also has a successful archive and was uploaded successfully through Xcode Organizer after CLI account lookup failed. The archived app passes `codesign --verify --deep --strict`; its privacy manifest validates and its bundled `ITSAppUsesNonExemptEncryption` value is `false`.

Upload with the **App Store Connect** distribution method so the build remains eligible for external testing. Do not choose **TestFlight Internal Only** for the public beta. Create an internal testing group first, then an external group, attach the build, and provide the beta description, feedback email, review contact, review notes, and What to Test text. The first external build needs Apple's TestFlight review. [Apple's external tester workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers) and [test information requirements](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information).

The external group already has a public link. After approval, verify its enrollment page offers the latest build, then add that exact URL to the website. If Apple is still reviewing the build, the website should accurately describe the pending beta rather than implying visitors can install it immediately. [Apple's TestFlight overview](https://developer.apple.com/testflight/).

## Repeating the archive and upload

Run from the repository root with the intended Apple Developer account signed into Xcode. For a later upload, first set a new build number and use a new archive path; builds `1` and `2` have already been uploaded. Keep the existing bundle and iCloud identifiers.

The successful **historical build-1** archive command is reproduced below. Build 2 already exists at `SelfieJourney-1.0-2.xcarchive`; keep both archives and use a new path/number for any later binary:

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


## Build-2 upload recovery

`build/releases/upload-1.0-2.log` records the earlier failed CLI attempt, not the later successful GUI delivery. Do not infer the current upload status from that log alone. With the valid account active in Xcode, the existing archive was opened through File → Open, selected in Organizer, and distributed through App Store Connect. Organizer showed upload complete; Connect then processed build 2 and accepted its external beta-review submission.
