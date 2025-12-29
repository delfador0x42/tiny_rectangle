//
//  GridType.swift
//  tiny_window_manager
//
//

import Foundation

enum GridType {
    case ninths       // 3x3, no orientation swap
    case eighths      // 4x2 landscape, 2x4 portrait
    case cornerThirds // 2x2 with 2/3 size cells, swaps on orientation

    func columns(isLandscape: Bool) -> Int {
        switch self {
        case .ninths:
            return 3
        case .eighths:
            return isLandscape ? 4 : 2
        case .cornerThirds:
            return 2
        }
    }

    func rows(isLandscape: Bool) -> Int {
        switch self {
        case .ninths:
            return 3
        case .eighths:
            return isLandscape ? 2 : 4
        case .cornerThirds:
            return 2
        }
    }

    // For corner thirds, cells are 2/3 screen in major dimension
    var usesCustomCellSize: Bool {
        self == .cornerThirds
    }

    func cellWidth(screenWidth: CGFloat, isLandscape: Bool) -> CGFloat {
        switch self {
        case .ninths:
            return floor(screenWidth / 3.0)
        case .eighths:
            return floor(screenWidth / CGFloat(isLandscape ? 4 : 2))
        case .cornerThirds:
            return floor(screenWidth * (isLandscape ? 2.0/3.0 : 1.0/2.0))
        }
    }

    func cellHeight(screenHeight: CGFloat, isLandscape: Bool) -> CGFloat {
        switch self {
        case .ninths:
            return floor(screenHeight / 3.0)
        case .eighths:
            return floor(screenHeight / CGFloat(isLandscape ? 2 : 4))
        case .cornerThirds:
            return floor(screenHeight * (isLandscape ? 1.0/2.0 : 2.0/3.0))
        }
    }
}
