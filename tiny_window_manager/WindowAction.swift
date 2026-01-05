//
//  WindowAction.swift
//  tiny_window_manager
//
//  AppKit-specific extensions for WindowActionType.
//  The core enum is defined in WindowManagerCore package.
//

import Foundation
import Carbon
import Cocoa
import WindowManagerCore

// MARK: - Type Alias

/// WindowAction is an alias for WindowActionType from WindowManagerCore.
/// All pure logic (cases, gaps, cycling, etc.) lives in the package.
/// This file adds AppKit-specific extensions (images, shortcuts, notifications).
typealias WindowAction = WindowActionType

// MARK: - Keyboard Modifier Constants

/// Keyboard modifier flag shortcuts for defining shortcuts.
fileprivate let alt = NSEvent.ModifierFlags.option.rawValue
fileprivate let ctrl = NSEvent.ModifierFlags.control.rawValue
fileprivate let shift = NSEvent.ModifierFlags.shift.rawValue
fileprivate let cmd = NSEvent.ModifierFlags.command.rawValue

// MARK: - AppKit Extensions

extension WindowAction {

    // MARK: - Triggering Actions

    /// Triggers this action via a notification (default source: keyboard shortcut).
    func post() {
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self))
    }

    /// Triggers this action as if it came from the menu bar.
    func postMenu() {
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self, source: .menuItem))
    }

    /// Triggers this action from a drag-to-snap gesture.
    func postSnap(windowElement: AccessibilityElement?, windowId: CGWindowID?, screen: NSScreen) {
        NotificationCenter.default.post(
            name: notificationName,
            object: ExecutionParameters(
                self,
                updateRestoreRect: false,
                screen: screen,
                windowElement: windowElement,
                windowId: windowId,
                source: .dragToSnap
            )
        )
    }

    /// Triggers this action from a URL scheme.
    func postUrl() {
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self, source: .url))
    }

    /// Triggers this action from a title bar interaction.
    func postTitleBar(windowElement: AccessibilityElement?) {
        NotificationCenter.default.post(
            name: notificationName,
            object: ExecutionParameters(self, windowElement: windowElement, source: .titleBar)
        )
    }

    // MARK: - Notification

    /// The notification name used to trigger this action.
    var notificationName: Notification.Name {
        Notification.Name(name)
    }

    // MARK: - Display Properties

    /// The human-readable name shown in the UI (derived from case name).
    var displayName: String? {
        // Actions without display names
        switch self {
        case .largerWidth, .smallerWidth, .largerHeight, .smallerHeight,
             .specified, .reverseAll, .tileAll, .cascadeAll, .cascadeActiveApp,
             .leftTodo, .rightTodo, .centerProminently,
             .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
             .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
             .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth,
             .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight,
             .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight:
            return nil
        default:
            return name.camelCaseToWords
        }
    }

    /// The icon image for this action (derived from case name with overrides).
    var image: NSImage {
        let imageName = Self.imageNameOverrides[self] ?? "\(name)Template"
        return NSImage(imageLiteralResourceName: imageName)
    }

    /// Image name overrides for actions that don't follow the standard pattern.
    private static let imageNameOverrides: [WindowAction: String] = [
        .centerHalf: "halfWidthCenterTemplate",
        .firstFourth: "leftFourthTemplate",
        .secondFourth: "centerLeftFourthTemplate",
        .thirdFourth: "centerRightFourthTemplate",
        .lastFourth: "rightFourthTemplate",
        .larger: "makeLargerTemplate",
        .smaller: "makeSmallerTemplate",
        .previousDisplay: "prevDisplayTemplate",
    ]

    // MARK: - Default Keyboard Shortcuts

    /// Default shortcut using Spectacle-style keybindings (Cmd+Option based).
    var spectacleDefault: Shortcut? {
        switch self {
        case .leftHalf: return Shortcut(cmd|alt, kVK_LeftArrow)
        case .rightHalf: return Shortcut(cmd|alt, kVK_RightArrow)
        case .maximize: return Shortcut(cmd|alt, kVK_ANSI_F)
        case .maximizeHeight: return Shortcut(ctrl|alt|shift, kVK_UpArrow)
        case .previousDisplay: return Shortcut(ctrl|alt|cmd, kVK_LeftArrow)
        case .nextDisplay: return Shortcut(ctrl|alt|cmd, kVK_RightArrow)
        case .larger: return Shortcut(ctrl|alt|shift, kVK_RightArrow)
        case .smaller: return Shortcut(ctrl|alt|shift, kVK_LeftArrow)
        case .bottomHalf: return Shortcut(cmd|alt, kVK_DownArrow)
        case .topHalf: return Shortcut(cmd|alt, kVK_UpArrow)
        case .center: return Shortcut(alt|cmd, kVK_ANSI_C)
        case .bottomLeft: return Shortcut(cmd|ctrl|shift, kVK_LeftArrow)
        case .bottomRight: return Shortcut(cmd|ctrl|shift, kVK_RightArrow)
        case .topLeft: return Shortcut(ctrl|cmd, kVK_LeftArrow)
        case .topRight: return Shortcut(ctrl|cmd, kVK_RightArrow)
        case .restore: return Shortcut(ctrl|alt, kVK_Delete)
        default: return nil
        }
    }

    /// Default shortcut using an alternative keybinding scheme (Ctrl+Option based).
    var alternateDefault: Shortcut? {
        switch self {
        case .leftHalf: return Shortcut(ctrl|alt, kVK_LeftArrow)
        case .rightHalf: return Shortcut(ctrl|alt, kVK_RightArrow)
        case .bottomHalf: return Shortcut(ctrl|alt, kVK_DownArrow)
        case .topHalf: return Shortcut(ctrl|alt, kVK_UpArrow)
        case .bottomLeft: return Shortcut(ctrl|alt, kVK_ANSI_J)
        case .bottomRight: return Shortcut(ctrl|alt, kVK_ANSI_K)
        case .topLeft: return Shortcut(ctrl|alt, kVK_ANSI_U)
        case .topRight: return Shortcut(ctrl|alt, kVK_ANSI_I)
        case .maximize: return Shortcut(ctrl|alt, kVK_Return)
        case .maximizeHeight: return Shortcut(ctrl|alt|shift, kVK_UpArrow)
        case .previousDisplay: return Shortcut(ctrl|alt|cmd, kVK_LeftArrow)
        case .nextDisplay: return Shortcut(ctrl|alt|cmd, kVK_RightArrow)
        case .larger: return Shortcut(ctrl|alt, kVK_ANSI_Equal)
        case .smaller: return Shortcut(ctrl|alt, kVK_ANSI_Minus)
        case .center: return Shortcut(ctrl|alt, kVK_ANSI_C)
        case .restore: return Shortcut(ctrl|alt, kVK_Delete)
        case .firstThird: return Shortcut(ctrl|alt, kVK_ANSI_D)
        case .firstTwoThirds: return Shortcut(ctrl|alt, kVK_ANSI_E)
        case .centerThird: return Shortcut(ctrl|alt, kVK_ANSI_F)
        case .lastTwoThirds: return Shortcut(ctrl|alt, kVK_ANSI_T)
        case .lastThird: return Shortcut(ctrl|alt, kVK_ANSI_G)
        case .centerTwoThirds:
            if let installVersion = Defaults.installVersion.value,
               let intInstallVersion = Int(installVersion),
               intInstallVersion > 94 {
                return Shortcut(ctrl|alt, kVK_ANSI_R)
            }
            return nil
        default: return nil
        }
    }

    // MARK: - Behavior Properties (App-Specific)

    /// Whether this action changes the window's size (uses app Defaults).
    var resizes: Bool {
        switch self {
        case .center, .centerProminently, .nextDisplay, .previousDisplay:
            return false
        case .moveUp, .moveDown, .moveLeft, .moveRight:
            return Defaults.resizeOnDirectionalMove.enabled
        default:
            return true
        }
    }

    /// Gap shared edge using app Defaults.
    var gapSharedEdge: Edge {
        switch self {
        case .leftHalf: return .right
        case .rightHalf: return .left
        case .bottomHalf: return .top
        case .topHalf: return .bottom
        case .bottomLeft: return [.top, .right]
        case .bottomRight: return [.top, .left]
        case .topLeft: return [.bottom, .right]
        case .topRight: return [.bottom, .left]
        case .moveUp: return Defaults.resizeOnDirectionalMove.enabled ? .bottom : .none
        case .moveDown: return Defaults.resizeOnDirectionalMove.enabled ? .top : .none
        case .moveLeft: return Defaults.resizeOnDirectionalMove.enabled ? .right : .none
        case .moveRight: return Defaults.resizeOnDirectionalMove.enabled ? .left : .none
        default: return .none
        }
    }

    /// Gaps applicable using app Defaults.
    var gapsApplicable: Dimension {
        switch self {
        case .leftHalf, .rightHalf, .bottomHalf, .topHalf, .centerHalf,
             .bottomLeft, .bottomRight, .topLeft, .topRight,
             .firstThird, .firstTwoThirds, .centerThird, .centerTwoThirds, .lastTwoThirds, .lastThird,
             .firstFourth, .secondFourth, .thirdFourth, .lastFourth,
             .firstThreeFourths, .centerThreeFourths, .lastThreeFourths,
             .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth,
             .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
             .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
             .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth,
             .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight,
             .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight,
             .leftTodo, .rightTodo:
            return .both
        case .moveUp, .moveDown:
            return Defaults.resizeOnDirectionalMove.enabled ? .vertical : .none
        case .moveLeft, .moveRight:
            return Defaults.resizeOnDirectionalMove.enabled ? .horizontal : .none
        case .maximize:
            return Defaults.applyGapsToMaximize.userDisabled ? .none : .both
        case .maximizeHeight:
            return Defaults.applyGapsToMaximizeHeight.userDisabled ? .none : .vertical
        case .almostMaximize, .previousDisplay, .nextDisplay,
             .larger, .smaller, .largerWidth, .smallerWidth, .largerHeight, .smallerHeight,
             .center, .centerProminently, .restore,
             .specified, .reverseAll, .tileAll, .cascadeAll, .cascadeActiveApp:
            return .none
        }
    }

    // MARK: - Window Calculation

    /// Returns the appropriate window calculation for this action.
    @MainActor
    var calculation: WindowCalculation? {
        switch self {
        case .nextDisplay, .previousDisplay:
            return NextPrevDisplayCalculation.shared
        case .specified:
            return SpecifiedCalculation.shared
        case .restore, .tileAll, .cascadeAll, .cascadeActiveApp, .reverseAll:
            return nil
        default:
            return SimpleCalculation.shared
        }
    }

    /// Whether this action can extend outside the current screen area (e.g., for multi-display moves).
    var allowedToExtendOutsideCurrentScreenArea: Bool {
        switch self {
        case .nextDisplay, .previousDisplay:
            return true
        default:
            return false
        }
    }
}
