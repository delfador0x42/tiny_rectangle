//  RectCalculatorTests.swift - Tests for RectCalculator

import XCTest
@testable import WindowManagerCore

final class RectCalculatorTests: XCTestCase {

    let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    // MARK: - Halves Tests

    func testLeftHalf() {
        let rect = RectCalculator.calculateRect(for: .leftHalf, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 960, height: 1080))
    }

    func testRightHalf() {
        let rect = RectCalculator.calculateRect(for: .rightHalf, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 960, y: 0, width: 960, height: 1080))
    }

    func testTopHalf() {
        let rect = RectCalculator.calculateRect(for: .topHalf, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 0, y: 540, width: 1920, height: 540))
    }

    func testBottomHalf() {
        let rect = RectCalculator.calculateRect(for: .bottomHalf, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 1920, height: 540))
    }

    // MARK: - Corners Tests

    func testTopLeft() {
        let rect = RectCalculator.calculateRect(for: .topLeft, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 0, y: 540, width: 960, height: 540))
    }

    func testBottomRight() {
        let rect = RectCalculator.calculateRect(for: .bottomRight, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 960, y: 0, width: 960, height: 540))
    }

    // MARK: - Thirds Tests

    func testFirstThird() {
        let rect = RectCalculator.calculateRect(for: .firstThird, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 0, y: 0, width: 640, height: 1080))
    }

    func testCenterThird() {
        let rect = RectCalculator.calculateRect(for: .centerThird, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 640, y: 0, width: 640, height: 1080))
    }

    func testLastThird() {
        let rect = RectCalculator.calculateRect(for: .lastThird, in: screenFrame)
        XCTAssertEqual(rect, CGRect(x: 1280, y: 0, width: 640, height: 1080))
    }

    // MARK: - Maximize Tests

    func testMaximize() {
        let rect = RectCalculator.calculateRect(for: .maximize, in: screenFrame)
        XCTAssertEqual(rect, screenFrame)
    }

    // MARK: - Center Tests

    func testCenter() {
        let window = CGRect(x: 100, y: 100, width: 800, height: 600)
        let rect = RectCalculator.calculateRect(for: .center, in: screenFrame, window: window)
        XCTAssertEqual(rect, CGRect(x: 560, y: 240, width: 800, height: 600))
    }

    func testCenterRequiresWindow() {
        let rect = RectCalculator.calculateRect(for: .center, in: screenFrame, window: nil)
        XCTAssertNil(rect)
    }

    // MARK: - Grid Tests

    func testNinths() {
        // Test all 9 positions
        let topLeft = RectCalculator.calculateRect(for: .topLeftNinth, in: screenFrame)
        XCTAssertEqual(topLeft?.width, 640)
        XCTAssertEqual(topLeft?.height, 360)

        let middleCenter = RectCalculator.calculateRect(for: .middleCenterNinth, in: screenFrame)
        XCTAssertNotNil(middleCenter)
    }
}
