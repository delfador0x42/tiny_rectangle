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
@MainActor
protocol Calculation {
    func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult?
    func calculateRect(_ params: RectCalculationParameters) -> RectResult
}

// ============================================================================
// MARK: - Base Class
// ============================================================================

/// The base class for all window position calculations.
@MainActor
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

@MainActor
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
    /// Delegates to the pure RectCalculator in WindowManagerCore.
    func calculateRect(in screen: CGRect, window: CGRect? = nil) -> CGRect? {
        RectCalculator.calculateRect(for: self, in: screen, window: window, settings: Defaults.settings)
    }
}

// ============================================================================
// MARK: - SimpleCalculation
// ============================================================================

/// The main calculation class that handles most window actions.
class SimpleCalculation: WindowCalculation {
    /// Legacy accessor - use AppServices.shared.simpleCalculation for new code.
    static var shared: SimpleCalculation { AppServices.shared.simpleCalculation }
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

// cycleGroup is now defined in WindowManagerCore/WindowActionType.swift

// ============================================================================
// MARK: - NextPrevDisplayCalculation
// ============================================================================

/// Handles moving windows between multiple displays.
class NextPrevDisplayCalculation: WindowCalculation {
    /// Legacy accessor - use AppServices.shared.nextPrevDisplayCalculation for new code.
    static var shared: NextPrevDisplayCalculation { AppServices.shared.nextPrevDisplayCalculation }

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
    /// Legacy accessor - use AppServices.shared.specifiedCalculation for new code.
    static var shared: SpecifiedCalculation { AppServices.shared.specifiedCalculation }
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
