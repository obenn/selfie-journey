# Selfie Journey — TestFlight release

Updated September 16, 2026. **The user chose build 3 for the initial App Store submission and build 4 for later.** Connect shows build 3 as Ready to Submit with Internal distribution, and build 2 as Testing externally after beta approval. App Store submission is still in progress and has not been completed; see [App Store status](APP_STORE.md).

Build 4 is absent from Connect and remains a verified local signed archive. Its generic framing guide and optional background removal are not part of the selected App Store build. The earlier build-4 upload attempt failed on Xcode account authentication. No new upload, tester invitation, or external promotion is scheduled.

## Current release status

| Item | Result; September 16 audit unless a historical date is specified |
| --- | --- |
| App Store Connect record | Selfie Journey, app ID `6809197003` |
| Bundle ID | `com.strikethrough.PicaDay` |
| Later build | **1.0 (4)** — local only and absent from Connect. Signed archive complete; earlier CLI upload failed before delivery with **Failed to Use Accounts**. User chose to keep this build for later |
| Build-4 signed archive | `build/releases/SelfieJourney-1.0-4.xcarchive` — archive succeeded, bundled version/build confirmed as **1.0 (4)**, code signature valid |
| Build-4 unit tests | **61 Swift Testing tests in 9 suites passed** in `/tmp/selfiejourney-build4-iphone-final.xcresult` |
| Build-4 Vision checks | Simulator smoke XCTest **skipped** because its model is unavailable. The same production renderer passed an actual-Vision macOS fixture check in **3.76 seconds**; `/tmp/selfiejourney-background-smoke/portrait-neutral.png` passed visual inspection. This is one macOS fixture, not physical-iPhone or broad-quality verification |
| Build-4 UI checks | **All 7 iPhone UI cases passed across the initial run and targeted retry**, including new export invalidation. Six passed initially; the baseline photo-import dismissal test passed after correcting its hittability wait in `/tmp/selfiejourney-build4-iphone-import-retry.xcresult`. Video-background options and all four pose cards passed visual inspection. Both relevant iPad cases passed: onboarding/pose persistence and video export/invalidation. The latter passed after adapting its selector to native floating tabs and restarting a stalled test session; app code was unchanged. iPad pose and video-option screenshots also passed visual inspection |
| Last verified uploaded version/build | **1.0 (3)**; upload and processing complete; status **Ready to Submit**, reconfirmed September 16 |
| Previous signed archive | `build/releases/SelfieJourney-1.0-3.xcarchive` — retained locally, gitignored |
| Upload evidence | Xcode Organizer confirmed upload complete; Connect’s completed Build Uploads row lists **September 6, 8:14 PM America/Toronto** |
| Upload method | Existing signed archive opened in Xcode Organizer; **App Store Connect** distribution, eligible for external testing |
| Earlier upload failure | CLI retry still failed on stale account credential keys even after unlock; the valid active Xcode account and Organizer upload resolved delivery without rebuilding |
| Native validation | Build 3: 4 functional iPhone UI tests, 1 light iPhone capture test, and 1 iPad UI test passed. All six native screenshot assets refreshed. Build-2 baseline had 49 unit and 7 UI tests pass |
| Beta information | New 1,044-character beta description and build-3 What to Test (1,434 characters) saved. Contact complete privately; Sign-in Required = No. Build-3 review notes remain prepared, not saved; build-2 review notes retained |
| Build 3 distribution | **Ready to Submit**, assigned to Internal; selected for the separate App Store submission. No external promotion performed during this audit |
| External build, September 16 | **1.0 (2) Testing**; beta review has been approved. No external group changes performed |
| External notification | **Automatically notify testers** selected when submitting build 2 |
| Public invitation link | Existing link: https://testflight.apple.com/join/ucGAbHsd. Build 2 is now Testing; public enrollment itself was not rechecked during this audit |
| Internal group | **2 existing testers**, added manually by the user; build 3 assigned automatically and available for internal testing |
| Previous build | **1.0 (1) Expired** |
| Public website and metadata | Remain on build-3 copy. No website deployment during this audit. Support/privacy pages and the newly public GitHub repository/Issues all returned HTTP 200 on September 16 |
| App Store-only work, September 16 | User chose build 3; Distribution selects it and reconfirms 3 iPhone screenshots using the 6.9-inch set. The 3 iPad 13-inch screenshots were last verified September 6 and need a fresh check. Separate review contact/notes are blank and Sign-in Required is Yes; privacy publication and free pricing/availability still require checks. App Store review has not been submitted |

## Later build-4 TestFlight plan

Deferred by the user on September 16 while build 3 is submitted to the App Store. These are later steps, not actions requested during the current submission.

1. When the user resumes build 4, recover its upload through a valid Xcode account in Organizer. Local validation is complete: the signed build-4 archive is ready, 61 unit tests, 7 iPhone UI cases, and 2 iPad UI cases passed across their runs/retries, and one actual-Vision macOS fixture passed. Varied-portrait and physical-device quality checks remain part of internal testing.
2. Upload through **App Store Connect** with `testFlightInternalTestingOnly=false`. After processing, verify that the existing Internal group received build 4 through automatic distribution, save the build-4 What to Test below, and confirm that its two existing testers can install it. No new tester invitation is needed.
3. Stop at internal testing. Preserve the existing External group and its approved build 2. Wait for the user to choose whether this same build should go external.
4. On that later request, recheck Apple's current review state, add the same build to the existing External group, and submit Beta App Review if required. Apple allows only one build per version in review at once. Choose whether approved-build notifications should be automatic or sent manually at that time.
5. Only after promotion and a verified installable public beta should public release copy, screenshots, or website availability be updated. The existing public link is https://testflight.apple.com/join/ucGAbHsd.

App Store screenshots, App Store version build selection, and publication of the store privacy label are separate App Store release work. They are not prerequisites for adding a processed build to a TestFlight group or submitting its beta review. TestFlight uses its own beta description, What to Test, feedback email, and review contact details; invitation screenshots are optional. [Apple's TestFlight information workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/) and [build statuses](https://developer.apple.com/help/app-store-connect/reference/app-uploads/app-build-statuses/).

## What to Test — draft for build 4 (1,721 characters)

Prepared for internal testers; not yet saved in App Store Connect. Copy only the text between this introduction and the next heading.

Selfie Journey is completely free. No subscriptions or in-app purchases.

This internal build adds a simpler framing guide and optional background removal for your time-lapse video. Your original photos stay unchanged, and all image processing happens on your device.

- Try all four portrait distances in setup, Settings, and the camera. Each uses open corner brackets and a dotted eye line. Check that the guide is easy to follow without asking you to match a particular face shape. Try position and lighting advice, the previous-photo overlay, and the timer. Guides should not appear in saved selfies.
- In Lookback, use photos from at least two different days. Create a video with Remove background off first, then turn it on and create another. The still-photo preview shows originals; removal is applied when the video is created.
- Play the finished video before sharing. With removal on, each photo should have the same soft neutral backdrop. Check hair, glasses, ears, shoulders, varied lighting, and busy backgrounds. Fine edges can vary. Tell us about noticeable cutouts or flicker.
- Change the pace, dates, or background option and recreate the video. Preview and sharing should use the new result, in date order. Check that the Journal and iCloud backups still contain the original photos.
- Cancel an export and try again. If removal cannot finish or cannot find a person, it should stop with a clear message and offer Use original backgrounds; it should not quietly mix treated and untreated photos.

Please report what happened and what you expected through the optional GitHub link in Settings. Keep private photos, notes, and personal information out of public issues. The app attaches no data or logs.

## Build-4 implementation and validation boundary

The fixed guide uses the same open-bracket and dotted-eye-line design for all four poses, scaled to each framing target; it contains no face or body silhouette. Background removal defaults off. When enabled, Apple's Vision person segmentation runs at accurate quality separately for every photo, and Core Image composites the export copy over `#EEECE4`. Original photos, notes, and backups are preserved. The finished MP4 has a native AVKit preview before sharing. A missing person or failed removal aborts the export and offers an explicit original-background retry.

The build-4 run has passed 61 Swift Testing tests in 9 suites. The simulator's real-Vision smoke XCTest was skipped because its model is unavailable. Separately, the same production renderer passed an actual-Vision macOS check on one portrait fixture in 3.76 seconds, and the resulting PNG passed visual inspection. This demonstrates that fixture on macOS; it does not establish physical-iPhone quality or results across varied portraits. All 7 iPhone UI cases passed across the initial run and the targeted import-test retry, including the new export-invalidation case. Video-background controls and all four pose cards passed visual inspection. The iPad onboarding/pose-persistence and video-export/invalidation cases also passed. The video test was updated for native floating tabs, then passed after restarting a stalled simulator session. Results are in `/tmp/selfiejourney-build4-ipad.xcresult` (onboarding) and `/tmp/selfiejourney-build4-ipad-video-clean.xcresult` (video); both screens passed visual inspection. The signed archive is verified; the earlier CLI upload attempt failed before delivery on account authentication. On September 16, Connect still had no build 4 and the user deferred it until later. Real ML quality across varied faces, hair, clothing, lighting, and physical devices still needs internal testing. Follow the [product QA checklist](PRODUCT.md#validation-and-device-qa) before considering external promotion.

## Historical beta copy — clarity update for build 3

On September 6, the **Beta App Description and build-3 What to Test were saved**. Build-3 review notes remained prepared, not saved. Build 3 was processed and assigned internally; build 2 was Waiting for Review externally and blocked another version-1.0 beta submission. Keep this saved public beta description while testing build 4 internally; use the separate build-4 What to Test above for that build.

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
| Public beta URL | https://testflight.apple.com/join/ucGAbHsd — existing link; build 2 was Waiting for Review at the September 6 check |

## Release audit and distribution

The local project uses automatic signing, team `8U8LFWAQP6`, and the existing iCloud Drive container `iCloud.com.strikethrough.PicaDay`. Camera and photo-library-add purpose strings are present. Photos import uses `PhotosPicker`. The app contains no third-party package dependencies or StoreKit purchasing code. Build 2's privacy manifest declares app-only UserDefaults access and no collected data types; pair its Data Not Collected response with the new binary and [the operations documentation](OPERATIONS.md). Build 1's archived manifest reflected the earlier feedback/reporting features.

`ITSAppUsesNonExemptEncryption` is set to Boolean `false` in `SelfieJourney/Info.plist`. The reviewed implementation only uses Apple's system networking/iCloud and CryptoKit hashing. This is the classification implied by Apple's guidance for encryption limited to the operating system; it does not mean that HTTPS connections are unencrypted. [Apple's export documentation table](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption) and [Info.plist guidance](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations).

The source app icon is 1024×1024. Its redundant alpha channel was removed losslessly before the release archive: every original alpha value was 255, every RGB value and color metadata were preserved, and `sips` confirms `hasAlpha: no`. The original build-1 signed archive and App Store Connect export/upload subsequently succeeded. Build 2 also has a successful archive and was uploaded successfully through Xcode Organizer after CLI account lookup failed. The archived app passes `codesign --verify --deep --strict`; its privacy manifest validates and its bundled `ITSAppUsesNonExemptEncryption` value is `false`.

Upload with the **App Store Connect** distribution method even when the initial audience is internal. **TestFlight Internal Only** makes that upload ineligible for external distribution later. The normal upload remains eligible for both; group assignment controls who receives it. The existing Internal group's automatic distribution can add new Xcode uploads without adding them to External. [Apple's internal tester workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-internal-testers/).

Promotion is a separate, manual action after the user chooses it: TestFlight → External Testing → existing group → Add Builds → select the already uploaded build → supply What to Test/review information → Submit Review or Start Testing as offered. Preserve any existing review until its status is known. Automatic notification on an external build does not automatically add future uploads to that group. [Apple's external tester workflow](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/) and [test information requirements](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information/).

The external group already has a public link. After approval, verify its enrollment page offers the latest build, then add that exact URL to the website. If Apple is still reviewing the build, the website should accurately describe the pending beta rather than implying visitors can install it immediately. [Apple's TestFlight overview](https://developer.apple.com/testflight/).

## Repeating the archive and upload

Run from the repository root with the intended Apple Developer account signed into Xcode. Use a new build number for each new upload and retain the numbered archive; builds `1`, `2`, and `3` have already been uploaded. Keep the existing bundle and iCloud identifiers. The checked-in helper accepts a build number and optional version and **archives only**:

```sh
./scripts/archive-testflight.sh 4 1.0
```

It writes the signed archive under `build/releases/SelfieJourney-1.0-4.xcarchive`. Build products and logs remain gitignored. The helper preserves the required Apple Clang linker overrides and does not upload, add testers, submit review, or notify anyone.

For the initial internal release, open that archive in Xcode Organizer, choose **Distribute App → App Store Connect**, and finish the upload. Do not choose TestFlight Internal Only. Wait for Connect processing; **Ready to Submit** supports internal distribution. Verify the correct build in the existing Internal group and save its What to Test. Leave External unchanged.

For a command-line upload when the Xcode account is healthy, use the checked-in [export options](../release/ExportOptions-TestFlight.plist). This command uploads the archive but does not promote it externally:

```sh
xcodebuild -exportArchive \
  -archivePath build/releases/SelfieJourney-1.0-4.xcarchive \
  -exportPath build/releases/export-1.0-4 \
  -exportOptionsPlist release/ExportOptions-TestFlight.plist \
  -allowProvisioningUpdates
```

The options use `method=app-store-connect`, `destination=upload`, automatic signing for team `8U8LFWAQP6`, `manageAppVersionAndBuildNumber=false`, and `testFlightInternalTestingOnly=false`. Retaining this last setting is what allows a later manual external promotion of the same build. Neither the archive helper nor the upload command schedules a promotion.

If CLI export reports missing Xcode account credential keys, use the valid account in Organizer to upload the existing signed archive. Do not infer upload success from an archive alone or a failed CLI log; verify Organizer's upload result and the processed build in Connect. Preserve earlier archives and evidence rather than replacing them with a later build.


## Build-2 upload recovery

`build/releases/upload-1.0-2.log` records the earlier failed CLI attempt, not the later successful GUI delivery. Do not infer the current upload status from that log alone. With the valid account active in Xcode, the existing archive was opened through File → Open, selected in Organizer, and distributed through App Store Connect. Organizer showed upload complete; Connect then processed build 2 and accepted its external beta-review submission.
