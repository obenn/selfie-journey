# Selfie Journey — TestFlight release

Updated September 6, 2026. Version **1.0 (1)** was archived, signed, and successfully uploaded to App Store Connect at **12:04 America/Toronto**. Apple's upload response reported that the package was processing. External beta review has not yet been submitted, and there is no public invitation link.

## Current release status

| Item | Verified result |
| --- | --- |
| App Store Connect record | Selfie Journey, app ID `6809197003` |
| Bundle ID | `com.strikethrough.PicaDay` |
| Uploaded version/build | `1.0 (1)` |
| Signed archive | `/Users/oliver/dev/picaday/PicaDay/build/releases/SelfieJourney-1.0-1.xcarchive` (retained locally; gitignored) |
| Distribution method | `app-store-connect`, with `testFlightInternalTestingOnly: false` |
| Upload | `Upload succeeded` and `EXPORT SUCCEEDED`, September 6, 2026 at 12:04 America/Toronto |
| Apple processing | Processing reported by the completed upload; final processing result awaits verification |
| Test information | Beta description, feedback email, marketing/privacy URLs, review name/email, and review notes entered; Save clicked. Persistence awaits verification because the Mac locked during the browser session. |
| Review phone number | Awaiting the user's actual contact number |
| External review / public link | Not submitted / not created |
| Website pricing copy | Live: “Completely free. No subscriptions.” Deployment `b23739a1-2573-4928-9386-c0e9704ad51f`; public pages, API health, and admin protection verified. |

To finish this release:

1. Verify the processed build and saved Test Information in App Store Connect, then complete the review contact phone number.
2. Create the internal and external tester groups, attach build 1, enter What to Test, and submit for TestFlight review.
3. After approval, enable and verify the external group's public invitation link, then add that exact URL to the website. The free/no-subscription wording is already live; the website retains “Coming soon” until the beta is installable.

## Beta App Description

Selfie Journey is completely free, with no subscriptions or in-app purchases.

One portrait a day. A little ritual. A life in motion. Capture yourself with a calm, native iPhone and iPad app, then watch those everyday moments become a beautiful lookback film.

Choose your preferred framing, follow gentle on-device face and lighting guidance, and use your previous portrait as an alignment overlay. Set a daily reminder, keep your streak going, and add a few words to remember the day.

Your portraits and journal stay on your device, with optional backup to your private iCloud Drive. No separate Selfie Journey account is needed. You control usage and reliability reporting with Full, Limited, and Off options; photos, journal content, and face tracking data are never included in that reporting.

Help shape the app by sending feedback from Settings. For technical issues, you can preview and choose to attach a short diagnostic history.

## What to Test

Selfie Journey is completely free. There are no subscriptions or in-app purchases.

Please try the daily portrait routine and tell us what feels great, confusing, or unreliable:

- Choose a pose, daily reminder time, and reporting preference during setup. Check that each can be changed later in Settings.
- Take a portrait in different lighting conditions. Try the framing guidance, previous-portrait overlay, and three-second timer. You can also choose an image using Library in the camera screen.
- Save a portrait with an optional note, then retake it. There should be one portrait per day, with a same-day retake replacing that day's image.
- Return on another day to build your streak. Once you have portraits from at least two days, try Lookback playback, pace and date options, and exporting a film.
- Enable iCloud backup in Settings and check backup and restore using devices signed into the same Apple Account with iCloud Drive enabled.
- Try Full, Limited, and Off reporting. Send feedback from Settings, both with and without the optional previewable diagnostic history.

For issues, include what you were doing and what you expected. Please avoid putting private information in your message. Thank you for helping make this daily ritual better.

## Beta App Review notes

Selfie Journey is a daily portrait journal for iPhone and iPad, supporting iOS/iPadOS 18 or later. The app is completely free with no subscriptions, in-app purchases, advertising, or paid feature gates. No separate app account, demo credentials, or sign-in is required.

To review: complete onboarding by choosing a portrait pose, a reminder preference, and a usage/reliability reporting level. Notifications are optional. From Today, open the camera and grant camera permission to test live capture. The Library button on the camera screen imports a user-selected photo through Apple's Photos picker, including when camera access is unavailable. Save the photo and optionally add a note. Saving another portrait on the same day replaces that day's portrait rather than creating a duplicate.

Live face, position, distance, and lighting guidance runs on the device using Apple frameworks. The app does not identify people. Portraits and journal notes are stored locally. Optional iCloud Drive backup is available in Settings and requires the device's Apple Account to have iCloud Drive enabled and available storage; core capture and journal features work without iCloud.

The Journal shows saved portraits. Lookback previews the collection; playback and movie export become available with portraits from at least two different days. A new installation therefore initially shows the one-frame/empty state until a second day's portrait is saved.

Settings also provides app feedback with an optional contact email and optional diagnostic history that can be previewed before sending. Usage/reliability reporting has Full, Limited, and Off choices. Users can select Off before any reporting begins, and the choice does not restrict app features. Reporting never includes photos, journal content, or face tracking data. The privacy policy explains the data types and retention periods.

Network services are limited to the app's feedback/reporting API over system HTTPS and Apple's iCloud facilities. CryptoKit SHA-256 is used to check backup file integrity; the app does not implement its own encryption algorithms.

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

The local project uses automatic signing, team `8U8LFWAQP6`, and the existing iCloud Drive container `iCloud.com.strikethrough.PicaDay`. Camera and photo-library-add purpose strings are present. Photos import uses `PhotosPicker`. The app contains no third-party package dependencies or StoreKit purchasing code. The privacy manifest declares app-only UserDefaults access and the maximum feedback/reporting data collected; App Store Connect privacy responses must remain consistent with it and [the operations documentation](OPERATIONS.md).

`ITSAppUsesNonExemptEncryption` is set to Boolean `false` in `SelfieJourney/Info.plist`. The reviewed implementation only uses Apple's system networking/iCloud and CryptoKit hashing. This is the classification implied by Apple's guidance for encryption limited to the operating system; it does not mean that HTTPS connections are unencrypted. [Apple's export documentation table](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption) and [Info.plist guidance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations).

The source app icon is 1024×1024. Its redundant alpha channel was removed losslessly before the release archive: every original alpha value was 255, every RGB value and color metadata were preserved, and `sips` confirms `hasAlpha: no`. The signed archive and App Store Connect export/upload subsequently succeeded. The archived app passes `codesign --verify --deep --strict`; its privacy manifest validates and its bundled `ITSAppUsesNonExemptEncryption` value is `false`.

Upload with the **App Store Connect** distribution method so the build remains eligible for external testing. Do not choose **TestFlight Internal Only** for the public beta. Create an internal testing group first, then an external group, attach the build, and provide the beta description, feedback email, review contact, review notes, and What to Test text. The first external build needs Apple's TestFlight review. [Apple's external tester workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers) and [test information requirements](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information).

After approval, enable a public link on the external group, verify its actual enrollment page, then add that exact URL to the website. If Apple is still reviewing the build, the website should accurately describe the pending beta rather than implying visitors can install it immediately. [Apple's TestFlight overview](https://developer.apple.com/testflight/).

## Repeating the archive and upload

Run from the repository root with the intended Apple Developer account signed into Xcode. For a later upload, first set a new build number and use a new archive path; build `1` has already been uploaded. Keep the existing bundle and iCloud identifiers.

The successful archive command is reproduced below using the retained release directory in place of the original temporary archive path:

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
