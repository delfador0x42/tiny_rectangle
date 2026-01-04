//  TilePreview.swift - Visual preview of window positions
//
//  A SwiftUI component that shows a miniature preview of how a
//  window action positions the window on screen.

import SwiftUI
import WindowManagerCore

// MARK: - TilePreview

/// Shows a visual representation of a window action.
///
/// Displays a small rectangle showing where the window will be
/// positioned relative to the screen.
public struct TilePreview: View {
    public let action: WindowActionType

    public init(action: WindowActionType) {
        self.action = action
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (inactive area)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))

                // Active area
                activeArea(in: geometry.size)
                    .fill(Color.gray.opacity(0.7))
            }
        }
    }

    private func activeArea(in size: CGSize) -> Path {
        let w = size.width
        let h = size.height

        let rect: CGRect
        switch action {
        // Halves
        case .leftHalf:
            rect = CGRect(x: 0, y: 0, width: w/2, height: h)
        case .rightHalf:
            rect = CGRect(x: w/2, y: 0, width: w/2, height: h)
        case .centerHalf:
            rect = CGRect(x: w/4, y: 0, width: w/2, height: h)
        case .topHalf:
            rect = CGRect(x: 0, y: 0, width: w, height: h/2)
        case .bottomHalf:
            rect = CGRect(x: 0, y: h/2, width: w, height: h/2)

        // Corners
        case .topLeft:
            rect = CGRect(x: 0, y: 0, width: w/2, height: h/2)
        case .topRight:
            rect = CGRect(x: w/2, y: 0, width: w/2, height: h/2)
        case .bottomLeft:
            rect = CGRect(x: 0, y: h/2, width: w/2, height: h/2)
        case .bottomRight:
            rect = CGRect(x: w/2, y: h/2, width: w/2, height: h/2)

        // Maximize variants
        case .maximize:
            rect = CGRect(x: 0, y: 0, width: w, height: h)
        case .almostMaximize:
            rect = CGRect(x: w*0.05, y: h*0.05, width: w*0.9, height: h*0.9)
        case .maximizeHeight:
            rect = CGRect(x: w/4, y: 0, width: w/2, height: h)

        // Size changes
        case .larger:
            rect = CGRect(x: w*0.1, y: h*0.1, width: w*0.8, height: h*0.8)
        case .smaller:
            rect = CGRect(x: w*0.25, y: h*0.25, width: w*0.5, height: h*0.5)

        // Center and restore
        case .center, .centerProminently:
            rect = CGRect(x: w*0.2, y: h*0.2, width: w*0.6, height: h*0.6)
        case .restore:
            rect = CGRect(x: w*0.15, y: h*0.15, width: w*0.7, height: h*0.7)

        // Display navigation
        case .nextDisplay:
            rect = CGRect(x: w*0.6, y: 0, width: w*0.4, height: h)
        case .previousDisplay:
            rect = CGRect(x: 0, y: 0, width: w*0.4, height: h)

        // Thirds
        case .firstThird:
            rect = CGRect(x: 0, y: 0, width: w/3, height: h)
        case .centerThird:
            rect = CGRect(x: w/3, y: 0, width: w/3, height: h)
        case .lastThird:
            rect = CGRect(x: w*2/3, y: 0, width: w/3, height: h)
        case .firstTwoThirds:
            rect = CGRect(x: 0, y: 0, width: w*2/3, height: h)
        case .centerTwoThirds:
            rect = CGRect(x: w/6, y: 0, width: w*2/3, height: h)
        case .lastTwoThirds:
            rect = CGRect(x: w/3, y: 0, width: w*2/3, height: h)

        // Movement
        case .moveLeft:
            rect = CGRect(x: 0, y: h*0.2, width: w*0.4, height: h*0.6)
        case .moveRight:
            rect = CGRect(x: w*0.6, y: h*0.2, width: w*0.4, height: h*0.6)
        case .moveUp:
            rect = CGRect(x: w*0.2, y: 0, width: w*0.6, height: h*0.4)
        case .moveDown:
            rect = CGRect(x: w*0.2, y: h*0.6, width: w*0.6, height: h*0.4)

        // Fourths
        case .firstFourth:
            rect = CGRect(x: 0, y: 0, width: w/4, height: h)
        case .secondFourth:
            rect = CGRect(x: w/4, y: 0, width: w/4, height: h)
        case .thirdFourth:
            rect = CGRect(x: w/2, y: 0, width: w/4, height: h)
        case .lastFourth:
            rect = CGRect(x: w*3/4, y: 0, width: w/4, height: h)
        case .firstThreeFourths:
            rect = CGRect(x: 0, y: 0, width: w*3/4, height: h)
        case .centerThreeFourths:
            rect = CGRect(x: w/8, y: 0, width: w*3/4, height: h)
        case .lastThreeFourths:
            rect = CGRect(x: w/4, y: 0, width: w*3/4, height: h)

        // Sixths
        case .topLeftSixth:
            rect = CGRect(x: 0, y: 0, width: w/3, height: h/2)
        case .topCenterSixth:
            rect = CGRect(x: w/3, y: 0, width: w/3, height: h/2)
        case .topRightSixth:
            rect = CGRect(x: w*2/3, y: 0, width: w/3, height: h/2)
        case .bottomLeftSixth:
            rect = CGRect(x: 0, y: h/2, width: w/3, height: h/2)
        case .bottomCenterSixth:
            rect = CGRect(x: w/3, y: h/2, width: w/3, height: h/2)
        case .bottomRightSixth:
            rect = CGRect(x: w*2/3, y: h/2, width: w/3, height: h/2)

        // Ninths
        case .topLeftNinth:
            rect = CGRect(x: 0, y: 0, width: w/3, height: h/3)
        case .topCenterNinth:
            rect = CGRect(x: w/3, y: 0, width: w/3, height: h/3)
        case .topRightNinth:
            rect = CGRect(x: w*2/3, y: 0, width: w/3, height: h/3)
        case .middleLeftNinth:
            rect = CGRect(x: 0, y: h/3, width: w/3, height: h/3)
        case .middleCenterNinth:
            rect = CGRect(x: w/3, y: h/3, width: w/3, height: h/3)
        case .middleRightNinth:
            rect = CGRect(x: w*2/3, y: h/3, width: w/3, height: h/3)
        case .bottomLeftNinth:
            rect = CGRect(x: 0, y: h*2/3, width: w/3, height: h/3)
        case .bottomCenterNinth:
            rect = CGRect(x: w/3, y: h*2/3, width: w/3, height: h/3)
        case .bottomRightNinth:
            rect = CGRect(x: w*2/3, y: h*2/3, width: w/3, height: h/3)

        // Eighths
        case .topLeftEighth:
            rect = CGRect(x: 0, y: 0, width: w/4, height: h/2)
        case .topCenterLeftEighth:
            rect = CGRect(x: w/4, y: 0, width: w/4, height: h/2)
        case .topCenterRightEighth:
            rect = CGRect(x: w/2, y: 0, width: w/4, height: h/2)
        case .topRightEighth:
            rect = CGRect(x: w*3/4, y: 0, width: w/4, height: h/2)
        case .bottomLeftEighth:
            rect = CGRect(x: 0, y: h/2, width: w/4, height: h/2)
        case .bottomCenterLeftEighth:
            rect = CGRect(x: w/4, y: h/2, width: w/4, height: h/2)
        case .bottomCenterRightEighth:
            rect = CGRect(x: w/2, y: h/2, width: w/4, height: h/2)
        case .bottomRightEighth:
            rect = CGRect(x: w*3/4, y: h/2, width: w/4, height: h/2)

        // Corner thirds
        case .topLeftThird:
            rect = CGRect(x: 0, y: 0, width: w*2/3, height: h*2/3)
        case .topRightThird:
            rect = CGRect(x: w/3, y: 0, width: w*2/3, height: h*2/3)
        case .bottomLeftThird:
            rect = CGRect(x: 0, y: h/3, width: w*2/3, height: h*2/3)
        case .bottomRightThird:
            rect = CGRect(x: w/3, y: h/3, width: w*2/3, height: h*2/3)

        // Default fallback
        default:
            rect = CGRect(x: w*0.2, y: h*0.2, width: w*0.6, height: h*0.6)
        }

        return Path(rect)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        TilePreview(action: .leftHalf)
            .frame(width: 40, height: 30)
        TilePreview(action: .topRight)
            .frame(width: 40, height: 30)
        TilePreview(action: .firstThird)
            .frame(width: 40, height: 30)
        TilePreview(action: .topLeftSixth)
            .frame(width: 40, height: 30)
    }
    .padding()
}
