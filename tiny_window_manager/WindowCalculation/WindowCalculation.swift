//
//  WindowCalculation.swift
//  tiny_window_manager
//
//  Consolidated window calculation system.
//  Contains all calculation logic for positioning windows.
//

import Cocoa
import WindowManagerCore

// Disambiguate from Foundation.Dimension (used for units of measurement)
typealias Dimension = WindowManagerCore.Dimension

// ============================================================================
// MARK: - Protocol
// ============================================================================

/// A type that can calculate window rectangles for positioning.
protocol Calculation {
    func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult?
    func calculateRect(_ params: RectCalculationParameters) -> RectResult
}

// ============================================================================
// MARK: - Base Class
// ============================================================================

/// The base class for all window position calculations.
class WindowCalculation: Calculation {

    func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
                let rectResult = calculateRect(params.asRectParams())
        if rectResult.rect.isNull { return nil }

        return WindowCalculationResult(
            rect: rectResult.rect,
            screen: params.usableScreens.currentScreen,
            resultingAction: params.action,
            resultingSubAction: rectResult.subAction
        )
    }

    func calculateRect(_ params: RectCalculationParameters) -> RectResult {
                return RectResult(.null)
    }

    // MARK: - Helper Methods

    func rectCenteredWithinRect(_ rect1: CGRect, _ rect2: CGRect) -> Bool {
                let centeredMidX = abs(rect2.midX - rect1.midX) <= 1.0
        let centeredMidY = abs(rect2.midY - rect1.midY) <= 1.0
        return rect1.contains(rect2) && centeredMidX && centeredMidY
    }

    func rectFitsWithinRect(rect1: CGRect, rect2: CGRect) -> Bool {
                return rect1.width <= rect2.width && rect1.height <= rect2.height
    }

    func isRepeatedCommand(_ params: WindowCalculationParameters) -> Bool {
                guard let lastAction = params.lastAction, lastAction.action == params.action else {
            return false
        }
        return lastAction.rect.screenFlipped == params.window.rect
    }
}

// ============================================================================
// MARK: - Data Structures
// ============================================================================

struct Window {
    let id: CGWindowID
    let rect: CGRect
}

struct WindowCalculationParameters {
    let window: Window
    let usableScreens: UsableScreens
    let action: WindowAction
    let lastAction: WindowActionRecord?
    let ignoreTodo: Bool

    func asRectParams(visibleFrame: CGRect? = nil, differentAction: WindowAction? = nil) -> RectCalculationParameters {
                return RectCalculationParameters(
            window: window,
            visibleFrameOfScreen: visibleFrame ?? usableScreens.currentScreen.adjustedVisibleFrame(ignoreTodo),
            action: differentAction ?? action,
            lastAction: lastAction
        )
    }

    func withDifferentAction(_ differentAction: WindowAction) -> WindowCalculationParameters {
                return .init(window: window, usableScreens: usableScreens, action: differentAction, lastAction: lastAction, ignoreTodo: ignoreTodo)
    }
}

struct RectCalculationParameters {
    let window: Window
    let visibleFrameOfScreen: CGRect
    let action: WindowAction
    let lastAction: WindowActionRecord?
}

struct RectResult {
    let rect: CGRect
    let resultingAction: WindowAction?
    let subAction: SubWindowAction?

    init(_ rect: CGRect, resultingAction: WindowAction? = nil, subAction: SubWindowAction? = nil) {
                self.rect = rect
        self.resultingAction = resultingAction
        self.subAction = subAction
    }
}

struct WindowCalculationResult {
    var rect: CGRect
    let screen: NSScreen
    let resultingAction: WindowAction
    let resultingSubAction: SubWindowAction?
    let resultingScreenFrame: CGRect?

    init(rect: CGRect, screen: NSScreen, resultingAction: WindowAction,
         resultingSubAction: SubWindowAction? = nil, resultingScreenFrame: CGRect? = nil) {
                self.rect = rect
        self.screen = screen
        self.resultingAction = resultingAction
        self.resultingSubAction = resultingSubAction
        self.resultingScreenFrame = resultingScreenFrame
    }
}

// ============================================================================
// MARK: - WindowAction Rect Calculation
// ============================================================================

extension WindowAction {

    /// Calculate the window rect for this action.
    func calculateRect(in screen: CGRect, window: CGRect? = nil) -> CGRect? {
        let w = screen.width
        let h = screen.height
        let x = screen.minX
        let y = screen.minY

        switch self {

        // MARK: Halves
        case .leftHalf:
            return CGRect(x: x, y: y, width: floor(w / 2), height: h)
        case .rightHalf:
            return CGRect(x: x + ceil(w / 2), y: y, width: floor(w / 2), height: h)
        case .topHalf:
            return CGRect(x: x, y: y + ceil(h / 2), width: w, height: floor(h / 2))
        case .bottomHalf:
            return CGRect(x: x, y: y, width: w, height: floor(h / 2))
        case .centerHalf:
            return CGRect(x: x + floor(w / 4), y: y, width: floor(w / 2), height: h)

        // MARK: Corners (Quarters)
        case .topLeft:
            return CGRect(x: x, y: y + ceil(h / 2), width: floor(w / 2), height: floor(h / 2))
        case .topRight:
            return CGRect(x: x + ceil(w / 2), y: y + ceil(h / 2), width: floor(w / 2), height: floor(h / 2))
        case .bottomLeft:
            return CGRect(x: x, y: y, width: floor(w / 2), height: floor(h / 2))
        case .bottomRight:
            return CGRect(x: x + ceil(w / 2), y: y, width: floor(w / 2), height: floor(h / 2))

        // MARK: Thirds (Vertical)
        case .firstThird:
            return CGRect(x: x, y: y, width: floor(w / 3), height: h)
        case .centerThird:
            return CGRect(x: x + floor(w / 3), y: y, width: floor(w / 3), height: h)
        case .lastThird:
            return CGRect(x: x + floor(w * 2 / 3), y: y, width: floor(w / 3), height: h)
        case .firstTwoThirds:
            return CGRect(x: x, y: y, width: floor(w * 2 / 3), height: h)
        case .centerTwoThirds:
            return CGRect(x: x + floor(w / 6), y: y, width: floor(w * 2 / 3), height: h)
        case .lastTwoThirds:
            return CGRect(x: x + floor(w / 3), y: y, width: floor(w * 2 / 3), height: h)

        // MARK: Fourths (Vertical)
        case .firstFourth:
            return CGRect(x: x, y: y, width: floor(w / 4), height: h)
        case .secondFourth:
            return CGRect(x: x + floor(w / 4), y: y, width: floor(w / 4), height: h)
        case .thirdFourth:
            return CGRect(x: x + floor(w * 2 / 4), y: y, width: floor(w / 4), height: h)
        case .lastFourth:
            return CGRect(x: x + floor(w * 3 / 4), y: y, width: floor(w / 4), height: h)
        case .firstThreeFourths:
            return CGRect(x: x, y: y, width: floor(w * 3 / 4), height: h)
        case .centerThreeFourths:
            return CGRect(x: x + floor(w / 8), y: y, width: floor(w * 3 / 4), height: h)
        case .lastThreeFourths:
            return CGRect(x: x + floor(w / 4), y: y, width: floor(w * 3 / 4), height: h)

        // MARK: Sixths (3x2 grid)
        case .topLeftSixth:
            return CGRect(x: x, y: y + ceil(h / 2), width: floor(w / 3), height: floor(h / 2))
        case .topCenterSixth:
            return CGRect(x: x + floor(w / 3), y: y + ceil(h / 2), width: floor(w / 3), height: floor(h / 2))
        case .topRightSixth:
            return CGRect(x: x + floor(w * 2 / 3), y: y + ceil(h / 2), width: floor(w / 3), height: floor(h / 2))
        case .bottomLeftSixth:
            return CGRect(x: x, y: y, width: floor(w / 3), height: floor(h / 2))
        case .bottomCenterSixth:
            return CGRect(x: x + floor(w / 3), y: y, width: floor(w / 3), height: floor(h / 2))
        case .bottomRightSixth:
            return CGRect(x: x + floor(w * 2 / 3), y: y, width: floor(w / 3), height: floor(h / 2))

        // MARK: Ninths (3x3 grid)
        case .topLeftNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 0, row: 0)
        case .topCenterNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 1, row: 0)
        case .topRightNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 2, row: 0)
        case .middleLeftNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 0, row: 1)
        case .middleCenterNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 1, row: 1)
        case .middleRightNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 2, row: 1)
        case .bottomLeftNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 0, row: 2)
        case .bottomCenterNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 1, row: 2)
        case .bottomRightNinth:
            return gridRect(screen: screen, cols: 3, rows: 3, col: 2, row: 2)

        // MARK: Corner Thirds (2x2, each cell 2/3 size)
        case .topLeftThird:
            return CGRect(x: x, y: y + ceil(h / 3), width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .topRightThird:
            return CGRect(x: x + ceil(w / 3), y: y + ceil(h / 3), width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .bottomLeftThird:
            return CGRect(x: x, y: y, width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .bottomRightThird:
            return CGRect(x: x + ceil(w / 3), y: y, width: floor(w * 2 / 3), height: floor(h * 2 / 3))

        // MARK: Eighths (4x2 grid)
        case .topLeftEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 0, row: 0)
        case .topCenterLeftEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 1, row: 0)
        case .topCenterRightEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 2, row: 0)
        case .topRightEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 3, row: 0)
        case .bottomLeftEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 0, row: 1)
        case .bottomCenterLeftEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 1, row: 1)
        case .bottomCenterRightEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 2, row: 1)
        case .bottomRightEighth:
            return gridRect(screen: screen, cols: 4, rows: 2, col: 3, row: 1)

        // MARK: Maximize
        case .maximize:
            return screen
        case .almostMaximize:
            let inset = floor(min(w, h) * 0.03)
            return screen.insetBy(dx: inset, dy: inset)
        case .maximizeHeight:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: y, width: win.width, height: h)

        // MARK: Center (keep current size)
        case .center:
            guard let win = window else { return nil }
            return CGRect(x: x + floor((w - win.width) / 2), y: y + floor((h - win.height) / 2),
                          width: win.width, height: win.height)
        case .centerProminently:
            let newW = floor(w * 0.8)
            let newH = floor(h * 0.8)
            return CGRect(x: x + floor((w - newW) / 2), y: y + floor((h - newH) / 2), width: newW, height: newH)

        // MARK: Movement (keep size, shift position)
        case .moveLeft:
            guard let win = window else { return nil }
            return CGRect(x: x, y: win.minY, width: win.width, height: win.height)
        case .moveRight:
            guard let win = window else { return nil }
            return CGRect(x: x + w - win.width, y: win.minY, width: win.width, height: win.height)
        case .moveUp:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: y + h - win.height, width: win.width, height: win.height)
        case .moveDown:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: y, width: win.width, height: win.height)

        // MARK: Resize (relative to current)
        case .larger:
            guard let win = window else { return nil }
            return win.insetBy(dx: -30, dy: -30)
        case .smaller:
            guard let win = window else { return nil }
            return win.insetBy(dx: 30, dy: 30)
        case .largerWidth:
            guard let win = window else { return nil }
            return CGRect(x: win.minX - 30, y: win.minY, width: win.width + 60, height: win.height)
        case .smallerWidth:
            guard let win = window else { return nil }
            return CGRect(x: win.minX + 30, y: win.minY, width: win.width - 60, height: win.height)
        case .largerHeight:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY - 30, width: win.width, height: win.height + 60)
        case .smallerHeight:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY + 30, width: win.width, height: win.height - 60)

        // MARK: Halve/Double
        case .halveWidthLeft:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: floor(win.width / 2), height: win.height)
        case .halveWidthRight:
            guard let win = window else { return nil }
            let newW = floor(win.width / 2)
            return CGRect(x: win.maxX - newW, y: win.minY, width: newW, height: win.height)
        case .halveHeightUp:
            guard let win = window else { return nil }
            let newH = floor(win.height / 2)
            return CGRect(x: win.minX, y: win.maxY - newH, width: win.width, height: newH)
        case .halveHeightDown:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: win.width, height: floor(win.height / 2))
        case .doubleWidthLeft:
            guard let win = window else { return nil }
            return CGRect(x: win.minX - win.width, y: win.minY, width: win.width * 2, height: win.height)
        case .doubleWidthRight:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: win.width * 2, height: win.height)
        case .doubleHeightUp:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY, width: win.width, height: win.height * 2)
        case .doubleHeightDown:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: win.minY - win.height, width: win.width, height: win.height * 2)

        // MARK: Todo Layouts
        case .leftTodo:
            let todoWidth = CGFloat(Defaults.todoSidebarWidth.value)
            return CGRect(x: x, y: y, width: todoWidth, height: h)
        case .rightTodo:
            let todoWidth = CGFloat(Defaults.todoSidebarWidth.value)
            return CGRect(x: x + w - todoWidth, y: y, width: todoWidth, height: h)

        // MARK: Special Actions (handled elsewhere)
        case .restore, .nextDisplay, .previousDisplay,
             .tileAll, .cascadeAll, .cascadeActiveApp, .reverseAll, .specified:
            return nil
        }
    }

    private func gridRect(screen: CGRect, cols: Int, rows: Int, col: Int, row: Int) -> CGRect {
        let cellW = floor(screen.width / CGFloat(cols))
        let cellH = floor(screen.height / CGFloat(rows))
        let yPos = screen.maxY - cellH * CGFloat(row + 1)
        return CGRect(x: screen.minX + cellW * CGFloat(col), y: yPos, width: cellW, height: cellH)
    }
}

// ============================================================================
// MARK: - SimpleCalculation
// ============================================================================

/// The main calculation class that handles most window actions.
class SimpleCalculation: WindowCalculation {
    static let shared = SimpleCalculation()
    private static var cycleState = WindowCycleState()

    /// Returns true if the next repeat of this action would wrap back to the start of the cycle.
    static func wouldCycleWrap(for action: WindowAction) -> Bool {
        cycleState.wouldWrap(for: action)
    }

    /// Resets the cycle state, causing the next action to start at position 0.
    static func resetCycleState() {
        cycleState.reset()
    }

    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        let action = params.action
        let screen = params.usableScreens.currentScreen
        let visibleFrame = screen.adjustedVisibleFrame(params.ignoreTodo)
        let windowRect = params.window.rect

        var effectiveAction = action
        if Defaults.subsequentExecutionMode.value != .none {
            if let lastAction = params.lastAction, lastAction.action == action {
                effectiveAction = Self.cycleState.effectiveAction(for: action)
            } else {
                Self.cycleState.reset()
                Self.cycleState.lastAction = action
            }
        }

        guard let rect = effectiveAction.calculateRect(in: visibleFrame, window: windowRect) else {
            return nil
        }

        return WindowCalculationResult(rect: rect, screen: screen, resultingAction: effectiveAction)
    }
}

// ============================================================================
// MARK: - Cycling State
// ============================================================================

struct WindowCycleState {
    var lastAction: WindowAction?
    var cycleIndex: Int = 0

    mutating func effectiveAction(for action: WindowAction) -> WindowAction {
        if lastAction == action {
            cycleIndex = (cycleIndex + 1) % action.cycleGroup.count
        } else {
            lastAction = action
            cycleIndex = 0
        }
        return action.cycleGroup[cycleIndex]
    }

    /// Returns true if the next call to effectiveAction would wrap back to the start of the cycle.
    func wouldWrap(for action: WindowAction) -> Bool {
        guard lastAction == action else { return false }
        return cycleIndex == action.cycleGroup.count - 1
    }

    mutating func reset() {
        lastAction = nil
        cycleIndex = 0
    }
}

extension WindowAction {
    var cycleGroup: [WindowAction] {
        switch self {
        case .leftHalf:
            return [.leftHalf, .firstTwoThirds, .firstThird]
        case .rightHalf:
            return [.rightHalf, .lastTwoThirds, .lastThird]
        case .topHalf:
            return [.topHalf]
        case .bottomHalf:
            return [.bottomHalf]
        case .centerHalf:
            return [.centerHalf, .centerTwoThirds, .centerThird]
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return [self]
        case .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            return [.topLeftNinth, .topCenterNinth, .topRightNinth,
                    .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
                    .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth]
        case .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return [.topLeftSixth, .topCenterSixth, .topRightSixth,
                    .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth]
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return [.topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
                    .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth]
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            return [.topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird]
        default:
            return [self]
        }
    }
}

// ============================================================================
// MARK: - NextPrevDisplayCalculation
// ============================================================================

/// Handles moving windows between multiple displays.
class NextPrevDisplayCalculation: WindowCalculation {
    static let shared = NextPrevDisplayCalculation()

    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
                let usableScreens = params.usableScreens
        guard usableScreens.numScreens > 1 else { return nil }

        guard let targetScreen = getTargetScreen(for: params.action, from: usableScreens) else {
            return nil
        }

        let targetScreenFrame = targetScreen.adjustedVisibleFrame(params.ignoreTodo)
        let rectParams = params.asRectParams(visibleFrame: targetScreenFrame)

        if let matchedResult = attemptToMatchLastAction(params: params, rectParams: rectParams, targetScreen: targetScreen) {
            return matchedResult
        }

        let rectResult = calculateRect(rectParams)
        let resultingAction = rectResult.resultingAction ?? params.action
        return WindowCalculationResult(rect: rectResult.rect, screen: targetScreen, resultingAction: resultingAction)
    }

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
                let wasMaximized = params.lastAction?.action == .maximize
        let autoMaximizeEnabled = !Defaults.autoMaximize.userDisabled
        let screen = params.visibleFrameOfScreen

        if wasMaximized && autoMaximizeEnabled {
            if let rect = WindowAction.maximize.calculateRect(in: screen, window: params.window.rect) {
                return RectResult(rect, resultingAction: .maximize)
            }
        }

        if let rect = WindowAction.center.calculateRect(in: screen, window: params.window.rect) {
            return RectResult(rect, resultingAction: .center)
        }
        return RectResult(.null)
    }

    private func getTargetScreen(for action: WindowAction, from usableScreens: UsableScreens) -> NSScreen? {
                switch action {
        case .nextDisplay: return usableScreens.adjacentScreens?.next
        case .previousDisplay: return usableScreens.adjacentScreens?.prev
        default: return nil
        }
    }

    private func attemptToMatchLastAction(params: WindowCalculationParameters, rectParams: RectCalculationParameters,
                                          targetScreen: NSScreen) -> WindowCalculationResult? {
                guard Defaults.attemptMatchOnNextPrevDisplay.userEnabled,
              let lastAction = params.lastAction,
              let calculation = lastAction.action.calculation else {
            return nil
        }

        AppDelegate.windowHistory.lastWindowActions.removeValue(forKey: params.window.id)

        let newCalculationParams = RectCalculationParameters(
            window: rectParams.window,
            visibleFrameOfScreen: rectParams.visibleFrameOfScreen,
            action: lastAction.action,
            lastAction: nil
        )
        let rectResult = calculation.calculateRect(newCalculationParams)
        return WindowCalculationResult(rect: rectResult.rect, screen: targetScreen, resultingAction: lastAction.action)
    }
}

// ============================================================================
// MARK: - SpecifiedCalculation
// ============================================================================

/// Calculates a window rectangle with a user-specified size, centered on the screen.
final class SpecifiedCalculation: WindowCalculation {
    static let shared = SpecifiedCalculation()
    private let specifiedHeight: CGFloat
    private let specifiedWidth: CGFloat

    override init() {
                specifiedHeight = CGFloat(Defaults.specifiedHeight.value)
        specifiedWidth = CGFloat(Defaults.specifiedWidth.value)
    }

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
                let screen = params.visibleFrameOfScreen
        let windowWidth = specifiedWidth <= 1 ? screen.width * specifiedWidth : min(screen.width, round(specifiedWidth))
        let windowHeight = specifiedHeight <= 1 ? screen.height * specifiedHeight : round(specifiedHeight)
        let centeredX = screen.minX + round((screen.width - windowWidth) / 2.0)
        let centeredY = screen.minY + round((screen.height - windowHeight) / 2.0)
        return RectResult(CGRect(x: centeredX, y: centeredY, width: windowWidth, height: windowHeight))
    }
}

// ============================================================================
// MARK: - GapCalculation
// ============================================================================

/// Handles applying gaps (padding/margins) between windows and screen edges.
class GapCalculation {

    static func applyGaps(_ rect: CGRect, dimension: Dimension = .both, sharedEdges: Edge = .none, gapSize: Float) -> CGRect {
                let fullGap = CGFloat(gapSize)
        let halfGap = fullGap / 2

        var result = rect.insetBy(
            dx: dimension.contains(.horizontal) ? fullGap : 0,
            dy: dimension.contains(.vertical) ? fullGap : 0
        )

        result = adjustForSharedHorizontalEdges(result, sharedEdges: sharedEdges, dimension: dimension, halfGap: halfGap)
        result = adjustForSharedVerticalEdges(result, sharedEdges: sharedEdges, dimension: dimension, halfGap: halfGap)
        return result
    }

    private static func adjustForSharedHorizontalEdges(_ rect: CGRect, sharedEdges: Edge, dimension: Dimension, halfGap: CGFloat) -> CGRect {
                guard dimension.contains(.horizontal) else { return rect }
        var result = rect
        if sharedEdges.contains(.left) {
            result.origin.x -= halfGap
            result.size.width += halfGap
        }
        if sharedEdges.contains(.right) {
            result.size.width += halfGap
        }
        return result
    }

    private static func adjustForSharedVerticalEdges(_ rect: CGRect, sharedEdges: Edge, dimension: Dimension, halfGap: CGFloat) -> CGRect {
                guard dimension.contains(.vertical) else { return rect }
        var result = rect
        if sharedEdges.contains(.bottom) {
            result.origin.y -= halfGap
            result.size.height += halfGap
        }
        if sharedEdges.contains(.top) {
            result.size.height += halfGap
        }
        return result
    }
}

// Note: Edge and Dimension types are imported from WindowManagerCore
