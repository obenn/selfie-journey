import XCTest

final class FeedbackUITests: XCTestCase {
    @MainActor
    func testExistingJournalAcknowledgesReportingOnceAndKeepsItsChoice() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-support", "--reporting-disclosure"]
        app.launch()
        XCTAssertTrue(app.staticTexts["reporting.disclosure"].waitForExistence(timeout: 10))
        let levels = app.segmentedControls["settings.telemetryLevel"]
        XCTAssertTrue(levels.buttons["Full"].isSelected)
        levels.buttons["Limited"].tap()
        app.buttons["reporting.continue"].tap()
        XCTAssertTrue(app.buttons["today.settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["reporting.disclosure"].exists)
        app.terminate()
        app.launchArguments = ["--uitesting", "--reporting-disclosure"]
        app.launch()
        XCTAssertTrue(app.buttons["today.settings"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["reporting.disclosure"].exists)
        app.buttons["today.settings"].tap()
        reveal(app.buttons["settings.telemetry"], in: app)
        app.buttons["settings.telemetry"].tap()
        XCTAssertTrue(levels.waitForExistence(timeout: 5))
        XCTAssertTrue(levels.buttons["Limited"].isSelected)
    }

    @MainActor
    func testReportingCanBeDisabledAndFeedbackLogsAreAnExplicitChoice() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-support"]
        app.launch()
        XCTAssertTrue(app.buttons["today.settings"].waitForExistence(timeout: 10))
        app.buttons["today.settings"].tap()
        reveal(app.buttons["settings.telemetry"], in: app)
        app.buttons["settings.telemetry"].tap()
        let levels = app.segmentedControls["settings.telemetryLevel"]
        XCTAssertTrue(levels.waitForExistence(timeout: 5))
        XCTAssertTrue(levels.buttons["Full"].isSelected)
        levels.buttons["Off"].tap()
        XCTAssertTrue(levels.buttons["Off"].isSelected)
        app.navigationBars["Usage & reliability"].buttons.element(boundBy: 0).tap()

        reveal(app.buttons["settings.feedback"], in: app)
        app.buttons["settings.feedback"].tap()
        let field = app.textViews["feedback.message"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        let send = app.buttons["feedback.send"]
        XCTAssertTrue(send.waitForExistence(timeout: 5))
        XCTAssertFalse(send.isEnabled)
        field.tap()
        field.typeText("A test note that must never reach the production service.")
        let logs = app.switches["feedback.includeLogs"]
        reveal(logs, in: app)
        XCTAssertEqual(logs.value as? String, "0")
        XCTAssertFalse(app.buttons["feedback.previewLogs"].exists)
        logs.switches.firstMatch.tap()
        let preview = app.buttons["feedback.previewLogs"]
        reveal(preview, in: app)
        preview.tap()
        XCTAssertTrue(app.navigationBars["Diagnostic preview"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Exactly what will be attached."].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "diagnostic-preview"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.navigationBars["Diagnostic preview"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(send.isEnabled)
        send.tap()
        // DEBUG's --uitesting transport is disabled: this validates the failure
        // state and retained draft without sending any user content to production.
        let error = app.descendants(matching: .any)["feedback.error"].firstMatch
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "A test note that must never reach the production service.")
        XCTAssertTrue(send.isEnabled)
    }

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
}
