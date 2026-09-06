# App Store screenshots

All six images were regenerated from the no-collection **1.0 build 2** source and visually verified. The iPad welcome screen visibly includes the new privacy card; on iPhone it sits below the initial scroll position. No reporting controls appear.

Captured on September 6, 2026 from the native app using the existing onboarding UI test. These are unmodified, opaque PNG screenshot attachments exported with `xcresulttool`; they are not resized or generated mockups.

| Set | Simulator | Dimensions | Suggested order |
| --- | --- | --- | --- |
| `iphone/` | iPhone 17 Pro Max, iOS 26.5 | 1320 × 2868 | `today.png`, `poses.png`, `onboarding.png` |
| `ipad/` | iPad Pro 13-inch (M5), iPadOS 26.5 | 2064 × 2752 | `today.png`, `poses.png`, `onboarding.png` |

Use the iPhone set in App Store Connect's **6.9-inch display** section and the iPad set in its **13-inch display** section. [Apple's screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

The app icon is supplied through the uploaded app build from `SelfieJourney/Assets.xcassets/AppIcon.appiconset/icon.png`; it does not belong in a screenshot slot. It is an opaque 1024 × 1024 PNG.

## Upload status

The replacement six-image set is ready locally but **not yet uploaded to App Store Connect**. Connect currently retains the earlier three iPhone screenshots and one iPad screenshot. The earlier session paused before replacement could finish. Replace that set with all six files below and verify their rendered previews as part of the public App Store listing work. This is separate from build 2’s already-submitted TestFlight review. The existing icon preview already matches the bundled app icon.

## Capture and verification

Run only `SelfieJourneyUITests/SelfieJourneyUITests/testOnboardingChoosesPoseSkipsRemindersAndKeepsLaterChanges` with `xcodebuild test`, the desired simulator destination, and `LD=/usr/bin/clang LDPLUSPLUS=/usr/bin/clang++`. Supply separate result bundle paths for each device. Export attachments with:

```sh
xcrun xcresulttool export attachments \
  --path /path/to/result.xcresult \
  --output-path /path/to/exported-attachments
```

Use the exported `manifest.json` to select the attachments named `today`, `poses`, and `onboarding`. The test also captures the reminder screen, which is intentionally omitted from these three-image sets.

The build-2 runs passed with zero failures:

- iPhone: `/tmp/selfiejourney-no-collection-iphone.xcresult` — 49 unit tests and 6 UI tests.
- iPad: `/tmp/selfiejourney-no-collection-ipad.xcresult` — 1 targeted onboarding UI test.

The UI test's reveal helper checks the control's position against the fixed onboarding footer, because SwiftUI can report scroll content as hittable before it is visible above that footer. These captures include the replacement privacy copy and exclude all old reporting choices. All PNG dimensions and opacity were verified, and no image resizing or visual editing was applied.
