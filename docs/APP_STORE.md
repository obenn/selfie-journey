# Selfie Journey — App Store metadata

Updated September 6, 2026 from the shipped 1.0 source, privacy manifest, service implementation, and the current App Store Connect session. The status below separates verified saved fields from entries still awaiting verification or upload. The app has not been submitted for App Store review in this session.

## Current completion status

| Area | Verified status |
| --- | --- |
| App information | Subtitle “Your life, one portrait a day”, primary Photo & Video, secondary Lifestyle, and calculated **4+** age rating saved |
| Privacy URLs | Policy and Choices both saved as https://selfiejourney.com/privacy/ |
| Privacy draft | **Data Not Collected** saved and preview verified for the replacement build 2; not yet published |
| Version metadata | New 1,853-character no-collection description saved (Save disabled after success); promotional text, keywords, marketing/support URLs, and copyright also saved |
| Review fields | Currently blank in Connect; Sign-in Required currently Yes. Enter the actual contact details, set No, and save together. A previous attempt confirmed that a valid review phone number is required; none has been provided |
| Build | Signed **1.0 (2)** archive succeeded at `build/releases/SelfieJourney-1.0-2.xcarchive`; its manifest is empty, tracking is off, and old API/collection code is absent. Export failed: `exportArchive Failed to Use Accounts`, missing Xcode credential keys. **Build 2 is not uploaded or selected; build 1 remains selected** |
| App icon | Connect's icon preview verified against the bundled icon |
| Native verification | Build-2 iPhone run: 49 unit and 6 UI tests; iPad run: 1 onboarding UI test; zero failures |
| Website/service | No-collection website and retired intake deployed at 18:33:58 UTC, deployment `8686d2acd95c4131b412ea3600c3a3aa`; public pages, 410 responses, and admin protection verified |
| Current interruption | Safari/Mac locked. Unlock was requested; it remained locked when checked two minutes later |
| Screenshots | Six native build-2 screenshots are ready locally: iPhone 1320 × 2868 and iPad 2064 × 2752 opaque PNGs. **Connect still has the earlier 3 iPhone + 1 iPad screenshots; none of the replacement set is confirmed uploaded** |

Next steps when the Mac is unlocked:

1. Retry export/upload from the existing signed build-2 archive. If Xcode still reports missing account credentials, restore the Apple account session in Xcode before retrying; do not change the bundle ID or rebuild merely to change the number.
2. After Apple processes build 2, replace the selected build 1 with build 2.
3. Replace the earlier screenshots with the three verified build-2 images for each device class, then verify all six in Connect.
4. Enter the actual review contact phone/name/email and review notes, set Sign-in Required to No, and save together. The phone requirement previously blocked this save.
5. Verify the Data Not Collected draft against the selected build 2 before publishing privacy details or submitting the app for review.

**Neither the privacy label nor a new beta has been published.** The saved description alone does not replace the uploaded app binary.

## Store copy

**Name:** Selfie Journey

**Subtitle (29/30 characters):** Your life, one portrait a day

**Promotional text (154/170 characters):**

Completely free. No subscriptions. Capture a daily portrait with gentle framing guides, build your streak, and turn everyday moments into a lookback film.

**Description:**

Selfie Journey is completely free. No subscriptions, in-app purchases, or paid feature gates.

One portrait a day. A little ritual. A life in motion.

Keep a quiet record of the everyday you. Take a portrait in seconds, return tomorrow, and watch those small moments become a beautiful lookback film over time.

FIND YOUR FRAME
Choose from four portrait distances, from close-up to wide. Gentle guides help you match your framing, while on-device face and lighting advice helps you find your position. Use a previous portrait as a subtle alignment overlay, or give yourself a moment with the three-second timer.

MAKE IT A DAILY RITUAL
Pick a reminder time that fits your day. Follow your current streak, weekly progress, and milestones with a little encouragement each time you show up. Miss a day? Your memories are still there, ready for the next chapter.

KEEP THE MOMENT
Save one portrait each day, add a few words, and browse your growing journal by month. Retake today's photo whenever you like, or choose a portrait with Apple's photo picker.

WATCH YOUR STORY UNFOLD
Play your portraits in order, choose the pace, and show or hide dates. With portraits from at least two days, export a lookback film and share it using the familiar iOS share sheet.

YOUR JOURNAL, WITH YOU
Your portraits and notes live on your device. Optional iCloud Drive backups keep dated snapshots in your own iCloud storage, with a restore option for missing days. No separate Selfie Journey account is needed.

NO DATA COLLECTED
The app has no analytics, tracking, device identifiers, or diagnostic uploads. Face guidance and film creation run on your device. If you have an idea or find a bug, Settings can open GitHub in your browser. You choose what to post; the app attaches no personal data or logs.

A small ritual with a long horizon. Start with today's portrait.

**Keywords (84/100 characters):**

portrait,dailyphoto,diary,timelapse,streak,memories,camera,face,aging,lookback,habit

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
| Version/build | Replace the currently selected 1.0 (1) with the no-collection 1.0 (2) after upload and processing |
| Price | Free; user explicitly requested this |
| In-app purchases/subscriptions | None implemented |
| Sign-in required | Must be No; current Connect review form is reset to Yes and awaits completion |
| Copyright | 2026 Oliver Benning — saved |
| Review name/email | Oliver Benning / oliver@strikethrough.com — must be re-entered with a valid phone number |
| Review phone | Use the user's actual number if already supplied in Connect; otherwise leave for the user |
| Review notes | See [TESTFLIGHT.md](TESTFLIGHT.md), “Beta App Review notes”; also suitable for the initial App Store review |
| App icon | SelfieJourney/Assets.xcassets/AppIcon.appiconset/icon.png; shipped opaque 1024×1024 icon bundled in uploaded build; Connect preview matches |
| Screenshots | Three verified build-2 screenshots per device class under docs/app-store/iphone and docs/app-store/ipad. Connect still has the earlier 3 iPhone + 1 iPad set; replacements not uploaded |

Do not invent copyright ownership wording, business/trader status, legal contact details, territorial regulatory registrations, release timing, or accessibility conformance. Preserve existing answers when they are account decisions rather than properties inferable from the source. A personal photo journal is not a medical or health-monitoring product.

## App privacy answers — build 2

**Data Not Collected** is saved in App Store Connect as a draft, with the preview verified. It must describe the final **1.0 (2)** binary, not the earlier uploaded build 1. Publication has not yet been confirmed.

The replacement app has no analytics client, installation identifier, local diagnostic ring, feedback form, or collection transport. `NSPrivacyTracking` is false and `NSPrivacyCollectedDataTypes` is empty. App-only UserDefaults remain declared with reason `CA92.1`. User photos and notes remain local; optional backups use the user's private iCloud Drive. On-device camera analysis is not developer collection.

GitHub support is an ordinary external browser link with no attached identifiers, device details, logs, or app content. Voluntary issues are governed by GitHub's privacy policy and can be public. The website's ordinary Cloudflare requests and retained historical build-1 records are explained separately in the privacy policy. See Apple's [App privacy details guidance](https://developer.apple.com/app-store/app-privacy-details/) for the collection boundary and Apple-service distinction.

Build 1's former five-type label (Device ID, Product Interaction, Other Diagnostic Data, Email Address, Customer Support) described that earlier implementation. Removing those declarations alone would not make build 1 a no-collection app. The retired API endpoints now reject old-client submissions with verified 410 responses. The selected binary still needs replacement with build 2 before release.

## Review notes — build 2

Selfie Journey is a daily portrait journal for iPhone and iPad, supporting iOS/iPadOS 18 or later. It is completely free, with no subscriptions, in-app purchases, advertising, or paid feature gates. No separate account, demo credentials, or sign-in is required.

Complete onboarding by choosing a portrait frame and optional reminder time. From Today, grant camera permission to try live capture and framing guidance, or choose Library in the camera screen to import a user-selected photo through Apple's Photos picker. Save a portrait with an optional note. Saving another portrait on the same day replaces that day's image.

Face, position, distance, and lighting guidance runs on device. The app does not identify people. Portraits and notes are stored locally. Optional iCloud Drive backups require iCloud Drive and available storage on the user's Apple Account; capture and the journal work without iCloud. We cannot access the user's private backups.

Journal shows saved portraits. Lookback can preview the collection; movie export requires portraits from at least two different days. A new installation therefore starts with an empty or one-frame state.

Build 2 removes the earlier feedback, diagnostics, and analytics implementation. The app collects no data, has no reporting identifier, and sends no analytics or log uploads. Settings can open GitHub Issues in the system browser without attaching content, identifiers, or logs. The user independently chooses whether to post on that external service.

Network-backed journal storage uses Apple's iCloud facilities. CryptoKit SHA-256 checks backup file integrity; the app implements no custom encryption. The privacy policy is https://selfiejourney.com/privacy/.

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
