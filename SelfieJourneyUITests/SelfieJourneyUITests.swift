import XCTest

final class SelfieJourneyUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchEmptyJournal() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.buttons["today.capture"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor
    private func keepScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        func isVisibleForInteraction() -> Bool {
            guard element.isHittable else { return false }
            // SwiftUI can report offscreen scroll content as hittable. The
            // onboarding footer stays fixed over that content, so reveal the
            // control's center above it before synthesizing a tap.
            let footer = app.buttons["onboarding.continue"]
            let visibleBottom = footer.exists ? footer.frame.minY : app.frame.maxY
            return element.frame.midY < visibleBottom && element.frame.midY > app.frame.minY
        }
        for _ in 0..<5 {
            if isVisibleForInteraction() { return }
            app.swipeUp()
        }
        XCTAssertTrue(isVisibleForInteraction(), "Expected this control to be reachable by scrolling: \(element)")
    }

    @MainActor
    private func dismissCameraPermissionIfPresent() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 3) else { return }
        let deny = alert.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Don’t Allow", "Don't Allow")).firstMatch
        XCTAssertTrue(deny.exists, "Expected the camera permission prompt")
        if deny.exists { deny.tap() }
    }

    @MainActor
    func testOnboardingChoosesPoseSkipsRemindersAndKeepsLaterChanges() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--onboarding", "--reset-onboarding"]
        app.launch()
        XCTAssertTrue(app.staticTexts["onboarding.welcome"].waitForExistence(timeout: 10))
        keepScreenshot("onboarding", app: app)
        app.buttons["onboarding.continue"].tap()

        let classic = app.buttons["pose.classic"]
        XCTAssertTrue(classic.waitForExistence(timeout: 5))
        XCTAssertTrue(classic.isSelected, "A new journey should start with the recommended classic frame")
        keepScreenshot("poses", app: app)
        let wide = app.buttons["pose.wide"]
        reveal(wide, in: app)
        wide.tap()
        XCTAssertTrue(wide.isSelected)
        app.buttons["onboarding.continue"].tap()

        let time = app.descendants(matching: .any).matching(identifier: "onboarding.reminderTime").firstMatch
        XCTAssertTrue(time.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.enableReminder"].exists)
        keepScreenshot("reminder", app: app)
        // Permission stays under the user's control: this path does not tap
        // Enable or interact with a real system notification prompt.
        app.buttons["onboarding.skipReminder"].tap()
        XCTAssertTrue(app.buttons["today.capture"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["onboarding.welcome"].exists)
        keepScreenshot("today", app: app)

        app.buttons["today.settings"].tap()
        let reminder = app.switches["settings.reminderToggle"]
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
        XCTAssertEqual(reminder.value as? String, "0")
        let poseSettings = app.buttons["settings.pose"]
        reveal(poseSettings, in: app)
        poseSettings.tap()
        XCTAssertTrue(app.navigationBars["Your portrait frame"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["pose.wide"].isSelected)

        let close = app.buttons["pose.close"]
        reveal(close, in: app)
        close.tap()
        XCTAssertTrue(close.isSelected)
        app.navigationBars["Your portrait frame"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["settings.done"].waitForExistence(timeout: 5))
        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.buttons["today.capture"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchArguments = ["--uitesting", "--onboarding"]
        app.launch()
        XCTAssertTrue(app.buttons["today.capture"].waitForExistence(timeout: 10), "Completed setup should not return on another launch")
        XCTAssertFalse(app.staticTexts["onboarding.welcome"].exists)
        app.buttons["today.settings"].tap()
        reveal(app.buttons["settings.pose"], in: app)
        app.buttons["settings.pose"].tap()
        XCTAssertTrue(app.buttons["pose.close"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["pose.close"].isSelected, "A frame changed in settings should survive relaunch")
        app.navigationBars["Your portrait frame"].buttons.element(boundBy: 0).tap()

    }

    @MainActor
    func testFirstPortraitOffersPhotoImportWhenCameraIsUnavailable() {
        let app = launchEmptyJournal()
        let capture = app.buttons["today.capture"]
        reveal(capture, in: app)
        capture.tap()
        XCTAssertTrue(app.buttons["capture.close"].waitForExistence(timeout: 5))
        dismissCameraPermissionIfPresent()

        #if targetEnvironment(simulator)
        let fallback = app.staticTexts.matching(NSPredicate(
            format: "label == %@ OR label == %@",
            "Your portrait goes here.", "Let’s see you."
        )).firstMatch
        XCTAssertTrue(fallback.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["capture.shutter"].isEnabled)
        #endif

        let importButton = app.buttons["capture.import"]
        reveal(importButton, in: app)
        XCTAssertTrue(importButton.isEnabled)
        importButton.tap()
        let cancelPicker = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancelPicker.waitForExistence(timeout: 5))
        cancelPicker.tap()
        XCTAssertTrue(app.buttons["capture.close"].waitForExistence(timeout: 5))
        app.buttons["capture.close"].tap()
        XCTAssertTrue(app.buttons["today.capture"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["capture.save"].exists)
    }

    @MainActor
    func testEmptyJournalAndLookbackLeadToTheFirstPortrait() {
        let app = launchEmptyJournal()
        app.tabBars.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts["Your selfies, day by day."].waitForExistence(timeout: 5))
        let firstPortrait = app.buttons["Take your first selfie"]
        reveal(firstPortrait, in: app)
        firstPortrait.tap()
        XCTAssertTrue(app.buttons["capture.close"].waitForExistence(timeout: 5))
        dismissCameraPermissionIfPresent()
        app.buttons["capture.close"].tap()
        XCTAssertTrue(app.staticTexts["Your selfies, day by day."].waitForExistence(timeout: 5))

        app.tabBars.buttons["Lookback"].tap()
        let emptyFilm = app.staticTexts["See yourself change."]
        XCTAssertTrue(emptyFilm.waitForExistence(timeout: 5))
        let begin = app.buttons["Take your first selfie"]
        reveal(begin, in: app)
        begin.tap()
        XCTAssertTrue(app.buttons["capture.close"].waitForExistence(timeout: 5))
        app.buttons["capture.close"].tap()
        XCTAssertTrue(emptyFilm.waitForExistence(timeout: 5))
    }

    @MainActor
    func testDailyRitualSettingsAndPortraitGuide() {
        let app = launchEmptyJournal()
        app.buttons["today.settings"].tap()
        XCTAssertTrue(app.navigationBars["Your daily ritual"].waitForExistence(timeout: 5))
        let reminder = app.switches["settings.reminderToggle"]
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
        let reminderControl = reminder.switches.firstMatch
        if reminder.value as? String != "1" { reminderControl.tap() }
        let time = app.descendants(matching: .any).matching(identifier: "settings.reminderTime").firstMatch
        XCTAssertTrue(time.waitForExistence(timeout: 5))
        reminderControl.tap()
        XCTAssertFalse(time.exists)

        let github = app.buttons["settings.githubIssues"]
        reveal(github, in: app)
        XCTAssertTrue(github.exists, "Suggestions and bug reports should open GitHub instead of collecting feedback in the app")
        XCTAssertTrue(app.buttons["settings.githubRepository"].exists)
        XCTAssertFalse(app.buttons["settings.telemetry"].exists)

        let guide = app.buttons["A guide to your daily portrait"]
        reveal(guide, in: app)
        guide.tap()
        XCTAssertTrue(app.navigationBars["The portrait guide"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Find your light"].exists)
        XCTAssertTrue(app.staticTexts["Meet the guide"].exists)
        app.navigationBars["The portrait guide"].buttons["Done"].tap()
        XCTAssertTrue(app.buttons["settings.done"].waitForExistence(timeout: 5))
        app.buttons["settings.done"].tap()
        XCTAssertTrue(app.buttons["today.settings"].waitForExistence(timeout: 5))

        app.buttons["today.settings"].tap()
        XCTAssertTrue(app.switches["settings.reminderToggle"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.switches["settings.reminderToggle"].value as? String, "0")
        app.buttons["settings.done"].tap()
    }
}
