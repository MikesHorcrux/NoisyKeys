//
//  NoisyKeysUITests.swift
//  NoisyKeysUITests
//
//  Created by Mike  Van Amburg on 3/29/26.
//

import XCTest

final class NoisyKeysUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testOnboardingLetsYouPickAndPreviewAStartingSound() throws {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_RESET_ONBOARDING"]
        app.launch()

        let primaryButton = app.buttons["Continue"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 5))
        primaryButton.tap()
        primaryButton.tap()

        let selectedSound = app.descendants(matching: .any).matching(identifier: "onboarding.selectedSound").firstMatch
        XCTAssertTrue(selectedSound.waitForExistence(timeout: 5))
        XCTAssertEqual(selectedSound.label, "Felt Bloom")
        XCTAssertFalse(app.buttons["Custom Mix"].exists)

        let jazzClub = app.buttons["Jazz Club"]
        XCTAssertTrue(jazzClub.exists)
        jazzClub.tap()
        XCTAssertEqual(selectedSound.label, "Jazz Club")

        let previewButton = app.buttons["Preview Sound"]
        XCTAssertTrue(previewButton.exists)
        previewButton.tap()

        primaryButton.tap()
        XCTAssertTrue(app.staticTexts["Jazz Club"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
