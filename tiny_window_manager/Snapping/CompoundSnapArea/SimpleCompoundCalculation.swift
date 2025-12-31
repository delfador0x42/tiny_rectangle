//
//  SimpleCompoundCalculation.swift
//  tiny_window_manager
//
//  Consolidated compound snap area calculations.
//  Replaces HalvesCompoundCalculation, ThirdsCompoundCalculation,
//  SixthsCompoundCalculation, and FourthsCompoundCalculation.
//

import Foundation

// MARK: - Unified Compound Calculation

/// Single calculation class that handles ALL compound snap area types.
/// Replaces 10 separate calculation structs.
struct SimpleCompoundCalculation: CompoundSnapAreaCalculation {

    let compoundType: CompoundSnapArea

    func snapArea(
        cursorLocation loc: NSPoint,
        screen: NSScreen,
        directional: Directional,
        priorSnapArea: SnapArea?
    ) -> SnapArea? {
        print(#function, "called")

        let frame = screen.frame
        let priorAction = priorSnapArea?.action

        let action: WindowAction? = switch compoundType {
        case .leftTopBottomHalf:
            calculateLeftEdge(loc: loc, frame: frame, priorAction: priorAction)
        case .rightTopBottomHalf:
            calculateRightEdge(loc: loc, frame: frame, priorAction: priorAction)
        case .thirds:
            calculateHorizontalThirds(loc: loc, frame: frame, priorAction: priorAction)
        case .portraitThirdsSide:
            calculateVerticalThirds(loc: loc, frame: frame, priorAction: priorAction)
        case .halves:
            calculateLeftRightHalves(loc: loc, frame: frame)
        case .topSixths:
            calculateTopSixths(loc: loc, frame: frame, priorAction: priorAction)
        case .bottomSixths:
            calculateBottomSixths(loc: loc, frame: frame, priorAction: priorAction)
        case .fourths:
            calculateFourths(loc: loc, frame: frame, priorAction: priorAction)
        case .portraitTopBottomHalves:
            calculateTopBottomHalves(loc: loc, frame: frame, priorAction: priorAction)
        }

        guard let action else { return nil }
        return SnapArea(screen: screen, directional: directional, action: action)
    }

    // MARK: - Edge Calculations

    /// Left edge: left half with top/bottom corners
    private func calculateLeftEdge(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction {
        let cornerSize = CGFloat(Defaults.shortEdgeSnapAreaSize.value)
        let marginTop = Defaults.snapEdgeMarginTop.cgFloat
        let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat
        let ignoredAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

        // Bottom corner zone
        if loc.y <= frame.minY + marginBottom + cornerSize {
            if !ignoredAreas.contains(.bottomLeftShort) {
                return .bottomHalf
            }
        }

        // Top corner zone
        if loc.y >= frame.maxY - marginTop - cornerSize {
            if !ignoredAreas.contains(.topLeftShort) {
                return .topHalf
            }
        }

        return .leftHalf
    }

    /// Right edge: right half with top/bottom corners
    private func calculateRightEdge(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction {
        let cornerSize = CGFloat(Defaults.shortEdgeSnapAreaSize.value)
        let marginTop = Defaults.snapEdgeMarginTop.cgFloat
        let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat
        let ignoredAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

        // Bottom corner zone
        if loc.y <= frame.minY + marginBottom + cornerSize {
            if !ignoredAreas.contains(.bottomRightShort) {
                return .bottomHalf
            }
        }

        // Top corner zone
        if loc.y >= frame.maxY - marginTop - cornerSize {
            if !ignoredAreas.contains(.topRightShort) {
                return .topHalf
            }
        }

        return .rightHalf
    }

    /// Top/bottom edge: simple left/right halves
    private func calculateLeftRightHalves(loc: NSPoint, frame: CGRect) -> WindowAction {
        loc.x < frame.midX ? .leftHalf : .rightHalf
    }

    /// Portrait mode: top/bottom halves with corner zones
    private func calculateTopBottomHalves(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction? {
        let cornerSize = Defaults.shortEdgeSnapAreaSize.cgFloat
        let marginTop = Defaults.snapEdgeMarginTop.cgFloat
        let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat
        let ignoredAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

        // Bottom corner zone
        if loc.y <= frame.minY + marginBottom + cornerSize {
            let option: SnapAreaOption = loc.x < frame.midX ? .bottomLeftShort : .bottomRightShort
            if !ignoredAreas.contains(option) {
                return .bottomHalf
            }
        }

        // Top corner zone
        if loc.y >= frame.maxY - marginTop - cornerSize {
            let option: SnapAreaOption = loc.x < frame.midX ? .topLeftShort : .topRightShort
            if !ignoredAreas.contains(option) {
                return .topHalf
            }
        }

        // Main vertical split
        let midY = frame.minY + frame.height / 2
        return loc.y <= midY ? .bottomHalf : .topHalf
    }

    // MARK: - Thirds Calculations

    /// Horizontal thirds (landscape monitors)
    private func calculateHorizontalThirds(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction {
        let thirdWidth = floor(frame.width / 3)
        let leftEnd = frame.minX + thirdWidth
        let rightStart = frame.maxX - thirdWidth

        if loc.x <= leftEnd {
            return .firstThird
        } else if loc.x >= rightStart {
            return .lastThird
        } else {
            // Center region - check for expansion
            return determineCenterThirdAction(priorAction: priorAction)
        }
    }

    /// Vertical thirds (portrait monitors) with corner zones
    private func calculateVerticalThirds(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction? {
        let cornerSize = Defaults.shortEdgeSnapAreaSize.cgFloat
        let marginTop = Defaults.snapEdgeMarginTop.cgFloat
        let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat
        let ignoredAreas = SnapAreaOption(rawValue: Defaults.ignoredSnapAreas.value)

        // Check corner zones first
        if loc.y <= frame.minY + marginBottom + cornerSize {
            let option: SnapAreaOption = loc.x < frame.midX ? .bottomLeftShort : .bottomRightShort
            if !ignoredAreas.contains(option) {
                return .bottomHalf
            }
        }

        if loc.y >= frame.maxY - marginTop - cornerSize {
            let option: SnapAreaOption = loc.x < frame.midX ? .topLeftShort : .topRightShort
            if !ignoredAreas.contains(option) {
                return .topHalf
            }
        }

        // Vertical thirds
        let thirdHeight = floor(frame.height / 3)
        let bottomEnd = frame.minY + thirdHeight
        let topStart = frame.maxY - thirdHeight

        if loc.y <= bottomEnd {
            return .lastThird  // Bottom = last
        } else if loc.y >= topStart {
            return .firstThird  // Top = first
        } else {
            return determineCenterThirdAction(priorAction: priorAction)
        }
    }

    /// Center third expansion logic
    private func determineCenterThirdAction(priorAction: WindowAction?) -> WindowAction {
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

    // MARK: - Sixths Calculations

    /// Top edge: sixths or maximize
    private func calculateTopSixths(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction {
        guard let prior = priorAction else { return .maximize }

        let thirdWidth = floor(frame.width / 3)
        let leftEnd = frame.minX + thirdWidth
        let rightStart = frame.maxX - thirdWidth

        // Left region
        if loc.x <= leftEnd {
            if [.topLeft, .topLeftSixth, .topCenterSixth].contains(prior) {
                return .topLeftSixth
            }
        }

        // Right region
        if loc.x >= rightStart {
            if [.topRight, .topRightSixth, .topCenterSixth].contains(prior) {
                return .topRightSixth
            }
        }

        // Coming from any top sixth -> center sixth
        if [.topLeftSixth, .topRightSixth, .topCenterSixth].contains(prior) {
            return .topCenterSixth
        }

        return .maximize
    }

    /// Bottom edge: sixths or thirds
    private func calculateBottomSixths(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction {
        guard let prior = priorAction else {
            return calculateHorizontalThirds(loc: loc, frame: frame, priorAction: nil)
        }

        let thirdWidth = floor(frame.width / 3)
        let leftEnd = frame.minX + thirdWidth
        let rightStart = frame.maxX - thirdWidth

        // Left region
        if loc.x <= leftEnd {
            if [.bottomLeft, .bottomLeftSixth, .bottomCenterSixth].contains(prior) {
                return .bottomLeftSixth
            }
        }

        // Center region
        if loc.x > leftEnd && loc.x < rightStart {
            if [.bottomRightSixth, .bottomLeftSixth, .bottomCenterSixth].contains(prior) {
                return .bottomCenterSixth
            }
        }

        // Right region
        if loc.x >= rightStart {
            if [.bottomRight, .bottomRightSixth, .bottomCenterSixth].contains(prior) {
                return .bottomRightSixth
            }
        }

        // Fallback to thirds
        return calculateHorizontalThirds(loc: loc, frame: frame, priorAction: prior)
    }

    // MARK: - Fourths Calculation

    /// Four columns with expansion logic
    private func calculateFourths(loc: NSPoint, frame: CGRect, priorAction: WindowAction?) -> WindowAction {
        let columnWidth = floor(frame.width / 4)
        let col1End = frame.minX + columnWidth
        let col2End = frame.minX + columnWidth * 2
        let col3End = frame.minX + columnWidth * 3

        if loc.x <= col1End {
            return .firstFourth
        } else if loc.x <= col2End {
            // Second column - expansion logic
            if let prior = priorAction {
                if [.firstFourth, .firstThreeFourths].contains(prior) {
                    return .firstThreeFourths
                }
                if [.thirdFourth, .lastThreeFourths, .centerHalf].contains(prior) {
                    return .centerHalf
                }
            }
            return .secondFourth
        } else if loc.x <= col3End {
            // Third column - expansion logic
            if let prior = priorAction {
                if [.secondFourth, .firstThreeFourths, .centerHalf].contains(prior) {
                    return .centerHalf
                }
                if [.lastFourth, .lastThreeFourths].contains(prior) {
                    return .lastThreeFourths
                }
            }
            return .thirdFourth
        } else {
            return .lastFourth
        }
    }
}
