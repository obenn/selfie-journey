# Selfie Journey — TestFlight release

Updated September 6, 2026. **Selfie Journey 1.0 (3) is uploaded, processed, and available to the internal group’s two existing testers.** Connect lists it as Ready to Submit. **Build 2 remains Waiting for Review externally**; Apple permits only one build of version 1.0 in beta review at a time, so build 3 has not been submitted externally. The existing public link still cannot accept testers until the group has an approved build. Build 1 is expired.

## Current release status

| Item | Verified result |
| --- | --- |
| App Store Connect record | Selfie Journey, app ID `6809197003` |
| Bundle ID | `com.strikethrough.PicaDay` |
| Latest uploaded version/build | **1.0 (3)**; upload and processing complete; status **Ready to Submit** |
| Latest signed archive | `build/releases/SelfieJourney-1.0-3.xcarchive` — signed successfully, retained locally, gitignored |
| Upload evidence | Xcode Organizer confirmed upload complete; Connect’s completed Build Uploads row lists **September 6, 8:14 PM America/Toronto** |
| Upload method | Existing signed archive opened in Xcode Organizer; **App Store Connect** distribution, eligible for external testing |
| Earlier upload failure | CLI retry still failed on stale account credential keys even after unlock; the valid active Xcode account and Organizer upload resolved delivery without rebuilding |
| Native validation | Build 3: 4 functional iPhone UI tests, 1 light iPhone capture test, and 1 iPad UI test passed. All six native screenshot assets refreshed. Build-2 baseline had 49 unit and 7 UI tests pass |
| Beta information | New 1,044-character beta description and build-3 What to Test (1,434 characters) saved. Contact complete privately; Sign-in Required = No. Build-3 review notes remain prepared, not saved; build-2 review notes retained |
| Build 3 distribution | Processed and automatically assigned internally. **Not submitted externally**: Connect blocks another build from version 1.0 until the current beta review is approved |
| External group | Existing group: **1 tester, 1 build**, build **1.0 (2)**, **Waiting for Review**, 90-day testing window |
| External notification | **Automatically notify testers** selected when submitting build 2 |
| Public invitation link | Existing link: https://testflight.apple.com/join/ucGAbHsd. Connect warns that testers **cannot join until the group has an approved build** |
| Internal group | **2 existing testers**, added manually by the user; build 3 assigned automatically and available for internal testing |
| Previous build | **1.0 (1) Expired** |
| Website | Clarity update live: deployment `a220c401-cf84-464e-ba93-170405040f3f`, Worker version `98be3939-40f6-4d3b-ac65-8adfc77891df`, September 7 at 00:12:34 UTC; free/no-subscription copy preserved |
| App Store-only work | Distribution now selects build 3, saved and verified; store privacy label remains a draft and review fields are incomplete. All six build-3 screenshots uploaded and verified: 3 iPhone 6.9-inch and 3 iPad 13-inch. These are separate from TestFlight |

## Remaining TestFlight actions

1. Internal testers can use build 3 now. No additional internal invitation is pending.
2. Await the current external review of build 2. Connect explicitly permits only one build of version 1.0 in beta review and says additional builds can be submitted once the submitted build is approved. Build 2’s review was preserved.
3. After that gate clears, save the prepared build-3 review notes and submit build 3 externally. Its What to Test is already saved.
4. Verify an approved build is installable through https://testflight.apple.com/join/ucGAbHsd before changing the website’s Coming soon wording to immediate beta availability.

App Store screenshots, App Store version build selection, and publication of the store privacy label are separate App Store release work. They are not prerequisites for adding a processed build to a TestFlight group or submitting its beta review. TestFlight uses its own beta description, What to Test, feedback email, and review contact details; invitation screenshots are optional. [Apple's TestFlight information workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/) and [build statuses](https://developer.apple.com/help/app-store-connect/reference/app-uploads/app-build-statuses/).

## Beta copy — clarity update for build 3

The **Beta App Description and build-3 What to Test are saved**. Build-3 review notes remain prepared, not saved. Build 3 is processed and assigned internally; build 2 remains Waiting for Review externally and blocks another version-1.0 beta submission.

## Beta App Description — saved (1,044 characters)

One selfie a day. Watch yourself change.

Selfie Journey helps you take a daily selfie with consistent face framing, then make a time-lapse video that shows how you change over months and years. The video uses the photos you actually take.

Completely free. No subscriptions or in-app purchases.

Choose a portrait distance and use face guides, lighting advice, and a previous-photo overlay to line up each day's selfie. Set a daily reminder, build your streak, and keep an optional note with each photo.

In Lookback, play your selfies in order, choose the pace, and create a time-lapse video once you have photos from at least two different days.

Your photos and notes stay on your device, with optional backups to your private iCloud Drive. The app collects no data and needs no separate account. Face guidance and video creation happen on device.

For suggestions or issues, Settings can open GitHub in your browser. You choose what to post; the app attaches no logs or personal data. Please leave private information out of public issues.

## What to Test — saved for build 3 (1,434 characters)

Selfie Journey is completely free. No subscriptions or in-app purchases.

This update makes the purpose clearer: take a selfie each day with similar face framing, then turn your real photos into a time-lapse of how you change over months and years.

- Go through setup, choose one of the four portrait distances, and set or skip a daily reminder. Tell us if the daily-selfie and time-lapse flow is clear.
- Tap Take today's selfie on Today. Try the face and eye-line guides, position and lighting advice, previous-photo overlay, and three-second timer. You can also import a photo using Library.
- Save a selfie with an optional note, then retake it. The new photo should replace today's earlier photo rather than add another day.
- Return on a different day. Check your streak and Journal, then open Lookback. With photos from at least two days, try the pace/date options and Create time-lapse video. Check that the exported video follows your actual photos in order.
- Check iCloud backup and missing-day restore on devices using the same Apple Account with iCloud Drive enabled.
- Check the No data collected message and optional GitHub links in Settings. The app should attach no photos, identifiers, or logs. Existing photos, reminders, and backups should remain after updating.

For an issue, describe what happened and what you expected. Please keep private photos, notes, and other personal information out of public feedback.

## Beta App Review notes — proposed for build 3

Selfie Journey is a daily selfie and time-lapse app for iPhone and iPad, supporting iOS/iPadOS 18 or later. Users take one selfie each day, use face guides to keep their framing similar, and turn the saved photos into a video showing changes over time. The video is made from actual user photos.

Build 3 clarifies this daily-selfie → consistent-framing → time-lapse flow in the interface. The app is completely free, with no subscriptions, in-app purchases, advertising, or paid feature gates. No separate account, demo credentials, or sign-in is required.

Complete onboarding by choosing a portrait distance and optional reminder time. On Today, tap Take today's selfie and grant camera permission to try live capture and framing advice. Library in the camera screen imports a user-selected photo through Apple's Photos picker. Save a selfie with an optional note. Another save on the same day replaces that day's photo.

Face, position, distance, and lighting guidance runs on device and helps the user frame the photo before capture. Journal shows the saved daily photos. Open Lookback, titled Your time-lapse, to preview them in date order. Create time-lapse video becomes available with photos from at least two different days, so a new installation initially shows an empty or one-frame state.

Photos and notes remain local. Optional iCloud Drive backups require an Apple Account with iCloud Drive and available storage; capture and the journal work without iCloud. We cannot access the user's private backups.

The app collects no data and sends no analytics, tracking identifiers, or diagnostic uploads. Settings can open GitHub Issues in the system browser without attaching app content or logs. The user decides whether to post on that separate service.

Network-backed journal storage uses Apple's iCloud facilities. CryptoKit SHA-256 checks backup file integrity; the app implements no custom encryption. Privacy policy: https://selfiejourney.com/privacy/.

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

Run from the repository root with the intended Apple Developer account signed into Xcode. For a later upload, first set a new build number and use a new archive path; builds `1`, `2`, and `3` have already been uploaded. Keep the existing bundle and iCloud identifiers.

The successful **historical build-1** archive command is reproduced below. Builds 2 and 3 already exist at their numbered archive paths; preserve them and use a new path/number for any later binary:

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
