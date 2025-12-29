//
//  GridCycling.swift
//  tiny_window_manager
//
//

import Foundation

struct GridCycling {

    // Cycling order for ninths (direction: .right)
    private static let ninthsOrder: [SubWindowAction] = [
        .topLeftNinth, .topCenterNinth, .topRightNinth,
        .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
        .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth
    ]

    // Cycling order for eighths (direction: .right)
    private static let eighthsOrder: [SubWindowAction] = [
        .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
        .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth
    ]

    // Cycling order for corner thirds (direction: .right)
    private static let cornerThirdsOrder: [SubWindowAction] = [
        .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird
    ]

    static func nextCalculation(for gridType: GridType, currentSubAction: SubWindowAction, direction: Direction) -> SimpleCalc? {
        let order: [SubWindowAction]
        let calculationGetter: (SubWindowAction) -> SimpleCalc?

        switch gridType {
        case .ninths:
            order = ninthsOrder
            calculationGetter = { getNinthCalculation(for: $0) }
        case .eighths:
            order = eighthsOrder
            calculationGetter = { getEighthCalculation(for: $0) }
        case .cornerThirds:
            order = cornerThirdsOrder
            calculationGetter = { getCornerThirdCalculation(for: $0) }
        }

        guard let currentIndex = order.firstIndex(of: currentSubAction) else {
            return nil
        }

        let nextIndex: Int
        switch direction {
        case .right:
            nextIndex = (currentIndex + 1) % order.count
        case .left:
            nextIndex = (currentIndex - 1 + order.count) % order.count
        }

        return calculationGetter(order[nextIndex])
    }

    private static func getNinthCalculation(for subAction: SubWindowAction) -> SimpleCalc? {
        switch subAction {
        case .topLeftNinth:
            return WindowCalculationFactory.topLeftNinthCalculation.orientationBasedRect
        case .topCenterNinth:
            return WindowCalculationFactory.topCenterNinthCalculation.orientationBasedRect
        case .topRightNinth:
            return WindowCalculationFactory.topRightNinthCalculation.orientationBasedRect
        case .middleLeftNinth:
            return WindowCalculationFactory.middleLeftNinthCalculation.orientationBasedRect
        case .middleCenterNinth:
            return WindowCalculationFactory.middleCenterNinthCalculation.orientationBasedRect
        case .middleRightNinth:
            return WindowCalculationFactory.middleRightNinthCalculation.orientationBasedRect
        case .bottomLeftNinth:
            return WindowCalculationFactory.bottomLeftNinthCalculation.orientationBasedRect
        case .bottomCenterNinth:
            return WindowCalculationFactory.bottomCenterNinthCalculation.orientationBasedRect
        case .bottomRightNinth:
            return WindowCalculationFactory.bottomRightNinthCalculation.orientationBasedRect
        default:
            return nil
        }
    }

    private static func getEighthCalculation(for subAction: SubWindowAction) -> SimpleCalc? {
        switch subAction {
        case .topLeftEighth:
            return WindowCalculationFactory.topLeftEighthCalculation.orientationBasedRect
        case .topCenterLeftEighth:
            return WindowCalculationFactory.topCenterLeftEighthCalculation.orientationBasedRect
        case .topCenterRightEighth:
            return WindowCalculationFactory.topCenterRightEighthCalculation.orientationBasedRect
        case .topRightEighth:
            return WindowCalculationFactory.topRightEighthCalculation.orientationBasedRect
        case .bottomLeftEighth:
            return WindowCalculationFactory.bottomLeftEighthCalculation.orientationBasedRect
        case .bottomCenterLeftEighth:
            return WindowCalculationFactory.bottomCenterLeftEighthCalculation.orientationBasedRect
        case .bottomCenterRightEighth:
            return WindowCalculationFactory.bottomCenterRightEighthCalculation.orientationBasedRect
        case .bottomRightEighth:
            return WindowCalculationFactory.bottomRightEighthCalculation.orientationBasedRect
        default:
            return nil
        }
    }

    private static func getCornerThirdCalculation(for subAction: SubWindowAction) -> SimpleCalc? {
        switch subAction {
        case .topLeftThird:
            return WindowCalculationFactory.topLeftThirdCalculation.orientationBasedRect
        case .topRightThird:
            return WindowCalculationFactory.topRightThirdCalculation.orientationBasedRect
        case .bottomLeftThird:
            return WindowCalculationFactory.bottomLeftThirdCalculation.orientationBasedRect
        case .bottomRightThird:
            return WindowCalculationFactory.bottomRightThirdCalculation.orientationBasedRect
        default:
            return nil
        }
    }
}
