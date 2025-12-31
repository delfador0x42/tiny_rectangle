//
//  SimpleWindowCalculation.swift
//  tiny_window_manager
//
//  A complete rewrite of the window calculation system.
//  Replaces ~50 class files and ~3000 lines with ~200 lines.
//

import Foundation

// MARK: - Simple Rect Calculation

extension WindowAction {

    /// Calculate the window rect for this action.
    /// This is the entire calculation system in one switch statement.
    ///
    /// - Parameters:
    ///   - screen: The visible frame of the screen (excludes menu bar, dock)
    ///   - window: The current window rect (needed for move/resize actions)
    /// - Returns: The calculated rect, or nil if this action needs special handling
    func calculateRect(in screen: CGRect, window: CGRect? = nil) -> CGRect? {
        let w = screen.width
        let h = screen.height
        let x = screen.minX
        let y = screen.minY

        switch self {

        // MARK: - Halves
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

        // MARK: - Corners (Quarters)
        case .topLeft:
            return CGRect(x: x, y: y + ceil(h / 2), width: floor(w / 2), height: floor(h / 2))
        case .topRight:
            return CGRect(x: x + ceil(w / 2), y: y + ceil(h / 2), width: floor(w / 2), height: floor(h / 2))
        case .bottomLeft:
            return CGRect(x: x, y: y, width: floor(w / 2), height: floor(h / 2))
        case .bottomRight:
            return CGRect(x: x + ceil(w / 2), y: y, width: floor(w / 2), height: floor(h / 2))

        // MARK: - Thirds (Vertical)
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

        // MARK: - Fourths (Vertical)
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

        // MARK: - Sixths (3x2 grid)
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

        // MARK: - Ninths (3x3 grid)
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

        // MARK: - Corner Thirds (2x2, each cell 2/3 size)
        case .topLeftThird:
            return CGRect(x: x, y: y + ceil(h / 3), width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .topRightThird:
            return CGRect(x: x + ceil(w / 3), y: y + ceil(h / 3), width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .bottomLeftThird:
            return CGRect(x: x, y: y, width: floor(w * 2 / 3), height: floor(h * 2 / 3))
        case .bottomRightThird:
            return CGRect(x: x + ceil(w / 3), y: y, width: floor(w * 2 / 3), height: floor(h * 2 / 3))

        // MARK: - Eighths (4x2 grid)
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

        // MARK: - Maximize
        case .maximize:
            return screen
        case .almostMaximize:
            let inset = floor(min(w, h) * 0.03) // 3% inset
            return screen.insetBy(dx: inset, dy: inset)
        case .maximizeHeight:
            guard let win = window else { return nil }
            return CGRect(x: win.minX, y: y, width: win.width, height: h)

        // MARK: - Center (keep current size)
        case .center:
            guard let win = window else { return nil }
            return CGRect(
                x: x + floor((w - win.width) / 2),
                y: y + floor((h - win.height) / 2),
                width: win.width,
                height: win.height
            )
        case .centerProminently:
            // Center at 80% of screen size
            let newW = floor(w * 0.8)
            let newH = floor(h * 0.8)
            return CGRect(
                x: x + floor((w - newW) / 2),
                y: y + floor((h - newH) / 2),
                width: newW,
                height: newH
            )

        // MARK: - Movement (keep size, shift position)
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

        // MARK: - Resize (relative to current)
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

        // MARK: - Halve/Double
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

        // MARK: - Todo Layouts
        case .leftTodo:
            let todoWidth = CGFloat(Defaults.todoSidebarWidth.value)
            return CGRect(x: x, y: y, width: todoWidth, height: h)
        case .rightTodo:
            let todoWidth = CGFloat(Defaults.todoSidebarWidth.value)
            return CGRect(x: x + w - todoWidth, y: y, width: todoWidth, height: h)

        // MARK: - Special Actions (handled elsewhere)
        case .restore, .nextDisplay, .previousDisplay,
             .tileAll, .cascadeAll, .cascadeActiveApp, .reverseAll, .specified:
            return nil
        }
    }

    /// Helper for grid-based calculations
    private func gridRect(screen: CGRect, cols: Int, rows: Int, col: Int, row: Int) -> CGRect {
        let cellW = floor(screen.width / CGFloat(cols))
        let cellH = floor(screen.height / CGFloat(rows))
        // row 0 = top (in macOS coordinates, higher Y)
        let yPos = screen.maxY - cellH * CGFloat(row + 1)
        return CGRect(
            x: screen.minX + cellW * CGFloat(col),
            y: yPos,
            width: cellW,
            height: cellH
        )
    }
}

// MARK: - Simple Calculation Class (Drop-in replacement for WindowCalculationFactory)

/// A single calculation class that handles ALL window actions.
/// Replaces ~50 separate calculation classes.
class SimpleCalculation: WindowCalculation {

    /// Shared cycling state
    private static var cycleState = WindowCycleState()

    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        let action = params.action
        let screen = params.usableScreens.currentScreen
        let visibleFrame = screen.adjustedVisibleFrame(params.ignoreTodo)
        let windowRect = params.window.rect

        // Handle cycling if enabled
        var effectiveAction = action
        if Defaults.subsequentExecutionMode.value != .none {
            if let lastAction = params.lastAction, lastAction.action == action {
                effectiveAction = Self.cycleState.effectiveAction(for: action)
            } else {
                Self.cycleState.reset()
                Self.cycleState.lastAction = action
            }
        }

        // Calculate the rect using our simple switch statement
        guard let rect = effectiveAction.calculateRect(in: visibleFrame, window: windowRect) else {
            return nil
        }

        return WindowCalculationResult(
            rect: rect,
            screen: screen,
            resultingAction: effectiveAction,
            resultingSubAction: nil
        )
    }
}

// MARK: - Factory Replacement

extension WindowCalculationFactory {
    /// Single calculation instance that handles everything
    static let simpleCalculation = SimpleCalculation()

    /// New simplified lookup - all actions use the same calculation
    static func calculation(for action: WindowAction) -> WindowCalculation? {
        // Special actions that need their own handling
        switch action {
        case .nextDisplay, .previousDisplay:
            return nextPrevDisplayCalculation
        case .restore:
            return nil // Handled separately
        case .tileAll, .cascadeAll, .cascadeActiveApp, .reverseAll:
            return nil // Multi-window actions handled elsewhere
        case .specified:
            return specifiedCalculation
        default:
            return simpleCalculation
        }
    }
}

// MARK: - Cycling State

/// Simple state machine for cycling through positions when same action is repeated.
/// Replaces the entire GridCycling and SixthsRepeated infrastructure.
struct WindowCycleState {
    var lastAction: WindowAction?
    var cycleIndex: Int = 0

    /// Get the effective action considering cycling.
    /// For example, pressing leftHalf repeatedly cycles: 1/2 → 2/3 → 1/3
    mutating func effectiveAction(for action: WindowAction) -> WindowAction {
        if lastAction == action {
            cycleIndex = (cycleIndex + 1) % action.cycleGroup.count
        } else {
            lastAction = action
            cycleIndex = 0
        }
        return action.cycleGroup[cycleIndex]
    }

    mutating func reset() {
        lastAction = nil
        cycleIndex = 0
    }
}

extension WindowAction {
    /// Define which actions cycle together.
    /// The first item is the default when first pressed.
    var cycleGroup: [WindowAction] {
        switch self {
        // Halves cycle through sizes
        case .leftHalf:
            return [.leftHalf, .firstTwoThirds, .firstThird]
        case .rightHalf:
            return [.rightHalf, .lastTwoThirds, .lastThird]
        case .topHalf:
            return [.topHalf] // Could add vertical thirds if desired
        case .bottomHalf:
            return [.bottomHalf]
        case .centerHalf:
            return [.centerHalf, .centerTwoThirds, .centerThird]

        // Corners could cycle through sizes too
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            return [self] // No cycling for corners by default

        // Ninths cycle through all 9 positions
        case .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            return [
                .topLeftNinth, .topCenterNinth, .topRightNinth,
                .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
                .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth
            ]

        // Sixths cycle through all 6 positions
        case .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return [
                .topLeftSixth, .topCenterSixth, .topRightSixth,
                .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth
            ]

        // Eighths cycle through all 8 positions
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return [
                .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
                .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth
            ]

        // Corner thirds cycle through all 4
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            return [.topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird]

        // Everything else doesn't cycle
        default:
            return [self]
        }
    }
}
