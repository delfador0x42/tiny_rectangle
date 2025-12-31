//
//  WindowCalculationKitTests.swift
//  WindowCalculationKit
//
//  Basic tests for the WindowCalculationKit package.
//

import Testing
import Foundation
@testable import WindowCalculationKit

@Suite("Types")
struct TypesTests {

    @Test("CycleSize fractions are correct")
    func cycleSizeFractions() {
        #expect(CycleSize.oneHalf.fraction == 0.5)
        #expect(CycleSize.oneThird.fraction == Float(1.0/3.0))
        #expect(CycleSize.twoThirds.fraction == Float(2.0/3.0))
        #expect(CycleSize.oneQuarter.fraction == 0.25)
        #expect(CycleSize.threeQuarters.fraction == 0.75)
    }

    @Test("CycleSize bitwise conversion roundtrips")
    func cycleSizeBitwise() {
        let original: Set<CycleSize> = [.oneHalf, .twoThirds, .oneThird]
        let bits = original.toBits()
        let restored = CycleSize.fromBits(bits)
        #expect(original == restored)
    }

    @Test("CycleSize sorted order starts with oneHalf")
    func cycleSizeSortedOrder() {
        let sorted = CycleSize.sortedForCycle
        #expect(sorted.first == .oneHalf)
    }

    @Test("GridType dimensions are correct")
    func gridTypeDimensions() {
        // Ninths: always 3x3
        #expect(GridType.ninths.columns(isLandscape: true) == 3)
        #expect(GridType.ninths.rows(isLandscape: true) == 3)
        #expect(GridType.ninths.columns(isLandscape: false) == 3)
        #expect(GridType.ninths.rows(isLandscape: false) == 3)

        // Eighths: 4x2 landscape, 2x4 portrait
        #expect(GridType.eighths.columns(isLandscape: true) == 4)
        #expect(GridType.eighths.rows(isLandscape: true) == 2)
        #expect(GridType.eighths.columns(isLandscape: false) == 2)
        #expect(GridType.eighths.rows(isLandscape: false) == 4)

        // Sixths: 3x2 landscape, 2x3 portrait
        #expect(GridType.sixths.columns(isLandscape: true) == 3)
        #expect(GridType.sixths.rows(isLandscape: true) == 2)
        #expect(GridType.sixths.columns(isLandscape: false) == 2)
        #expect(GridType.sixths.rows(isLandscape: false) == 3)
    }
}

@Suite("Core Data Structures")
struct CoreTests {

    @Test("RectResult initialization")
    func rectResultInit() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let result = RectResult(rect, subAction: .leftThird)

        #expect(result.rect == rect)
        #expect(result.subAction == .leftThird)
    }

    @Test("CalculationParams landscape detection")
    func calculationParamsLandscape() {
        let landscapeFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let portraitFrame = CGRect(x: 0, y: 0, width: 1080, height: 1920)

        let landscapeParams = CalculationParams(
            window: WindowInfo(id: 1, rect: .zero),
            visibleFrame: landscapeFrame,
            action: .leftHalf
        )

        let portraitParams = CalculationParams(
            window: WindowInfo(id: 1, rect: .zero),
            visibleFrame: portraitFrame,
            action: .leftHalf
        )

        #expect(landscapeParams.isLandscape == true)
        #expect(portraitParams.isLandscape == false)
    }

    @Test("Edge OptionSet operations")
    func edgeOptionSet() {
        let horizontal = Edge.horizontal
        #expect(horizontal.contains(.left))
        #expect(horizontal.contains(.right))
        #expect(!horizontal.contains(.top))
        #expect(!horizontal.contains(.bottom))

        let all = Edge.all
        #expect(all.contains(.left))
        #expect(all.contains(.right))
        #expect(all.contains(.top))
        #expect(all.contains(.bottom))
    }
}

@Suite("ActionIdentifier")
struct ActionIdentifierTests {

    @Test("ActionIdentifier is Codable")
    func actionIdentifierCodable() throws {
        let action = ActionIdentifier.leftHalf
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(ActionIdentifier.self, from: data)
        #expect(decoded == action)
    }

    @Test("ActionIdentifier covers all window positions")
    func actionIdentifierCoverage() {
        // Just verify we have all the major categories
        let allCases = ActionIdentifier.allCases

        // Halves
        #expect(allCases.contains(.leftHalf))
        #expect(allCases.contains(.rightHalf))
        #expect(allCases.contains(.topHalf))
        #expect(allCases.contains(.bottomHalf))

        // Corners
        #expect(allCases.contains(.topLeft))
        #expect(allCases.contains(.topRight))
        #expect(allCases.contains(.bottomLeft))
        #expect(allCases.contains(.bottomRight))

        // Thirds
        #expect(allCases.contains(.firstThird))
        #expect(allCases.contains(.centerThird))
        #expect(allCases.contains(.lastThird))
    }
}

// MARK: - GridCalculation Tests

@Suite("GridCalculation")
struct GridCalculationTests {

    // Use a 900x600 screen for easy math (ninths = 300x200 cells)
    let landscapeScreen = CGRect(x: 0, y: 0, width: 900, height: 600)

    // Use a 600x900 screen for portrait
    let portraitScreen = CGRect(x: 0, y: 0, width: 600, height: 900)

    func makeParams(screen: CGRect, action: ActionIdentifier = .topLeftNinth) -> CalculationParams {
        CalculationParams(
            window: WindowInfo(id: 1, rect: .zero),
            visibleFrame: screen,
            action: action
        )
    }

    // MARK: - Ninths Tests

    @Test("Top-left ninth calculates correct position")
    func topLeftNinth() {
        let calc = GridCalculation.topLeftNinth
        let params = makeParams(screen: landscapeScreen)
        let result = calc.calculateRect(params)

        // Top-left: x=0, y=600-200=400, width=300, height=200
        #expect(result.rect.origin.x == 0)
        #expect(result.rect.origin.y == 400)
        #expect(result.rect.width == 300)
        #expect(result.rect.height == 200)
        #expect(result.subAction == .topLeftNinth)
    }

    @Test("Middle-center ninth calculates correct position")
    func middleCenterNinth() {
        let calc = GridCalculation.middleCenterNinth
        let params = makeParams(screen: landscapeScreen)
        let result = calc.calculateRect(params)

        // Middle-center: column=1, row=1
        // x=300, y=600-400=200, width=300, height=200
        #expect(result.rect.origin.x == 300)
        #expect(result.rect.origin.y == 200)
        #expect(result.rect.width == 300)
        #expect(result.rect.height == 200)
        #expect(result.subAction == .middleCenterNinth)
    }

    @Test("Bottom-right ninth calculates correct position")
    func bottomRightNinth() {
        let calc = GridCalculation.bottomRightNinth
        let params = makeParams(screen: landscapeScreen)
        let result = calc.calculateRect(params)

        // Bottom-right: column=2, row=2
        // x=600, y=0, width=300, height=200
        #expect(result.rect.origin.x == 600)
        #expect(result.rect.origin.y == 0)
        #expect(result.rect.width == 300)
        #expect(result.rect.height == 200)
        #expect(result.subAction == .bottomRightNinth)
    }

    // MARK: - Eighths Tests (Orientation-Aware)

    @Test("Top-left eighth in landscape")
    func topLeftEighthLandscape() {
        // In landscape: 4 columns × 2 rows
        // Cell size: 900/4=225 wide, 600/2=300 tall
        let calc = GridCalculation.topLeftEighth
        let params = makeParams(screen: landscapeScreen)
        let result = calc.calculateRect(params)

        #expect(result.rect.origin.x == 0)
        #expect(result.rect.origin.y == 300)  // Top row in macOS coords
        #expect(result.rect.width == 225)
        #expect(result.rect.height == 300)
    }

    @Test("Top-left eighth in portrait")
    func topLeftEighthPortrait() {
        // In portrait: 2 columns × 4 rows
        // Cell size: 600/2=300 wide, 900/4=225 tall
        let calc = GridCalculation.topLeftEighth
        let params = makeParams(screen: portraitScreen)
        let result = calc.calculateRect(params)

        #expect(result.rect.origin.x == 0)
        #expect(result.rect.origin.y == 675)  // Top row: 900-225=675
        #expect(result.rect.width == 300)
        #expect(result.rect.height == 225)
    }

    @Test("Bottom-right eighth in landscape")
    func bottomRightEighthLandscape() {
        // Landscape: column=3, row=1
        let calc = GridCalculation.bottomRightEighth
        let params = makeParams(screen: landscapeScreen)
        let result = calc.calculateRect(params)

        #expect(result.rect.origin.x == 675)  // 3 * 225
        #expect(result.rect.origin.y == 0)    // Bottom row
        #expect(result.rect.width == 225)
        #expect(result.rect.height == 300)
    }

    // MARK: - Corner Thirds Tests

    @Test("Top-left corner third in landscape")
    func topLeftThirdLandscape() {
        // Landscape: width=2/3, height=1/2
        // Cell size: 900*2/3=600, 600*0.5=300
        let calc = GridCalculation.topLeftThird
        let params = makeParams(screen: landscapeScreen)
        let result = calc.calculateRect(params)

        #expect(result.rect.origin.x == 0)
        #expect(result.rect.origin.y == 300)  // Top row
        #expect(result.rect.width == 600)
        #expect(result.rect.height == 300)
        #expect(result.subAction == .topLeftThird)
    }

    @Test("Bottom-right corner third in landscape")
    func bottomRightThirdLandscape() {
        // Column=1, row=1
        let calc = GridCalculation.bottomRightThird
        let params = makeParams(screen: landscapeScreen)
        let result = calc.calculateRect(params)

        #expect(result.rect.origin.x == 600)  // 1 * 600
        #expect(result.rect.origin.y == 0)    // Bottom row
        #expect(result.rect.width == 600)
        #expect(result.rect.height == 300)
    }

    @Test("Top-left corner third in portrait")
    func topLeftThirdPortrait() {
        // Portrait: width=1/2, height=2/3
        // Cell size: 600*0.5=300, 900*2/3=600
        let calc = GridCalculation.topLeftThird
        let params = makeParams(screen: portraitScreen)
        let result = calc.calculateRect(params)

        #expect(result.rect.origin.x == 0)
        #expect(result.rect.origin.y == 300)  // 900 - 600 = 300
        #expect(result.rect.width == 300)
        #expect(result.rect.height == 600)
    }

    // MARK: - Screen with Offset Origin

    @Test("Grid calculation respects screen origin offset")
    func screenWithOffset() {
        // Simulate a secondary display at x=900
        let offsetScreen = CGRect(x: 900, y: 100, width: 900, height: 600)
        let calc = GridCalculation.topLeftNinth
        let params = makeParams(screen: offsetScreen)
        let result = calc.calculateRect(params)

        // Should start at screen's minX, not 0
        #expect(result.rect.origin.x == 900)
        #expect(result.rect.origin.y == 500)  // 100 + 600 - 200 = 500
    }

    // MARK: - Custom Grid Calculation

    @Test("Custom grid calculation with different landscape/portrait positions")
    func customGridPositions() {
        // Create a calculation that's in different positions for landscape vs portrait
        let calc = GridCalculation(
            gridType: .ninths,
            landscapeColumn: 0, landscapeRow: 0,  // Top-left in landscape
            portraitColumn: 2, portraitRow: 2,    // Bottom-right in portrait
            subAction: .topLeftNinth
        )

        let landscapeParams = makeParams(screen: landscapeScreen)
        let landscapeResult = calc.calculateRect(landscapeParams)

        let portraitParams = makeParams(screen: portraitScreen)
        let portraitResult = calc.calculateRect(portraitParams)

        // In landscape: top-left
        #expect(landscapeResult.rect.origin.x == 0)
        #expect(landscapeResult.rect.origin.y == 400)

        // In portrait: bottom-right (different position)
        #expect(portraitResult.rect.origin.x == 400)  // 600/3 * 2 = 400
        #expect(portraitResult.rect.origin.y == 0)
    }
}

// MARK: - GridType Cell Sizing Tests

@Suite("GridType Cell Sizing")
struct GridTypeCellSizingTests {

    @Test("Ninths cell sizing")
    func ninthsCellSizing() {
        let width = GridType.ninths.cellWidth(screenWidth: 900, isLandscape: true)
        let height = GridType.ninths.cellHeight(screenHeight: 600, isLandscape: true)

        #expect(width == 300)
        #expect(height == 200)
    }

    @Test("Eighths cell sizing in landscape")
    func eighthsCellSizingLandscape() {
        let width = GridType.eighths.cellWidth(screenWidth: 900, isLandscape: true)
        let height = GridType.eighths.cellHeight(screenHeight: 600, isLandscape: true)

        #expect(width == 225)  // 900 / 4
        #expect(height == 300) // 600 / 2
    }

    @Test("Eighths cell sizing in portrait")
    func eighthsCellSizingPortrait() {
        let width = GridType.eighths.cellWidth(screenWidth: 600, isLandscape: false)
        let height = GridType.eighths.cellHeight(screenHeight: 900, isLandscape: false)

        #expect(width == 300)  // 600 / 2
        #expect(height == 225) // 900 / 4
    }

    @Test("Corner thirds cell sizing in landscape")
    func cornerThirdsCellSizingLandscape() {
        let width = GridType.cornerThirds.cellWidth(screenWidth: 900, isLandscape: true)
        let height = GridType.cornerThirds.cellHeight(screenHeight: 600, isLandscape: true)

        #expect(width == 600)  // 900 * 2/3
        #expect(height == 300) // 600 * 1/2
    }

    @Test("Corner thirds cell sizing in portrait")
    func cornerThirdsCellSizingPortrait() {
        let width = GridType.cornerThirds.cellWidth(screenWidth: 600, isLandscape: false)
        let height = GridType.cornerThirds.cellHeight(screenHeight: 900, isLandscape: false)

        #expect(width == 300)  // 600 * 1/2
        #expect(height == 600) // 900 * 2/3
    }

    @Test("Cell sizing uses floor to avoid fractional pixels")
    func cellSizingUsesFloor() {
        // 1000 / 3 = 333.333... should floor to 333
        let width = GridType.ninths.cellWidth(screenWidth: 1000, isLandscape: true)
        #expect(width == 333)

        // Verify no fractional part
        #expect(width.truncatingRemainder(dividingBy: 1) == 0)
    }
}
