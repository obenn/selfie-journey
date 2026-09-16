# Selfie Journey — App Store metadata

Updated September 16, 2026. **The user chose to submit 1.0 (3) for the initial App Store release and keep build 4 for later.** App Store Connect still selects build 3. This audit has not yet completed the submission; do not describe it as submitted or approved.

Build 4 remains a verified local signed archive and is absent from the remote build list. Its generic framing guide and optional background removal are outside this submission. Public copy and screenshots continue to describe build 3.

## Current completion status

| Area | Last verified status |
| --- | --- |
| Release choice, September 16 | **1.0 (3)** selected in Distribution; user explicitly chose build 3 for App Store review and build 4 later |
| Submission, September 16 | **Not submitted yet**. Review fields, privacy publication, pricing/availability, and Apple's final validation still need completion/checks |
| App Store review fields, September 16 | Contact and notes blank; **Sign-in Required is Yes** and must become No. Reuse the contact already saved privately in TestFlight; paste-ready app review notes appear below |
| Browser access, September 16 | Safari repeatedly lost its window during automation. An in-app App Store Connect tab is open at Apple sign-in and retained for handoff; user sign-in is required to continue. No submission fields were changed during this audit |
| Privacy | **Data Not Collected** draft and policy/choices URLs were saved previously. Publication must be rechecked before submitting |
| Pricing and availability | Free is the intended price; confirm saved pricing and existing territory/release choices before submission |
| App information | Previously saved subtitle “Daily selfies to time-lapse”, Photo & Video / Lifestyle categories, and calculated **4+** age rating |
| Version metadata | Saved clarity copy: subtitle 27 characters, promotional text 166, description 1,971, keywords 85 ASCII bytes; entirely free with no subscriptions or in-app purchases |
| Build 3, September 16 | Processed, **Ready to Submit**, assigned to Internal; selected for this App Store submission |
| Build 2, September 16 | External TestFlight status is now **Testing**: Apple approved the beta. This is separate from App Store review |
| Build 4, September 16 | **Local only; absent from Connect**. `build/releases/SelfieJourney-1.0-4.xcarchive` is verified as 1.0 (4). Earlier CLI upload failed on saved Xcode account authentication; no verified delivery |
| Screenshots, September 16 | The live form reconfirmed **3 iPhone screenshots using the 6.9-inch set**. The 3 iPad 13-inch screenshots were verified on September 6 and still need a fresh submission check. Both sets use native Today, Poses, and Onboarding images for build 3 |
| App icon | Previously verified Connect preview matches the opaque bundled 1024×1024 icon |
| Build-3 validation | 4 functional iPhone UI tests, 1 light iPhone capture test, and 1 iPad UI test passed. Earlier build-2 baseline: 49 unit and 7 UI tests passed |
| Build-4 validation, September 7 | 61 unit tests, all 7 iPhone UI cases across the original run/retry, and 2 targeted iPad UI cases passed. Actual Vision passed one macOS fixture; simulator real-Vision smoke skipped. Build 4 is outside this submission |
| Support and privacy, September 16 | https://selfiejourney.com/support/ and https://selfiejourney.com/privacy/ return HTTP 200. The user made the GitHub repository public; anonymous repository and Issues requests now both return HTTP 200 |
| Website | No deployment during this submission audit. Existing copy remains on build 3; see [deployment history](DEPLOYMENT.md) |
| Beta information | Existing TestFlight contact is saved privately and beta Sign-in Required is No. Build-3 What to Test and beta description were saved previously; they are separate from App Store review fields |

Remaining submission work:

1. Complete App Store review contact and notes, reusing the existing private TestFlight contact; set Sign-in Required to No.
2. Verify and publish the Data Not Collected label, and confirm free pricing and existing availability/release settings.
3. Complete Apple's submission validation, submit **build 3**, and verify the resulting App Review status. Record success only after Connect confirms it.

No new upload, build-4 promotion, external tester invitation, website deployment, or repository visibility change is part of these remaining steps. The user has already made GitHub public. The [TestFlight record](TESTFLIGHT.md) keeps the later build-4 plan separate.

## Store copy — saved clarity update

The subtitle, promotional text, description, and keywords below were **saved and revisited in App Store Connect on September 6**. They match build 3, which the user selected for the September 16 App Store submission. Build-4 feature copy is excluded.

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
| Version/build | September 16: **1.0 (3)** selected for App Store submission; build 4 remains local for later |
| Price | Free; user explicitly requested this |
| In-app purchases/subscriptions | None implemented |
| Sign-in required | No in saved TestFlight review information; separate App Store form still says Yes as of the September 16 audit and must be corrected |
| Copyright | 2026 Oliver Benning — saved |
| Review name/email | Oliver Benning / oliver@strikethrough.com — complete and saved for TestFlight |
| Review phone | Provided and saved privately in Connect; do not copy it into the repository |
| Review notes | Use the paste-ready build-3 App Review notes below; not yet confirmed saved |
| App icon | SelfieJourney/Assets.xcassets/AppIcon.appiconset/icon.png; shipped opaque 1024×1024 icon bundled in uploaded build; Connect preview matches |
| Screenshots | Build-3 sets under docs/app-store/iphone and docs/app-store/ipad: all six uploaded, filenames verified, 3 of 10 shown in each device section |

Do not invent copyright ownership wording, business/trader status, legal contact details, territorial regulatory registrations, release timing, or accessibility conformance. Preserve existing answers when they are account decisions rather than properties inferable from the source. A personal photo journal is not a medical or health-monitoring product.

## App privacy answers — build 2 onward

**Data Not Collected** was saved in App Store Connect as a draft, with the preview verified. It describes the no-collection implementation introduced in **1.0 (2)** and retained in subsequent source, rather than expired build 1. The store privacy label has not been verified as published.

The replacement app has no analytics client, installation identifier, local diagnostic ring, feedback form, or collection transport. `NSPrivacyTracking` is false and `NSPrivacyCollectedDataTypes` is empty. App-only UserDefaults remain declared with reason `CA92.1`. User photos and notes remain local; optional backups use the user's private iCloud Drive. On-device camera analysis is not developer collection.

Build 4's optional background removal also runs entirely on device, using Apple Vision person masks and Core Image to process export copies. Original photos and private iCloud backups remain unchanged. No photos, masks, or processing results are sent to the developer. Validate the signed build's manifest and network behavior as part of release checks; the feature does not introduce a new collection purpose.

GitHub support is an ordinary external browser link with no attached identifiers, device details, logs, or app content. Voluntary issues are governed by GitHub's privacy policy and can be public. The website's ordinary Cloudflare requests and retained historical build-1 records are explained separately in the privacy policy. See Apple's [App privacy details guidance](https://developer.apple.com/app-store/app-privacy-details/) for the collection boundary and Apple-service distinction.

Build 1's former five-type label (Device ID, Product Interaction, Other Diagnostic Data, Email Address, Customer Support) described that earlier implementation. Removing those declarations alone would not make build 1 a no-collection app. The retired API endpoints reject old-client submissions with verified 410 responses. At the September 16 check, build 2 is Testing externally and the separate Distribution draft selects build 3. App Store review information and privacy-label publication still require completion/verification.

## App Review notes — ready to paste for build 3

Prepared September 16 for the selected App Store build; not yet confirmed saved in Connect. Copy only the text below.

Selfie Journey lets users take one selfie each day with consistent face framing and turn their saved photos into a time-lapse video. It supports iPhone and iPad running iOS/iPadOS 18 or later. The app is completely free, with no subscriptions, in-app purchases, advertising, or paid features. No separate account, sign-in, or demo credentials are required.

To review: complete onboarding, choose one of four portrait distances, and set or skip the daily reminder. On Today, tap Take today's selfie and grant camera permission. Try the framing and lighting advice, previous-photo overlay, and optional timer. Library imports a user-selected photo through Apple's Photos picker. Save a selfie with an optional note; saving again on the same day replaces that day's photo. Journal shows the saved daily photos.

In Lookback (Your time-lapse), photos play in date order. Video creation requires photos saved on at least two different days, so a fresh installation initially shows an empty or one-photo state. Once eligible, choose the pace and whether to show dates, then tap Create time-lapse video and share through the standard iOS share sheet. Videos use the user's actual photos.

Photos and notes stay on device. Optional iCloud Drive backups use the user's private iCloud storage and require an Apple Account, iCloud Drive, and available storage. Capture and the journal work without iCloud. We cannot access these backups.

The app collects no data and sends no analytics, tracking identifiers, or diagnostic uploads. Face guidance and video creation run on device. Settings links to the public GitHub project and Issues in the browser without attaching app content or logs; posting there is optional.

The app uses Apple's system iCloud/networking facilities and CryptoKit SHA-256 for backup integrity, with no custom encryption. Privacy policy: https://selfiejourney.com/privacy/. Support: https://selfiejourney.com/support/.

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
