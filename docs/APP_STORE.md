# Selfie Journey — App Store metadata

Updated September 6, 2026 from the shipped 1.0 source, privacy manifest, service implementation, and the current App Store Connect session. The status below separates verified saved fields from entries still awaiting verification or upload. The app has not been submitted for public App Store release review. Build 2 remains Waiting for Review in the latest observed TestFlight state. Build 3 uploaded, processed, and is Ready to Submit with the internal group’s two testers assigned. Its external submission is blocked while build 2 remains in review.

## Current completion status

| Area | Verified status |
| --- | --- |
| App information | Subtitle “Daily selfies to time-lapse”, primary Photo & Video, secondary Lifestyle, and calculated **4+** age rating saved |
| Privacy URLs | Policy and Choices both saved as https://selfiejourney.com/privacy/ |
| Privacy draft | **Data Not Collected** saved and preview verified for the replacement build 2; not yet published |
| Version metadata | Clarity copy saved and revisited in Connect: subtitle 27 characters, promotional text 166, description 1,971, keywords 85 ASCII bytes |
| Native clarity revision | **1.0 (3)** uploaded and processed; Connect lists September 6 at **8:14 PM America/Toronto**. Status **Ready to Submit**, assigned to the internal group’s 2 testers |
| Beta review fields | Actual contact complete and saved privately; Sign-in Required = No. New 1,044-character beta description saved. Build-3 What to Test (1,434 characters) saved and confirmed; build-3 review notes remain prepared, not saved. Earlier build-2 review notes remain |
| App Store review fields | Distribution-form contact/notes were previously incomplete; recheck separately before a public App Store submission. Use the contact already provided rather than asking for it again |
| Builds | Build 3 processed and assigned internally. Build 2 remains **Waiting for Review** externally; Connect permits only one build of version 1.0 in beta review at a time. **App Store Distribution selects build 3**, saved and verified |
| App icon | Connect's icon preview verified against the bundled icon |
| Native verification | Build 3: 4 functional iPhone UI tests, 1 light iPhone capture test, and 1 iPad UI test passed. Earlier build-2 baseline: 49 unit tests and 7 UI tests passed |
| Website/service | Clarity copy live: deployment `a220c401-cf84-464e-ba93-170405040f3f`, Worker version `98be3939-40f6-4d3b-ac65-8adfc77891df`, September 7 at 00:12:34 UTC. See [deployment evidence](DEPLOYMENT.md) |
| TestFlight external | Existing group: **1 tester, 1 build**, build 2 **Waiting for Review**; automatic tester notification enabled. Existing public link: https://testflight.apple.com/join/ucGAbHsd; testers cannot join until the group has an approved build |
| TestFlight internal | **2 existing testers**, added manually by the user; build 3 assigned automatically and available for internal testing |
| Previous build | Build 1 is expired in TestFlight |
| Screenshots | **All six build-3 screenshots uploaded and verified in Connect**: Today, Poses, Onboarding for iPhone 6.9-inch and iPad 13-inch. Both sections show 3 of 10 screenshots with matching filenames |

Public App Store release work still remaining:

1. Complete/recheck the separate App Store review contact and notes, using the contact already supplied; set Sign-in Required to No.
2. Verify and publish the Data Not Collected label before submitting the public App Store release.

**Build 2 remains Waiting for Review externally. Build 3 is processed and assigned to the two internal testers.** Connect blocks another version-1.0 beta submission until the current review is approved; build 3 has not been submitted externally. The steps above concern the public App Store listing and do not block the beta submission. The privacy label remains unpublished. For internal invitations and external approval, see [TestFlight status](TESTFLIGHT.md).

## Store copy — saved clarity update

The subtitle, promotional text, description, and keywords below were **saved and revisited in App Store Connect**. Build 3 includes the matching native wording and has uploaded successfully. It has processed and is assigned internally. It has not replaced build 2 in external review.

**Name:** Selfie Journey

**Subtitle (27/30 characters):** Daily selfies to time-lapse

**Promotional text (166/170 characters):**

One selfie a day. Watch yourself change. Match your framing with face guides, then make a time-lapse of your photos over the years. Completely free. No subscriptions.

**Description (1971/4,000 characters):**

One selfie a day. Watch yourself change.

Take a selfie every day, use face guides to keep your framing consistent, and turn your photos into a time-lapse video of how you change over months and years.

Selfie Journey is completely free. No subscriptions, in-app purchases, or paid feature gates.

KEEP YOUR FACE IN A FAMILIAR POSITION
Choose from four portrait distances, from close-up to wide. Face and eye-line guides help you line up each selfie. See a subtle overlay of your previous photo, with on-device advice for position, head angle, and lighting. Take the photo when you are ready, or use the three-second timer.

BUILD A DAILY HABIT
Choose a reminder time that fits your day. Your streak, weekly progress, and milestones make it easy to keep going. If you miss a day, every photo you have taken is still part of your collection.

SEE THE CHANGES IN A TIME-LAPSE
Open Lookback to play your selfies in date order. Choose the pace and show or hide dates, then create a video from the photos you actually took. As your collection grows, watch how your face changes with age. Export requires selfies from at least two different days, and sharing uses the familiar iOS share sheet.

KEEP YOUR DAILY PHOTOS
Save one selfie each day, add an optional note, and browse your journal by month. Retake today's selfie whenever you like, or choose a photo with Apple's photo picker.

YOUR PHOTOS STAY WITH YOU
Photos and notes live on your device. Optional iCloud Drive backups keep dated copies in your own private iCloud storage, with a restore option for missing days. No separate Selfie Journey account is needed.

NO DATA COLLECTED
Face guidance and video creation run on your device. The app has no analytics, tracking identifiers, or diagnostic uploads. Settings can open GitHub if you want to suggest an improvement or report a bug; you choose what to post, and the app attaches no data or logs.

Start with today's selfie. Keep taking them. See the years in motion.

**Keywords (85/100 characters, ASCII bytes):**

portrait,daily,diary,timelapse,streak,memories,camera,face,aging,video,photo,progress

## Product fields

| Field | Value / current status |
| --- | --- |
| Primary category | Photo & Video — saved |
| Secondary category | Lifestyle — saved |
| Marketing URL | https://selfiejourney.com/ |
| Support URL | https://selfiejourney.com/support/ |
| Privacy policy URL | https://selfiejourney.com/privacy/ — saved |
| Privacy choices URL | https://selfiejourney.com/privacy/ — saved |
| App Store Connect app ID | 6809197003 |
| Bundle ID | com.strikethrough.PicaDay — preserve |
| Version/build | Build 3 processed and assigned internally; external submission awaits the current version-1.0 review. App Store Distribution selects build 3; saved and verified |
| Price | Free; user explicitly requested this |
| In-app purchases/subscriptions | None implemented |
| Sign-in required | No in saved TestFlight review information; verify the separate App Store review form before public release |
| Copyright | 2026 Oliver Benning — saved |
| Review name/email | Oliver Benning / oliver@strikethrough.com — complete and saved for TestFlight |
| Review phone | Provided and saved privately in Connect; do not copy it into the repository |
| Review notes | See [TESTFLIGHT.md](TESTFLIGHT.md), “Beta App Review notes”; also suitable for the initial App Store review |
| App icon | SelfieJourney/Assets.xcassets/AppIcon.appiconset/icon.png; shipped opaque 1024×1024 icon bundled in uploaded build; Connect preview matches |
| Screenshots | Build-3 sets under docs/app-store/iphone and docs/app-store/ipad: all six uploaded, filenames verified, 3 of 10 shown in each device section |

Do not invent copyright ownership wording, business/trader status, legal contact details, territorial regulatory registrations, release timing, or accessibility conformance. Preserve existing answers when they are account decisions rather than properties inferable from the source. A personal photo journal is not a medical or health-monitoring product.

## App privacy answers — build 2

**Data Not Collected** is saved in App Store Connect as a draft, with the preview verified. It describes **1.0 (2)**, now uploaded and in TestFlight review, rather than the expired build 1. The store privacy label has not been published.

The replacement app has no analytics client, installation identifier, local diagnostic ring, feedback form, or collection transport. `NSPrivacyTracking` is false and `NSPrivacyCollectedDataTypes` is empty. App-only UserDefaults remain declared with reason `CA92.1`. User photos and notes remain local; optional backups use the user's private iCloud Drive. On-device camera analysis is not developer collection.

GitHub support is an ordinary external browser link with no attached identifiers, device details, logs, or app content. Voluntary issues are governed by GitHub's privacy policy and can be public. The website's ordinary Cloudflare requests and retained historical build-1 records are explained separately in the privacy policy. See Apple's [App privacy details guidance](https://developer.apple.com/app-store/app-privacy-details/) for the collection boundary and Apple-service distinction.

Build 1's former five-type label (Device ID, Product Interaction, Other Diagnostic Data, Email Address, Customer Support) described that earlier implementation. Removing those declarations alone would not make build 1 a no-collection app. The retired API endpoints now reject old-client submissions with verified 410 responses. Build 2 is now in TestFlight review; the separate Distribution draft now selects build 3, saved and verified. App Store review information and privacy-label publication remain unfinished.

## Review notes — proposed for build 3

Prepared for the wording update; not yet confirmed saved in Connect.

Selfie Journey is a daily selfie and time-lapse app for iPhone and iPad, supporting iOS/iPadOS 18 or later. Users take one selfie each day, use face guides to keep their framing similar, and turn the saved photos into a video showing changes over time. The video is made from actual user photos.

Build 3 clarifies this daily-selfie → consistent-framing → time-lapse flow in the interface. The app is completely free, with no subscriptions, in-app purchases, advertising, or paid feature gates. No separate account, demo credentials, or sign-in is required.

Complete onboarding by choosing a portrait distance and optional reminder time. On Today, tap Take today's selfie and grant camera permission to try live capture and framing advice. Library in the camera screen imports a user-selected photo through Apple's Photos picker. Save a selfie with an optional note. Another save on the same day replaces that day's photo.

Face, position, distance, and lighting guidance runs on device and helps the user frame the photo before capture. Journal shows the saved daily photos. Open Lookback, titled Your time-lapse, to preview them in date order. Create time-lapse video becomes available with photos from at least two different days, so a new installation initially shows an empty or one-frame state.

Photos and notes remain local. Optional iCloud Drive backups require an Apple Account with iCloud Drive and available storage; capture and the journal work without iCloud. We cannot access the user's private backups.

The app collects no data and sends no analytics, tracking identifiers, or diagnostic uploads. Settings can open GitHub Issues in the system browser without attaching app content or logs. The user decides whether to post on that separate service.

Network-backed journal storage uses Apple's iCloud facilities. CryptoKit SHA-256 checks backup file integrity; the app implements no custom encryption. Privacy policy: https://selfiejourney.com/privacy/.

## Age rating questionnaire

The questionnaire was completed from the current app's features, and the saved result is **4+**. The source-based answers are:

- Parental Controls: **No**. Age Assurance: **No**.
- Unrestricted Web Access: **No**. Policy links open the system browser; no embedded browser is implemented.
- User-Generated Content: **No**. There is no public feed or in-app distribution to other users. Private portraits/notes and an iOS share sheet do not form a publishing community.
- Social Media: **No**. Messaging and Chat: **No**. Advertising: **No**.
- Profanity/Crude Humor, Horror/Fear, Alcohol/Tobacco/Drug Use, Medical/Treatment Information: **None**.
- Health/Wellness Topics: **No**. The routine is a photo habit; it gives no diet, exercise, treatment, or self-care advice.
- Mature/Suggestive Themes, Sexual Content/Nudity, Graphic Sexual Content/Nudity: **None**.
- Cartoon/Fantasy Violence, Realistic Violence, Prolonged Graphic/Sadistic Violence, Guns/Weapons: **None**.
- Gambling: **No**. Simulated Gambling and Contests: **None**. Loot Boxes: **No**.
- Made for Kids / age-category override: **Not Applicable**. Do not claim Kids-category eligibility or impose an invented minimum age.

Apple calculated the general **4+** rating from the saved answers. No unsupported regional classification or age override was entered. Capability labels were interpreted using Apple's [current age-rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions), especially its definition of UGC as broad distribution, and the [rating setup flow](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/).
