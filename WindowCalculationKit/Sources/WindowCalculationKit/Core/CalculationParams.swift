//
//  CalculationParams.swift
//  WindowCalculationKit
//
//  Input parameters for window calculations.
//

import CoreGraphics

/// Information about the window being positioned.
public struct WindowInfo: Sendable {

    /// Unique identifier for the window.
    public let id: UInt32

    /// Current window rectangle in screen coordinates.
    public let rect: CGRect

    public init(id: UInt32, rect: CGRect) {
        self.id = id
        self.rect = rect
    }
}

/// Parameters for rectangle calculations.
///
/// This is the primary input to calculation methods, containing all the
/// information needed to calculate a window's new position.
public struct CalculationParams: Sendable {

    /// Information about the window being positioned.
    public let window: WindowInfo

    /// The visible area of the screen (excluding menu bar, dock, etc.).
    public let visibleFrame: CGRect

    /// The action being performed.
    public let action: ActionIdentifier

    /// Information about the last action (for cycling detection).
    public let lastAction: LastActionInfo?

    /// Settings that affect calculation behavior.
    public let settings: CalculationSettings

    // MARK: - Initialization

    public init(
        window: WindowInfo,
        visibleFrame: CGRect,
        action: ActionIdentifier,
        lastAction: LastActionInfo? = nil,
        settings: CalculationSettings = .default
    ) {
        self.window = window
        self.visibleFrame = visibleFrame
        self.action = action
        self.lastAction = lastAction
        self.settings = settings
    }

    // MARK: - Convenience

    /// Whether this is a repeated execution of the same action.
    public var isRepeatedAction: Bool {
        guard let last = lastAction else { return false }
        return last.action == action
    }

    /// Whether the screen is in landscape orientation.
    public var isLandscape: Bool {
        visibleFrame.width >= visibleFrame.height
    }
}

/// Information about the previously executed action.
public struct LastActionInfo: Sendable {

    /// The action that was performed.
    public let action: ActionIdentifier

    /// More granular sub-action.
    public let subAction: SubActionIdentifier?

    /// The resulting window rectangle (for comparison).
    public let rect: CGRect

    /// How many times this action has been repeated.
    public let count: Int

    public init(
        action: ActionIdentifier,
        subAction: SubActionIdentifier? = nil,
        rect: CGRect,
        count: Int = 1
    ) {
        self.action = action
        self.subAction = subAction
        self.rect = rect
        self.count = count
    }
}

/// Settings that affect calculation behavior.
///
/// This abstracts away the app's Defaults system, allowing the package
/// to be configured without depending on UserDefaults.
public struct CalculationSettings: Sendable {

    /// Whether cycling through sizes is enabled.
    public let cyclingEnabled: Bool

    /// Which sizes to cycle through.
    public let cycleSizes: Set<CycleSize>

    /// Gap size between windows (in pixels).
    public let gapSize: CGFloat

    /// Additional gap from screen edges.
    public let screenEdgeGaps: EdgeGaps

    // MARK: - Initialization

    public init(
        cyclingEnabled: Bool = true,
        cycleSizes: Set<CycleSize> = CycleSize.defaultSizes,
        gapSize: CGFloat = 0,
        screenEdgeGaps: EdgeGaps = .zero
    ) {
        self.cyclingEnabled = cyclingEnabled
        self.cycleSizes = cycleSizes
        self.gapSize = gapSize
        self.screenEdgeGaps = screenEdgeGaps
    }

    /// Default settings.
    public static let `default` = CalculationSettings()
}

/// Gap values for screen edges.
public struct EdgeGaps: Sendable {

    public let top: CGFloat
    public let bottom: CGFloat
    public let left: CGFloat
    public let right: CGFloat

    public init(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }

    public static let zero = EdgeGaps()

    /// Create with uniform gap on all edges.
    public static func uniform(_ gap: CGFloat) -> EdgeGaps {
        EdgeGaps(top: gap, bottom: gap, left: gap, right: gap)
    }
}
