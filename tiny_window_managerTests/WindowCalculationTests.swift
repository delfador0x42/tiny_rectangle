//
//  WindowCalculationTests.swift
//  tiny_window_managerTests
//
//  Characterization tests for WindowCalculation classes.
//
//  PURPOSE:
//  --------
//  These tests document the CURRENT behavior of window calculations.
//  They serve as a safety net during refactoring - if any test fails,
//  it means the behavior changed (which may or may not be intentional).
//
//  These are NOT unit tests that assert "correct" behavior.
//  They capture what the code does TODAY so we can detect changes.
//
//  STRUCTURE:
//  ----------
//  1. Test Helpers - mock screen frames, parameter builders
//  2. Basic Calculations - halves, maximize, center (no cycling)
//  3. Corner Calculations - quarters of the screen
//  4. Grid Calculations - ninths, sixths, eighths
//  5. Orientation-Aware - thirds, fourths (landscape vs portrait)
//  6. Cycling Behavior - repeated execution with Defaults
//

import XCTest
@testable import tiny_window_manager

// MARK: - Test Helpers

/// Standard test screen frames for consistent testing
struct TestScreens {

    /// A typical 1920x1080 landscape display (Full HD)
    /// visibleFrame accounts for menu bar (25px) and dock (70px bottom)
    static let landscape1080p = CGRect(x: 0, y: 70, width: 1920, height: 985)

    /// A 1080x1920 portrait display (rotated Full HD)
    /// Same pixel count, but taller than wide
    static let portrait1080p = CGRect(x: 0, y: 70, width: 1080, height: 1825)

    /// A 2560x1440 landscape display (QHD)
    static let landscape1440p = CGRect(x: 0, y: 25, width: 2560, height: 1415)

    /// A secondary display offset to the right
    static let secondaryDisplay = CGRect(x: 1920, y: 0, width: 1920, height: 1080)

    /// A small test frame for simple math verification
    static let simple = CGRect(x: 0, y: 0, width: 1000, height: 500)

    /// Portrait version of simple frame
    static let simplePortrait = CGRect(x: 0, y: 0, width: 500, height: 1000)
}

/// Helper to create RectCalculationParameters for testing
struct TestParams {

    /// Creates parameters for a first execution (no previous action)
    static func firstExecution(
        screen: CGRect,
        action: WindowAction,
        windowRect: CGRect? = nil
    ) -> RectCalculationParameters {
        let window = Window(
            id: 1,
            rect: windowRect ?? CGRect(x: 100, y: 100, width: 400, height: 300)
        )
        return RectCalculationParameters(
            window: window,
            visibleFrameOfScreen: screen,
            action: action,
            lastAction: nil  // First execution = no last action
        )
    }

    /// Creates parameters for a repeated execution (cycling)
    static func repeatedExecution(
        screen: CGRect,
        action: WindowAction,
        lastAction: WindowAction,
        lastSubAction: SubWindowAction? = nil,
        lastRect: CGRect,
        count: Int = 1
    ) -> RectCalculationParameters {
        let window = Window(id: 1, rect: lastRect)
        let previous = tiny_window_managerAction(
            action: lastAction,
            subAction: lastSubAction,
            rect: lastRect.screenFlipped,  // Actions store screen-flipped coords
            count: count
        )
        return RectCalculationParameters(
            window: window,
            visibleFrameOfScreen: screen,
            action: action,
            lastAction: previous
        )
    }
}

// MARK: - Basic Calculation Tests

class BasicCalculationTests: XCTestCase {

    let screen = TestScreens.simple  // 1000x500 for easy math

    // MARK: - Maximize

    func testMaximize_fillsEntireScreen() {
        let calc = MaximizeCalculation()
        let params = TestParams.firstExecution(screen: screen, action: .maximize)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect, screen, "Maximize should fill the entire visible screen")
    }

    // MARK: - Left Half

    func testLeftHalf_firstExecution_takesLeftHalfOfScreen() {
        let calc = WindowCalculationFactory.leftHalfCalculation
        let params = TestParams.firstExecution(screen: screen, action: .leftHalf)

        let result = calc.calculateRect(params)

        // Left half: x=0, y=0, width=500 (half of 1000), height=500
        XCTAssertEqual(result.rect.origin.x, 0, "Left half should start at left edge")
        XCTAssertEqual(result.rect.origin.y, 0, "Left half should start at bottom")
        XCTAssertEqual(result.rect.width, 500, "Left half width should be half of screen")
        XCTAssertEqual(result.rect.height, 500, "Left half height should be full screen height")
    }

    // MARK: - Right Half

    func testRightHalf_firstExecution_takesRightHalfOfScreen() {
        let calc = WindowCalculationFactory.rightHalfCalculation
        let params = TestParams.firstExecution(screen: screen, action: .rightHalf)

        let result = calc.calculateRect(params)

        // Right half: x=500, y=0, width=500, height=500
        XCTAssertEqual(result.rect.origin.x, 500, "Right half should start at midpoint")
        XCTAssertEqual(result.rect.origin.y, 0, "Right half should start at bottom")
        XCTAssertEqual(result.rect.width, 500, "Right half width should be half of screen")
        XCTAssertEqual(result.rect.height, 500, "Right half height should be full screen height")
    }

    // MARK: - Top Half

    func testTopHalf_firstExecution_takesTopHalfOfScreen() {
        let calc = WindowCalculationFactory.topHalfCalculation
        let params = TestParams.firstExecution(screen: screen, action: .topHalf)

        let result = calc.calculateRect(params)

        // Top half in macOS coords: y starts at midpoint (250), height is half (250)
        // Remember: macOS y=0 is at bottom, so "top" has higher y values
        XCTAssertEqual(result.rect.origin.x, 0, "Top half should span full width")
        XCTAssertEqual(result.rect.width, 1000, "Top half should span full width")
        XCTAssertEqual(result.rect.height, 250, "Top half height should be half of screen")
        // Y position: screen.maxY - height = 500 - 250 = 250
        XCTAssertEqual(result.rect.origin.y, 250, "Top half should be at top of screen (macOS coords)")
    }

    // MARK: - Bottom Half

    func testBottomHalf_firstExecution_takesBottomHalfOfScreen() {
        let calc = WindowCalculationFactory.bottomHalfCalculation
        let params = TestParams.firstExecution(screen: screen, action: .bottomHalf)

        let result = calc.calculateRect(params)

        // Bottom half: starts at y=0 (bottom), height is half
        XCTAssertEqual(result.rect.origin.x, 0, "Bottom half should span full width")
        XCTAssertEqual(result.rect.origin.y, 0, "Bottom half should start at bottom")
        XCTAssertEqual(result.rect.width, 1000, "Bottom half should span full width")
        XCTAssertEqual(result.rect.height, 250, "Bottom half height should be half of screen")
    }

    // MARK: - Center

    func testCenter_keepsWindowSizeAndCenters() {
        let calc = WindowCalculationFactory.centerCalculation
        let windowRect = CGRect(x: 50, y: 50, width: 400, height: 300)
        let params = TestParams.firstExecution(screen: screen, action: .center, windowRect: windowRect)

        let result = calc.calculateRect(params)

        // Window should be centered: (1000-400)/2 = 300 for x, (500-300)/2 = 100 for y
        XCTAssertEqual(result.rect.width, 400, "Center should preserve window width")
        XCTAssertEqual(result.rect.height, 300, "Center should preserve window height")
        XCTAssertEqual(result.rect.midX, 500, accuracy: 1, "Window should be horizontally centered")
        XCTAssertEqual(result.rect.midY, 250, accuracy: 1, "Window should be vertically centered")
    }
}

// MARK: - Corner Calculation Tests

class CornerCalculationTests: XCTestCase {

    let screen = TestScreens.simple  // 1000x500

    // MARK: - Top Left

    func testTopLeft_firstExecution_takesTopLeftQuarter() {
        let calc = WindowCalculationFactory.upperLeftCalculation
        let params = TestParams.firstExecution(screen: screen, action: .topLeft)

        let result = calc.calculateRect(params)

        // Top-left: x=0, width=half(500), height=half(250), y at top
        XCTAssertEqual(result.rect.origin.x, 0, "Top-left should start at left edge")
        XCTAssertEqual(result.rect.width, 500, "Top-left width should be half screen")
        XCTAssertEqual(result.rect.height, 250, "Top-left height should be half screen")
        XCTAssertEqual(result.rect.origin.y, 250, "Top-left y should be at top (macOS coords)")
    }

    // MARK: - Top Right

    func testTopRight_firstExecution_takesTopRightQuarter() {
        let calc = WindowCalculationFactory.upperRightCalculation
        let params = TestParams.firstExecution(screen: screen, action: .topRight)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 500, "Top-right should start at midpoint")
        XCTAssertEqual(result.rect.width, 500, "Top-right width should be half screen")
        XCTAssertEqual(result.rect.height, 250, "Top-right height should be half screen")
        XCTAssertEqual(result.rect.origin.y, 250, "Top-right y should be at top")
    }

    // MARK: - Bottom Left

    func testBottomLeft_firstExecution_takesBottomLeftQuarter() {
        let calc = WindowCalculationFactory.lowerLeftCalculation
        let params = TestParams.firstExecution(screen: screen, action: .bottomLeft)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 0, "Bottom-left should start at left edge")
        XCTAssertEqual(result.rect.origin.y, 0, "Bottom-left should start at bottom")
        XCTAssertEqual(result.rect.width, 500, "Bottom-left width should be half screen")
        XCTAssertEqual(result.rect.height, 250, "Bottom-left height should be half screen")
    }

    // MARK: - Bottom Right

    func testBottomRight_firstExecution_takesBottomRightQuarter() {
        let calc = WindowCalculationFactory.lowerRightCalculation
        let params = TestParams.firstExecution(screen: screen, action: .bottomRight)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 500, "Bottom-right should start at midpoint")
        XCTAssertEqual(result.rect.origin.y, 0, "Bottom-right should start at bottom")
        XCTAssertEqual(result.rect.width, 500, "Bottom-right width should be half screen")
        XCTAssertEqual(result.rect.height, 250, "Bottom-right height should be half screen")
    }
}

// MARK: - Grid Calculation Tests

class GridCalculationTests: XCTestCase {

    // Using a 900x600 screen for easy 3x3 grid math (each cell is 300x200)
    let screen = CGRect(x: 0, y: 0, width: 900, height: 600)

    // MARK: - Ninths (3x3 grid)

    func testTopLeftNinth_calculatesCorrectCell() {
        let calc = WindowCalculationFactory.topLeftNinthCalculation
        let params = TestParams.firstExecution(screen: screen, action: .topLeftNinth)

        let result = calc.calculateRect(params)

        // Top-left ninth: column 0, row 0
        // x = 0, width = 300
        // y = 600 - 200 = 400 (top row in macOS coords), height = 200
        XCTAssertEqual(result.rect.origin.x, 0)
        XCTAssertEqual(result.rect.origin.y, 400)
        XCTAssertEqual(result.rect.width, 300)
        XCTAssertEqual(result.rect.height, 200)
    }

    func testMiddleCenterNinth_calculatesCorrectCell() {
        let calc = WindowCalculationFactory.middleCenterNinthCalculation
        let params = TestParams.firstExecution(screen: screen, action: .middleCenterNinth)

        let result = calc.calculateRect(params)

        // Middle-center ninth: column 1, row 1
        // x = 300, width = 300
        // y = 600 - 400 = 200 (middle row), height = 200
        XCTAssertEqual(result.rect.origin.x, 300)
        XCTAssertEqual(result.rect.origin.y, 200)
        XCTAssertEqual(result.rect.width, 300)
        XCTAssertEqual(result.rect.height, 200)
    }

    func testBottomRightNinth_calculatesCorrectCell() {
        let calc = WindowCalculationFactory.bottomRightNinthCalculation
        let params = TestParams.firstExecution(screen: screen, action: .bottomRightNinth)

        let result = calc.calculateRect(params)

        // Bottom-right ninth: column 2, row 2
        // x = 600, width = 300
        // y = 0 (bottom row), height = 200
        XCTAssertEqual(result.rect.origin.x, 600)
        XCTAssertEqual(result.rect.origin.y, 0)
        XCTAssertEqual(result.rect.width, 300)
        XCTAssertEqual(result.rect.height, 200)
    }
}

// MARK: - Orientation-Aware Tests (Thirds, Fourths)

class OrientationAwareTests: XCTestCase {

    // MARK: - Thirds in Landscape

    func testFirstThird_landscape_takesLeftThird() {
        let screen = TestScreens.simple  // 1000x500 (landscape)
        let calc = WindowCalculationFactory.firstThirdCalculation
        let params = TestParams.firstExecution(screen: screen, action: .firstThird)

        let result = calc.calculateRect(params)

        // In landscape, first third is LEFT third (vertical strip)
        XCTAssertEqual(result.rect.origin.x, 0, "First third should start at left edge")
        XCTAssertEqual(result.rect.width, 333, accuracy: 1, "First third should be ~1/3 width")
        XCTAssertEqual(result.rect.height, 500, "First third should be full height")
        XCTAssertEqual(result.subAction, .leftThird, "SubAction should be leftThird in landscape")
    }

    func testCenterThird_landscape_takesCenterThird() {
        let screen = TestScreens.simple
        let calc = WindowCalculationFactory.centerThirdCalculation
        let params = TestParams.firstExecution(screen: screen, action: .centerThird)

        let result = calc.calculateRect(params)

        // Center third in landscape
        XCTAssertEqual(result.rect.origin.x, 333, accuracy: 1, "Center third should start at 1/3")
        XCTAssertEqual(result.rect.width, 333, accuracy: 1, "Center third should be ~1/3 width")
        XCTAssertEqual(result.rect.height, 500, "Center third should be full height")
    }

    func testLastThird_landscape_takesRightThird() {
        let screen = TestScreens.simple
        let calc = WindowCalculationFactory.lastThirdCalculation
        let params = TestParams.firstExecution(screen: screen, action: .lastThird)

        let result = calc.calculateRect(params)

        // Last third in landscape is RIGHT third
        XCTAssertEqual(result.rect.origin.x, 666, accuracy: 1, "Last third should start at 2/3")
        XCTAssertEqual(result.rect.width, 333, accuracy: 1, "Last third should be ~1/3 width")
        XCTAssertEqual(result.rect.height, 500, "Last third should be full height")
        XCTAssertEqual(result.subAction, .rightThird, "SubAction should be rightThird in landscape")
    }

    // MARK: - Thirds in Portrait

    func testFirstThird_portrait_takesTopThird() {
        let screen = TestScreens.simplePortrait  // 500x1000 (portrait)
        let calc = WindowCalculationFactory.firstThirdCalculation
        let params = TestParams.firstExecution(screen: screen, action: .firstThird)

        let result = calc.calculateRect(params)

        // In portrait, first third is TOP third (horizontal strip)
        XCTAssertEqual(result.rect.width, 500, "First third should be full width in portrait")
        XCTAssertEqual(result.rect.height, 333, accuracy: 1, "First third should be ~1/3 height")
        // Top third y = 1000 - 333 = 667
        XCTAssertEqual(result.rect.origin.y, 666, accuracy: 1, "First third should be at top")
        XCTAssertEqual(result.subAction, .topThird, "SubAction should be topThird in portrait")
    }

    func testLastThird_portrait_takesBottomThird() {
        let screen = TestScreens.simplePortrait
        let calc = WindowCalculationFactory.lastThirdCalculation
        let params = TestParams.firstExecution(screen: screen, action: .lastThird)

        let result = calc.calculateRect(params)

        // Last third in portrait is BOTTOM third
        XCTAssertEqual(result.rect.width, 500, "Last third should be full width in portrait")
        XCTAssertEqual(result.rect.height, 333, accuracy: 1, "Last third should be ~1/3 height")
        XCTAssertEqual(result.rect.origin.y, 0, "Last third should be at bottom")
        XCTAssertEqual(result.subAction, .bottomThird, "SubAction should be bottomThird in portrait")
    }

    // MARK: - Fourths in Landscape

    func testFirstFourth_landscape_takesLeftFourth() {
        let screen = TestScreens.simple  // 1000x500
        let calc = WindowCalculationFactory.firstFourthCalculation
        let params = TestParams.firstExecution(screen: screen, action: .firstFourth)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 0)
        XCTAssertEqual(result.rect.width, 250, "First fourth should be 1/4 width")
        XCTAssertEqual(result.rect.height, 500, "First fourth should be full height")
    }

    func testLastFourth_landscape_takesRightFourth() {
        let screen = TestScreens.simple
        let calc = WindowCalculationFactory.lastFourthCalculation
        let params = TestParams.firstExecution(screen: screen, action: .lastFourth)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 750, "Last fourth should start at 3/4")
        XCTAssertEqual(result.rect.width, 250, "Last fourth should be 1/4 width")
        XCTAssertEqual(result.rect.height, 500)
    }
}

// MARK: - Sixths Tests

class SixthsTests: XCTestCase {

    // 900x600 screen: landscape 3 cols x 2 rows, each cell 300x300
    let landscapeScreen = CGRect(x: 0, y: 0, width: 900, height: 600)

    // 600x900 screen: portrait 2 cols x 3 rows, each cell 300x300
    let portraitScreen = CGRect(x: 0, y: 0, width: 600, height: 900)

    // MARK: - Landscape Sixths

    func testTopLeftSixth_landscape() {
        let calc = WindowCalculationFactory.topLeftSixthCalculation
        let params = TestParams.firstExecution(screen: landscapeScreen, action: .topLeftSixth)

        let result = calc.calculateRect(params)

        // Top-left sixth in landscape: column 0 of 3, row 0 of 2
        // x = 0, width = 300
        // y = 600 - 300 = 300 (top row), height = 300
        XCTAssertEqual(result.rect.origin.x, 0)
        XCTAssertEqual(result.rect.origin.y, 300)
        XCTAssertEqual(result.rect.width, 300)
        XCTAssertEqual(result.rect.height, 300)
    }

    func testBottomRightSixth_landscape() {
        let calc = WindowCalculationFactory.bottomRightSixthCalculation
        let params = TestParams.firstExecution(screen: landscapeScreen, action: .bottomRightSixth)

        let result = calc.calculateRect(params)

        // Bottom-right sixth in landscape: column 2 of 3, row 1 of 2
        XCTAssertEqual(result.rect.origin.x, 600)
        XCTAssertEqual(result.rect.origin.y, 0)
        XCTAssertEqual(result.rect.width, 300)
        XCTAssertEqual(result.rect.height, 300)
    }

    // MARK: - Portrait Sixths

    func testTopLeftSixth_portrait() {
        let calc = WindowCalculationFactory.topLeftSixthCalculation
        let params = TestParams.firstExecution(screen: portraitScreen, action: .topLeftSixth)

        let result = calc.calculateRect(params)

        // Top-left sixth in portrait: column 0 of 2, row 0 of 3
        // x = 0, width = 300
        // y = 900 - 300 = 600 (top row), height = 300
        XCTAssertEqual(result.rect.origin.x, 0)
        XCTAssertEqual(result.rect.origin.y, 600)
        XCTAssertEqual(result.rect.width, 300)
        XCTAssertEqual(result.rect.height, 300)
    }
}

// MARK: - Two-Thirds Tests

class TwoThirdsTests: XCTestCase {

    let screen = TestScreens.simple  // 1000x500

    func testFirstTwoThirds_landscape_takesLeftTwoThirds() {
        let calc = WindowCalculationFactory.firstTwoThirdsCalculation
        let params = TestParams.firstExecution(screen: screen, action: .firstTwoThirds)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 0)
        XCTAssertEqual(result.rect.width, 666, accuracy: 1, "First two-thirds should be ~2/3 width")
        XCTAssertEqual(result.rect.height, 500)
    }

    func testLastTwoThirds_landscape_takesRightTwoThirds() {
        let calc = WindowCalculationFactory.lastTwoThirdsCalculation
        let params = TestParams.firstExecution(screen: screen, action: .lastTwoThirds)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 333, accuracy: 1, "Last two-thirds should start at 1/3")
        XCTAssertEqual(result.rect.width, 666, accuracy: 1)
        XCTAssertEqual(result.rect.height, 500)
    }
}

// MARK: - Cycling Behavior Tests

class CyclingBehaviorTests: XCTestCase {

    // Store original Defaults values to restore after tests
    private var originalSubsequentMode: SubsequentExecutionMode!
    private var originalCycleSizes: Set<CycleSize>!

    override func setUp() {
        super.setUp()
        // Save original values
        originalSubsequentMode = Defaults.subsequentExecutionMode.value
        originalCycleSizes = Defaults.selectedCycleSizes.value

        // Set up for cycling tests
        Defaults.subsequentExecutionMode.value = .resize
        Defaults.selectedCycleSizes.value = [.oneHalf, .twoThirds, .oneThird]
    }

    override func tearDown() {
        // Restore original values
        Defaults.subsequentExecutionMode.value = originalSubsequentMode
        Defaults.selectedCycleSizes.value = originalCycleSizes
        super.tearDown()
    }

    let screen = TestScreens.simple  // 1000x500

    // MARK: - Corner Cycling (Width)

    func testTopLeft_cycling_changesWidth() {
        let calc = WindowCalculationFactory.upperLeftCalculation

        // First execution: half width (500)
        let firstParams = TestParams.firstExecution(screen: screen, action: .topLeft)
        let firstResult = calc.calculateRect(firstParams)
        XCTAssertEqual(firstResult.rect.width, 500, "First execution should be half width")

        // Second execution: should cycle to next size
        // The window is now at the first result's position
        let secondParams = TestParams.repeatedExecution(
            screen: screen,
            action: .topLeft,
            lastAction: .topLeft,
            lastRect: firstResult.rect,
            count: 1
        )
        let secondResult = calc.calculateRect(secondParams)

        // With default cycle [1/2, 2/3, 1/3], second should be 2/3
        // 2/3 of 1000 = 666
        XCTAssertEqual(secondResult.rect.width, 666, accuracy: 1, "Second execution should cycle to 2/3 width")
        XCTAssertEqual(secondResult.rect.height, 250, "Height should stay at half")
    }

    // MARK: - Cycling Disabled

    func testTopLeft_cyclingDisabled_staysAtHalf() {
        // Disable cycling
        Defaults.subsequentExecutionMode.value = .none

        let calc = WindowCalculationFactory.upperLeftCalculation

        // First execution
        let firstParams = TestParams.firstExecution(screen: screen, action: .topLeft)
        let firstResult = calc.calculateRect(firstParams)

        // Second execution with cycling disabled
        let secondParams = TestParams.repeatedExecution(
            screen: screen,
            action: .topLeft,
            lastAction: .topLeft,
            lastRect: firstResult.rect,
            count: 1
        )
        let secondResult = calc.calculateRect(secondParams)

        // Should stay at half width since cycling is disabled
        XCTAssertEqual(secondResult.rect.width, 500, "With cycling disabled, width should stay at half")
    }
}

// MARK: - Realistic Screen Tests

class RealisticScreenTests: XCTestCase {

    /// Tests with a real 1920x1080 display configuration
    func testLeftHalf_on1080pDisplay() {
        let screen = TestScreens.landscape1080p  // 1920x985 (minus menu bar/dock)
        let calc = WindowCalculationFactory.leftHalfCalculation
        let params = TestParams.firstExecution(screen: screen, action: .leftHalf)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 0)
        XCTAssertEqual(result.rect.origin.y, 70)  // Accounts for dock
        XCTAssertEqual(result.rect.width, 960)    // Half of 1920
        XCTAssertEqual(result.rect.height, 985)   // Full usable height
    }

    func testMaximize_on1440pDisplay() {
        let screen = TestScreens.landscape1440p  // 2560x1415
        let calc = MaximizeCalculation()
        let params = TestParams.firstExecution(screen: screen, action: .maximize)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect, screen, "Maximize should exactly fill the visible frame")
    }
}

// MARK: - Edge Case Tests

class EdgeCaseTests: XCTestCase {

    /// Test calculation with a very small screen
    func testLeftHalf_verySmallScreen() {
        let tinyScreen = CGRect(x: 0, y: 0, width: 100, height: 50)
        let calc = WindowCalculationFactory.leftHalfCalculation
        let params = TestParams.firstExecution(screen: tinyScreen, action: .leftHalf)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.width, 50, "Should still calculate half width")
        XCTAssertEqual(result.rect.height, 50, "Should use full height")
    }

    /// Test calculation with non-zero origin (secondary display)
    func testLeftHalf_secondaryDisplay() {
        let screen = TestScreens.secondaryDisplay  // x=1920
        let calc = WindowCalculationFactory.leftHalfCalculation
        let params = TestParams.firstExecution(screen: screen, action: .leftHalf)

        let result = calc.calculateRect(params)

        XCTAssertEqual(result.rect.origin.x, 1920, "Should start at display's x origin")
        XCTAssertEqual(result.rect.width, 960, "Should be half of display width")
    }

    /// Test that floor() is used (no fractional pixels)
    func testNinths_usesFloorForPixels() {
        // 1000/3 = 333.333... should floor to 333
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let calc = WindowCalculationFactory.topLeftNinthCalculation
        let params = TestParams.firstExecution(screen: screen, action: .topLeftNinth)

        let result = calc.calculateRect(params)

        // Verify no fractional pixels
        XCTAssertEqual(result.rect.width, floor(1000.0 / 3.0))
        XCTAssertEqual(result.rect.height, floor(600.0 / 3.0))
        XCTAssertEqual(result.rect.width.truncatingRemainder(dividingBy: 1), 0, "Width should be whole number")
    }
}
