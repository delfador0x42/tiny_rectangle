//  SnapAreaCalculator.swift - Snap area detection
//
//  Pure functions for detecting which snap area the cursor is in.
//  No AppKit/Cocoa dependencies.

import CoreGraphics

// MARK: - SnapAreaCalculator

/// Pure functions for snap area calculations.
///
/// Determines which window action should be triggered based on cursor position
/// relative to screen edges and corners.
public enum SnapAreaCalculator {

    // MARK: - Types

    /// A snap zone on the screen edge.
    public struct SnapZone: Sendable {
        public let directional: Directional
        public let rect: CGRect

        public init(directional: Directional, rect: CGRect) {
            self.directional = directional
            self.rect = rect
        }
    }

    // MARK: - Zone Calculations

    /// Calculate the snap zones for a screen.
    /// - Parameters:
    ///   - screenFrame: The screen's frame
    ///   - edgeSize: Size of the edge snap zones (typically 1-5 pixels)
    ///   - cornerSize: Size of the corner snap zones (typically 15-50 pixels)
    /// - Returns: Array of snap zones for all screen edges and corners
    public static func calculateSnapZones(
        screenFrame: CGRect,
        edgeSize: CGFloat,
        cornerSize: CGFloat
    ) -> [SnapZone] {
        var zones: [SnapZone] = []

        let x = screenFrame.minX
        let y = screenFrame.minY
        let w = screenFrame.width
        let h = screenFrame.height

        // Corners (squares at each corner)
        zones.append(SnapZone(
            directional: .tl,
            rect: CGRect(x: x, y: y + h - cornerSize, width: cornerSize, height: cornerSize)
        ))
        zones.append(SnapZone(
            directional: .tr,
            rect: CGRect(x: x + w - cornerSize, y: y + h - cornerSize, width: cornerSize, height: cornerSize)
        ))
        zones.append(SnapZone(
            directional: .bl,
            rect: CGRect(x: x, y: y, width: cornerSize, height: cornerSize)
        ))
        zones.append(SnapZone(
            directional: .br,
            rect: CGRect(x: x + w - cornerSize, y: y, width: cornerSize, height: cornerSize)
        ))

        // Top edge (between corners)
        zones.append(SnapZone(
            directional: .t,
            rect: CGRect(x: x + cornerSize, y: y + h - edgeSize, width: w - cornerSize * 2, height: edgeSize)
        ))

        // Bottom edge (between corners)
        zones.append(SnapZone(
            directional: .b,
            rect: CGRect(x: x + cornerSize, y: y, width: w - cornerSize * 2, height: edgeSize)
        ))

        // Left edge (between corners)
        zones.append(SnapZone(
            directional: .l,
            rect: CGRect(x: x, y: y + cornerSize, width: edgeSize, height: h - cornerSize * 2)
        ))

        // Right edge (between corners)
        zones.append(SnapZone(
            directional: .r,
            rect: CGRect(x: x + w - edgeSize, y: y + cornerSize, width: edgeSize, height: h - cornerSize * 2)
        ))

        return zones
    }

    /// Detect which snap zone contains the cursor.
    /// - Parameters:
    ///   - cursor: The cursor position
    ///   - zones: The snap zones to check
    /// - Returns: The directional position if cursor is in a zone, nil otherwise
    public static func detectSnapZone(
        cursor: CGPoint,
        zones: [SnapZone]
    ) -> Directional? {
        // Check corners first (they have priority)
        for zone in zones where [.tl, .tr, .bl, .br].contains(zone.directional) {
            if zone.rect.contains(cursor) {
                return zone.directional
            }
        }

        // Then check edges
        for zone in zones where [.t, .b, .l, .r].contains(zone.directional) {
            if zone.rect.contains(cursor) {
                return zone.directional
            }
        }

        return nil
    }

    // MARK: - Compound Snap Area Calculations

    /// Calculate the window action for a compound left edge snap.
    /// - Parameters:
    ///   - cursor: The cursor position
    ///   - screenFrame: The screen's frame
    ///   - cornerZoneSize: Size of the corner zones on the edge
    ///   - marginTop: Margin from top of screen
    ///   - marginBottom: Margin from bottom of screen
    /// - Returns: The calculated window action
    public static func calculateLeftEdgeAction(
        cursor: CGPoint,
        screenFrame: CGRect,
        cornerZoneSize: CGFloat,
        marginTop: CGFloat = 0,
        marginBottom: CGFloat = 0
    ) -> WindowActionType {
        // Bottom corner zone
        if cursor.y <= screenFrame.minY + marginBottom + cornerZoneSize {
            return .bottomHalf
        }

        // Top corner zone
        if cursor.y >= screenFrame.maxY - marginTop - cornerZoneSize {
            return .topHalf
        }

        return .leftHalf
    }

    /// Calculate the window action for a compound right edge snap.
    public static func calculateRightEdgeAction(
        cursor: CGPoint,
        screenFrame: CGRect,
        cornerZoneSize: CGFloat,
        marginTop: CGFloat = 0,
        marginBottom: CGFloat = 0
    ) -> WindowActionType {
        // Bottom corner zone
        if cursor.y <= screenFrame.minY + marginBottom + cornerZoneSize {
            return .bottomHalf
        }

        // Top corner zone
        if cursor.y >= screenFrame.maxY - marginTop - cornerZoneSize {
            return .topHalf
        }

        return .rightHalf
    }

    /// Calculate the window action for horizontal thirds (bottom edge).
    public static func calculateHorizontalThirdsAction(
        cursor: CGPoint,
        screenFrame: CGRect,
        priorAction: WindowActionType?
    ) -> WindowActionType {
        let thirdWidth = floor(screenFrame.width / 3)
        let leftEnd = screenFrame.minX + thirdWidth
        let rightStart = screenFrame.maxX - thirdWidth

        if cursor.x <= leftEnd {
            return .firstThird
        } else if cursor.x >= rightStart {
            return .lastThird
        } else {
            // Center region - check for expansion
            return determineCenterThirdAction(priorAction: priorAction)
        }
    }

    /// Calculate the window action for fourths (horizontal).
    public static func calculateFourthsAction(
        cursor: CGPoint,
        screenFrame: CGRect,
        priorAction: WindowActionType?
    ) -> WindowActionType {
        let columnWidth = floor(screenFrame.width / 4)
        let col1End = screenFrame.minX + columnWidth
        let col2End = screenFrame.minX + columnWidth * 2
        let col3End = screenFrame.minX + columnWidth * 3

        if cursor.x <= col1End {
            return .firstFourth
        } else if cursor.x <= col2End {
            // Second column - expansion logic
            if let prior = priorAction {
                if prior == .firstFourth || prior == .firstThreeFourths {
                    return .firstThreeFourths
                }
                if prior == .thirdFourth || prior == .lastThreeFourths || prior == .centerHalf {
                    return .centerHalf
                }
            }
            return .secondFourth
        } else if cursor.x <= col3End {
            // Third column - expansion logic
            if let prior = priorAction {
                if prior == .secondFourth || prior == .firstThreeFourths || prior == .centerHalf {
                    return .centerHalf
                }
                if prior == .lastFourth || prior == .lastThreeFourths {
                    return .lastThreeFourths
                }
            }
            return .thirdFourth
        } else {
            return .lastFourth
        }
    }

    /// Calculate left/right halves based on horizontal position.
    public static func calculateHorizontalHalvesAction(
        cursor: CGPoint,
        screenFrame: CGRect
    ) -> WindowActionType {
        cursor.x < screenFrame.midX ? .leftHalf : .rightHalf
    }

    /// Calculate top/bottom halves based on vertical position.
    public static func calculateVerticalHalvesAction(
        cursor: CGPoint,
        screenFrame: CGRect
    ) -> WindowActionType {
        cursor.y < screenFrame.midY ? .bottomHalf : .topHalf
    }

    // MARK: - Private Helpers

    private static func determineCenterThirdAction(priorAction: WindowActionType?) -> WindowActionType {
        guard let prior = priorAction else { return .centerThird }

        switch prior {
        case .firstThird, .firstTwoThirds:
            return .firstTwoThirds
        case .lastThird, .lastTwoThirds:
            return .lastTwoThirds
        default:
            return .centerThird
        }
    }
}
