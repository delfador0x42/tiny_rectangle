//
//  WindowAction.swift
//  tiny_window_manager
//
//  This file defines all the window positioning actions the app can perform.
//  Each action (like "left half", "maximize", "top right corner") is represented
//  as an enum case with associated properties for display, shortcuts, and behavior.
//

import Foundation
import Carbon
import Cocoa

// MARK: - Keyboard Modifier Constants

/// These are the raw values for keyboard modifier keys.
/// They can be combined with the bitwise OR operator (|) to create shortcuts.
/// Example: ctrl|alt creates a shortcut requiring both Control and Option keys.
fileprivate let alt = NSEvent.ModifierFlags.option.rawValue    // Option/Alt key (⌥)
fileprivate let ctrl = NSEvent.ModifierFlags.control.rawValue  // Control key (⌃)
fileprivate let shift = NSEvent.ModifierFlags.shift.rawValue   // Shift key (⇧)
fileprivate let cmd = NSEvent.ModifierFlags.command.rawValue   // Command key (⌘)

// MARK: - WindowAction Enum

/// Represents all possible window positioning/sizing actions.
/// Each case has a unique integer ID (rawValue) used for persistence and identification.
/// The IDs are not sequential because some were deprecated or reserved.
enum WindowAction: Int, Codable {

    // MARK: Basic Halves (split screen into 2 parts)
    case leftHalf = 0
    case rightHalf = 1
    case bottomHalf = 10
    case topHalf = 11
    case centerHalf = 30  // Half-width, centered horizontally

    // MARK: Corners (split screen into 4 quarters)
    case topLeft = 15
    case topRight = 16
    case bottomLeft = 13
    case bottomRight = 14

    // MARK: Thirds (split screen into 3 parts)
    case firstThird = 20
    case centerThird = 22
    case lastThird = 24
    case firstTwoThirds = 21
    case centerTwoThirds = 84
    case lastTwoThirds = 23

    // MARK: Fourths (split screen into 4 parts)
    case firstFourth = 31
    case secondFourth = 32
    case thirdFourth = 33
    case lastFourth = 34
    case firstThreeFourths = 35
    case centerThreeFourths = 85
    case lastThreeFourths = 36

    // MARK: Sixths (2 rows × 3 columns)
    case topLeftSixth = 37
    case topCenterSixth = 38
    case topRightSixth = 39
    case bottomLeftSixth = 40
    case bottomCenterSixth = 41
    case bottomRightSixth = 42

    // MARK: Ninths (3 rows × 3 columns)
    case topLeftNinth = 45
    case topCenterNinth = 46
    case topRightNinth = 47
    case middleLeftNinth = 48
    case middleCenterNinth = 49
    case middleRightNinth = 50
    case bottomLeftNinth = 51
    case bottomCenterNinth = 52
    case bottomRightNinth = 53

    // MARK: Corner Thirds (2×2 grid, each cell is 1/3 screen)
    case topLeftThird = 54
    case topRightThird = 55
    case bottomLeftThird = 56
    case bottomRightThird = 57

    // MARK: Eighths (2 rows × 4 columns)
    case topLeftEighth = 58
    case topCenterLeftEighth = 59
    case topCenterRightEighth = 60
    case topRightEighth = 61
    case bottomLeftEighth = 62
    case bottomCenterLeftEighth = 63
    case bottomCenterRightEighth = 64
    case bottomRightEighth = 65

    // MARK: Maximize & Size Actions
    case maximize = 2
    case almostMaximize = 29       // Maximize with small margins
    case maximizeHeight = 3        // Full height, keep current width
    case larger = 8                // Grow window
    case smaller = 9               // Shrink window
    case largerWidth = 80
    case smallerWidth = 81
    case largerHeight = 82
    case smallerHeight = 83

    // MARK: Resize by Doubling/Halving
    case doubleHeightUp = 72       // Double height, anchor at bottom
    case doubleHeightDown = 73     // Double height, anchor at top
    case doubleWidthLeft = 74      // Double width, anchor at right
    case doubleWidthRight = 75     // Double width, anchor at left
    case halveHeightUp = 76        // Halve height, keep top
    case halveHeightDown = 77      // Halve height, keep bottom
    case halveWidthLeft = 78       // Halve width, keep left
    case halveWidthRight = 79      // Halve width, keep right

    // MARK: Centering & Positioning
    case center = 12               // Center without resizing
    case centerProminently = 71    // Center with a specific size
    case restore = 19              // Restore to previous size/position

    // MARK: Display Navigation
    case previousDisplay = 4       // Move window to previous monitor
    case nextDisplay = 5           // Move window to next monitor

    // MARK: Movement (no resize)
    case moveLeft = 25
    case moveRight = 26
    case moveUp = 27
    case moveDown = 28

    // MARK: Multi-Window Actions
    case tileAll = 66              // Tile all windows on screen
    case cascadeAll = 67           // Cascade all windows
    case cascadeActiveApp = 70     // Cascade windows of active app only
    case reverseAll = 44           // Reverse all window positions

    // MARK: Special/Custom
    case specified = 43            // Custom user-specified position
    case leftTodo = 68             // Custom todo layout (left)
    case rightTodo = 69            // Custom todo layout (right)

    // MARK: - Action Metadata

    /// Metadata for display properties (displayName, image).
    /// Consolidates multiple switch statements into a single dictionary lookup.
    private struct ActionMetadata {
        let displayKey: String?      // Localization key (nil = no display name)
        let displayValue: String?    // Default localized value
        let imageName: String?       // Image asset name (nil = empty NSImage)

        init(displayKey: String? = nil, displayValue: String? = nil, imageName: String? = nil) {
            self.displayKey = displayKey
            self.displayValue = displayValue
            self.imageName = imageName
        }
    }

    /// Metadata dictionary for all actions with display properties.
    /// Actions not in this dictionary use defaults (no displayName, empty image).
    private static let metadata: [WindowAction: ActionMetadata] = [
        // Halves
        .leftHalf: ActionMetadata(displayKey: "Xc8-Sm-pig.title", displayValue: "Left Half", imageName: "leftHalfTemplate"),
        .rightHalf: ActionMetadata(displayKey: "F8S-GI-LiB.title", displayValue: "Right Half", imageName: "rightHalfTemplate"),
        .centerHalf: ActionMetadata(displayKey: "bRX-dV-iAR.title", displayValue: "Center Half", imageName: "halfWidthCenterTemplate"),
        .topHalf: ActionMetadata(displayKey: "d7y-s8-7GE.title", displayValue: "Top Half", imageName: "topHalfTemplate"),
        .bottomHalf: ActionMetadata(displayKey: "ec4-FB-fMa.title", displayValue: "Bottom Half", imageName: "bottomHalfTemplate"),

        // Corners
        .topLeft: ActionMetadata(displayKey: "adp-cN-qkh.title", displayValue: "Top Left", imageName: "topLeftTemplate"),
        .topRight: ActionMetadata(displayKey: "0Ak-33-SM7.title", displayValue: "Top Right", imageName: "topRightTemplate"),
        .bottomLeft: ActionMetadata(displayKey: "6ma-hP-5xX.title", displayValue: "Bottom Left", imageName: "bottomLeftTemplate"),
        .bottomRight: ActionMetadata(displayKey: "J6t-sg-Wwz.title", displayValue: "Bottom Right", imageName: "bottomRightTemplate"),

        // Thirds
        .firstThird: ActionMetadata(displayKey: "F12-EV-Lfz.title", displayValue: "First Third", imageName: "firstThirdTemplate"),
        .centerThird: ActionMetadata(displayKey: "7YK-9Z-lzw.title", displayValue: "Center Third", imageName: "centerThirdTemplate"),
        .lastThird: ActionMetadata(displayKey: "cRm-wn-Yv6.title", displayValue: "Last Third", imageName: "lastThirdTemplate"),
        .firstTwoThirds: ActionMetadata(displayKey: "3zd-xE-oWl.title", displayValue: "First Two Thirds", imageName: "firstTwoThirdsTemplate"),
        .centerTwoThirds: ActionMetadata(displayKey: "oSu-n4-8Yu.title", displayValue: "Center Two Thirds", imageName: "centerTwoThirdsTemplate"),
        .lastTwoThirds: ActionMetadata(displayKey: "08q-Ce-1QL.title", displayValue: "Last Two Thirds", imageName: "lastTwoThirdsTemplate"),

        // Fourths
        .firstFourth: ActionMetadata(displayKey: "Q6Q-6J-okH.title", displayValue: "First Fourth", imageName: "leftFourthTemplate"),
        .secondFourth: ActionMetadata(displayKey: "Fko-xs-gN5.title", displayValue: "Second Fourth", imageName: "centerLeftFourthTemplate"),
        .thirdFourth: ActionMetadata(displayKey: "ZTK-rS-b17.title", displayValue: "Third Fourth", imageName: "centerRightFourthTemplate"),
        .lastFourth: ActionMetadata(displayKey: "6HX-rn-VIp.title", displayValue: "Last Fourth", imageName: "rightFourthTemplate"),
        .firstThreeFourths: ActionMetadata(displayKey: "T9Z-QF-gwc.title", displayValue: "First Three Fourths", imageName: "firstThreeFourthsTemplate"),
        .centerThreeFourths: ActionMetadata(displayKey: "Vph-Z0-euH.title", displayValue: "Center Three Fourths", imageName: "centerThreeFourthsTemplate"),
        .lastThreeFourths: ActionMetadata(displayKey: "nwX-h6-fwm.title", displayValue: "Last Three Fourths", imageName: "lastThreeFourthsTemplate"),

        // Sixths
        .topLeftSixth: ActionMetadata(displayKey: "mFt-Kg-UYG.title", displayValue: "Top Left Sixth", imageName: "topLeftSixthTemplate"),
        .topCenterSixth: ActionMetadata(displayKey: "TTx-7X-Wie.title", displayValue: "Top Center Sixth", imageName: "topCenterSixthTemplate"),
        .topRightSixth: ActionMetadata(displayKey: "f3Q-q7-Pcy.title", displayValue: "Top Right Sixth", imageName: "topRightSixthTemplate"),
        .bottomLeftSixth: ActionMetadata(displayKey: "LqQ-pM-jRN.title", displayValue: "Bottom Left Sixth", imageName: "bottomLeftSixthTemplate"),
        .bottomCenterSixth: ActionMetadata(displayKey: "iOQ-1e-esP.title", displayValue: "Bottom Center Sixth", imageName: "bottomCenterSixthTemplate"),
        .bottomRightSixth: ActionMetadata(displayKey: "m2F-eA-g7w.title", displayValue: "Bottom Right Sixth", imageName: "bottomRightSixthTemplate"),

        // Maximize & Size Actions
        .maximize: ActionMetadata(displayKey: "8oe-J2-oUU.title", displayValue: "Maximize", imageName: "maximizeTemplate"),
        .almostMaximize: ActionMetadata(displayKey: "e57-QJ-6bL.title", displayValue: "Almost Maximize", imageName: "almostMaximizeTemplate"),
        .maximizeHeight: ActionMetadata(displayKey: "6DV-cd-fda.title", displayValue: "Maximize Height", imageName: "maximizeHeightTemplate"),
        .larger: ActionMetadata(displayKey: "Eah-KL-kbn.title", displayValue: "Larger", imageName: "makeLargerTemplate"),
        .smaller: ActionMetadata(displayKey: "MzN-CJ-ASD.title", displayValue: "Smaller", imageName: "makeSmallerTemplate"),
        .largerWidth: ActionMetadata(imageName: "largerWidthTemplate"),
        .smallerWidth: ActionMetadata(imageName: "smallerWidthTemplate"),

        // Centering & Positioning
        .center: ActionMetadata(displayKey: "8Bg-SZ-hDO.title", displayValue: "Center", imageName: "centerTemplate"),
        .restore: ActionMetadata(displayKey: "C9v-g0-DH8.title", displayValue: "Restore", imageName: "restoreTemplate"),

        // Display Navigation
        .previousDisplay: ActionMetadata(displayKey: "QwF-QN-YH7.title", displayValue: "Previous Display", imageName: "prevDisplayTemplate"),
        .nextDisplay: ActionMetadata(displayKey: "Jnd-Lc-nlh.title", displayValue: "Next Display", imageName: "nextDisplayTemplate"),

        // Movement
        .moveLeft: ActionMetadata(displayKey: "v2f-bX-xiM.title", displayValue: "Move Left", imageName: "moveLeftTemplate"),
        .moveRight: ActionMetadata(displayKey: "rzr-Qq-702.title", displayValue: "Move Right", imageName: "moveRightTemplate"),
        .moveUp: ActionMetadata(displayKey: "HOm-BV-2jc.title", displayValue: "Move Up", imageName: "moveUpTemplate"),
        .moveDown: ActionMetadata(displayKey: "1Rc-Od-eP5.title", displayValue: "Move Down", imageName: "moveDownTemplate"),
    ]

    // MARK: - Active Actions List

    /// All actions that appear in the menu, in display order.
    /// The order here determines the order in dropdown menus.
    static let active: [WindowAction] = [
        // Halves
        leftHalf, rightHalf, centerHalf, topHalf, bottomHalf,
        // Corners
        topLeft, topRight, bottomLeft, bottomRight,
        // Thirds
        firstThird, centerThird, lastThird, firstTwoThirds, centerTwoThirds, lastTwoThirds,
        // Size actions
        maximize, almostMaximize, maximizeHeight, larger, smaller, largerWidth, smallerWidth, largerHeight, smallerHeight,
        // Positioning
        center, centerProminently, restore,
        // Display navigation
        nextDisplay, previousDisplay,
        // Movement
        moveLeft, moveRight, moveUp, moveDown,
        // Fourths
        firstFourth, secondFourth, thirdFourth, lastFourth, firstThreeFourths, centerThreeFourths, lastThreeFourths,
        // Sixths
        topLeftSixth, topCenterSixth, topRightSixth, bottomLeftSixth, bottomCenterSixth, bottomRightSixth,
        // Special
        specified, reverseAll,
        // Ninths
        topLeftNinth, topCenterNinth, topRightNinth,
        middleLeftNinth, middleCenterNinth, middleRightNinth,
        bottomLeftNinth, bottomCenterNinth, bottomRightNinth,
        // Corner thirds
        topLeftThird, topRightThird, bottomLeftThird, bottomRightThird,
        // Eighths
        topLeftEighth, topCenterLeftEighth, topCenterRightEighth, topRightEighth,
        bottomLeftEighth, bottomCenterLeftEighth, bottomCenterRightEighth, bottomRightEighth,
        // Resize by doubling/halving
        doubleHeightUp, doubleHeightDown, doubleWidthLeft, doubleWidthRight,
        halveHeightUp, halveHeightDown, halveWidthLeft, halveWidthRight,
        // Multi-window
        tileAll, cascadeAll,
        leftTodo, rightTodo,
        cascadeActiveApp
    ]

    // MARK: - Triggering Actions

    /// Triggers this action via a notification (default source: keyboard shortcut)
    func post() {
        print(#function, "called")
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self))
    }

    /// Triggers this action as if it came from the menu bar
    func postMenu() {
        print(#function, "called")
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self, source: .menuItem))
    }

    /// Triggers this action from a drag-to-snap gesture
    func postSnap(windowElement: AccessibilityElement?, windowId: CGWindowID?, screen: NSScreen) {
        print(#function, "called")
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

    /// Triggers this action from a URL scheme
    func postUrl() {
        print(#function, "called")
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self, source: .url))
    }

    /// Triggers this action from a title bar interaction
    func postTitleBar(windowElement: AccessibilityElement?) {
        print(#function, "called")
        NotificationCenter.default.post(
            name: notificationName,
            object: ExecutionParameters(self, windowElement: windowElement, source: .titleBar)
        )
    }

    // MARK: - Menu Display Properties

    /// Returns true if this action should have a separator above it in the menu.
    /// This groups related actions together visually.
    var firstInGroup: Bool {
        switch self {
        case .leftHalf, .topLeft, .firstThird, .maximize, .nextDisplay, .moveLeft, .firstFourth, .topLeftSixth:
            return true
        default:
            return false
        }
    }

    /// A string identifier for this action.
    /// Used for notifications and as a unique key.
    var name: String {
        String(describing: self)
    }

    // MARK: - Localization

    /// The human-readable name shown in the UI (localized).
    /// Returns nil for actions that don't appear in standard menus.
    var displayName: String? {
        guard let meta = Self.metadata[self],
              let key = meta.displayKey,
              let value = meta.displayValue else {
            return nil
        }
        return NSLocalizedString(key, tableName: "Main", value: value, comment: "")
    }

    /// The notification name used to trigger this action.
    /// Based on the `name` property.
    var notificationName: Notification.Name {
        return Notification.Name(name)
    }

    // MARK: - Behavior Properties

    /// Whether this action changes the window's size.
    /// Some actions only move the window (center, move to display).
    var resizes: Bool {
        switch self {
        // These actions only move, never resize
        case .center, .centerProminently, .nextDisplay, .previousDisplay:
            return false
        // Directional moves optionally resize based on user preference
        case .moveUp, .moveDown, .moveLeft, .moveRight:
            return Defaults.resizeOnDirectionalMove.enabled
        // All other actions resize the window
        default:
            return true
        }
    }

    /// Whether this action can position windows partially outside the screen.
    /// Only the "double size" actions allow this (they expand in one direction).
    var allowedToExtendOutsideCurrentScreenArea: Bool {
        switch self {
        case .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight:
            return true
        default:
            return false
        }
    }

    /// Whether this action can be triggered by dragging a window to a screen edge.
    /// Some actions (like restore, resize, multi-window) don't make sense as snap targets.
    var isDragSnappable: Bool {
        switch self {
        // These actions can't be triggered by dragging to screen edges
        case .restore, .previousDisplay, .nextDisplay,
             .moveUp, .moveDown, .moveLeft, .moveRight,
             .specified, .reverseAll, .tileAll, .cascadeAll,
             .larger, .smaller, .largerWidth, .smallerWidth, .cascadeActiveApp,
             // Ninths (too many zones, not practical for snapping)
             .topLeftNinth, .topCenterNinth, .topRightNinth,
             .middleLeftNinth, .middleCenterNinth, .middleRightNinth,
             .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
             // Corner thirds
             .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
             // Eighths (too many zones)
             .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
             .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return false
        // All other actions can be snap targets
        default:
            return true
        }
    }

    // MARK: - Default Keyboard Shortcuts

    /// Default shortcut using Spectacle-style keybindings (Cmd+Option based).
    var spectacleDefault: Shortcut? {
        switch self {
        case .leftHalf: return Shortcut( cmd|alt, kVK_LeftArrow )
        case .rightHalf: return Shortcut( cmd|alt, kVK_RightArrow )
        case .maximize: return Shortcut( cmd|alt, kVK_ANSI_F )
        case .maximizeHeight: return Shortcut( ctrl|alt|shift, kVK_UpArrow )
        case .previousDisplay: return Shortcut( ctrl|alt|cmd, kVK_LeftArrow )
        case .nextDisplay:  return Shortcut( ctrl|alt|cmd, kVK_RightArrow )
        case .larger: return Shortcut( ctrl|alt|shift, kVK_RightArrow )
        case .smaller: return Shortcut( ctrl|alt|shift, kVK_LeftArrow )
        case .bottomHalf: return Shortcut( cmd|alt, kVK_DownArrow )
        case .topHalf: return Shortcut( cmd|alt, kVK_UpArrow )
        case .center: return Shortcut( alt|cmd, kVK_ANSI_C )
        case .bottomLeft: return Shortcut( cmd|ctrl|shift, kVK_LeftArrow )
        case .bottomRight: return Shortcut( cmd|ctrl|shift, kVK_RightArrow )
        case .topLeft: return Shortcut( ctrl|cmd, kVK_LeftArrow )
        case .topRight: return Shortcut( ctrl|cmd, kVK_RightArrow )
        case .restore: return Shortcut( ctrl|alt, kVK_Delete)
        default: return nil
        }
    }

    /// Default shortcut using an alternative keybinding scheme (Ctrl+Option based).
    /// This provides a different set of defaults for users who prefer this style.
    var alternateDefault: Shortcut? {
        switch self {
        case .leftHalf: return Shortcut( ctrl|alt, kVK_LeftArrow )
        case .rightHalf: return Shortcut( ctrl|alt, kVK_RightArrow )
        case .bottomHalf: return Shortcut( ctrl|alt, kVK_DownArrow )
        case .topHalf: return Shortcut( ctrl|alt, kVK_UpArrow )
        case .bottomLeft: return Shortcut( ctrl|alt, kVK_ANSI_J )
        case .bottomRight: return Shortcut( ctrl|alt, kVK_ANSI_K )
        case .topLeft: return Shortcut( ctrl|alt, kVK_ANSI_U )
        case .topRight: return Shortcut( ctrl|alt, kVK_ANSI_I )
        case .maximize: return Shortcut( ctrl|alt, kVK_Return )
        case .maximizeHeight: return Shortcut( ctrl|alt|shift, kVK_UpArrow )
        case .previousDisplay: return Shortcut( ctrl|alt|cmd, kVK_LeftArrow )
        case .nextDisplay: return Shortcut( ctrl|alt|cmd, kVK_RightArrow )
        case .larger: return Shortcut( ctrl|alt, kVK_ANSI_Equal )
        case .smaller: return Shortcut( ctrl|alt, kVK_ANSI_Minus )
        case .center: return Shortcut( ctrl|alt, kVK_ANSI_C )
        case .restore: return Shortcut( ctrl|alt, kVK_Delete)
        case .firstThird: return Shortcut( ctrl|alt, kVK_ANSI_D )
        case .firstTwoThirds: return Shortcut( ctrl|alt, kVK_ANSI_E )
        case .centerThird: return Shortcut( ctrl|alt, kVK_ANSI_F )
        case .lastTwoThirds: return Shortcut( ctrl|alt, kVK_ANSI_T )
        case .lastThird: return Shortcut( ctrl|alt, kVK_ANSI_G )
        case .centerTwoThirds:
            if let installVersion = Defaults.installVersion.value,
               let intInstallVersion = Int(installVersion),
               intInstallVersion > 94 {
                return Shortcut( ctrl|alt, kVK_ANSI_R )
            }
            return nil
        default: return nil
        }
    }

    // MARK: - Visual Assets

    /// The icon image for this action, used in menus and UI.
    /// Returns an empty NSImage for actions without dedicated icons.
    /// Template images (ending in "Template") adapt to light/dark mode automatically.
    var image: NSImage {
        guard let imageName = Self.metadata[self]?.imageName else {
            return NSImage()
        }
        return NSImage(imageLiteralResourceName: imageName)
    }

    // MARK: - Gap/Margin Properties

    /// Which edges of this window position are "shared" with adjacent windows.
    /// Used for applying window gaps - shared edges get half the gap size
    /// so adjacent windows end up with a full gap between them.
    ///
    /// For example, leftHalf shares its right edge with rightHalf,
    /// so both get half the gap on that edge.
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
        default:
            return .none
        }
    }

    /// Which dimensions (horizontal, vertical, both, or none) should have gaps applied.
    /// Controls whether window margins/padding are added for this action.
    var gapsApplicable: Dimension {
        switch self {
        case .leftHalf, .rightHalf, .bottomHalf, .topHalf, .centerHalf, .bottomLeft, .bottomRight, .topLeft, .topRight, .firstThird, .firstTwoThirds, .centerThird, .centerTwoThirds, .lastTwoThirds, .lastThird,
                .firstFourth, .secondFourth, .thirdFourth, .lastFourth, .firstThreeFourths, .centerThreeFourths, .lastThreeFourths, .topLeftSixth, .topCenterSixth, .topRightSixth, .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth,
            .topLeftNinth, .topCenterNinth, .topRightNinth, .middleLeftNinth, .middleCenterNinth, .middleRightNinth, .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth,
            .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird,
            .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
            .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth,
		 	.doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight,
		 	.halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight,
            .leftTodo, .rightTodo:
            return .both
        case .moveUp, .moveDown:
            return Defaults.resizeOnDirectionalMove.enabled ? .vertical : .none;
        case .moveLeft, .moveRight:
            return Defaults.resizeOnDirectionalMove.enabled ? .horizontal : .none;
        case .maximize:
            return Defaults.applyGapsToMaximize.userDisabled ? .none : .both;
        case .maximizeHeight:
            return Defaults.applyGapsToMaximizeHeight.userDisabled ? .none : .vertical;
        // These actions don't use gaps
        case .almostMaximize, .previousDisplay, .nextDisplay,
             .larger, .smaller, .largerWidth, .smallerWidth, .largerHeight, .smallerHeight,
             .center, .centerProminently, .restore,
             .specified, .reverseAll, .tileAll, .cascadeAll, .cascadeActiveApp:
            return .none
        }
    }

    // MARK: - Menu Organization

    /// The submenu category for this action, if it belongs in a submenu.
    /// Returns nil if the action should appear in the main menu.
    var category: WindowActionCategory? {
        switch self {
        case .firstFourth, .secondFourth, .thirdFourth, .lastFourth,
             .firstThreeFourths, .centerThreeFourths, .lastThreeFourths:
            return .fourths
        case .topLeftSixth, .topCenterSixth, .topRightSixth,
             .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth:
            return .sixths
        case .moveUp, .moveDown, .moveLeft, .moveRight:
            return .move
        default:
            return nil
        }
    }

    /// A broader classification of the action type, used for grouping in settings.
    /// Different from `category` - this is about what kind of action it is,
    /// not where it appears in menus.
    var classification: WindowActionCategory? {
        switch self {
        case .firstThird, .firstTwoThirds, .centerThird, .centerTwoThirds, .lastTwoThirds, .lastThird:
            return .thirds
        case .smaller, .larger, .smallerWidth, .largerWidth, .smallerHeight, .largerHeight:
            return .size
        case .previousDisplay, .nextDisplay:
            return .display
        default:
            return nil
        }
    }

    // MARK: - Window Calculation

    /// Returns the appropriate window calculation for this action.
    /// Some actions (restore, tileAll, etc.) handle their own logic and return nil.
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
}

// MARK: - SubWindowAction Enum

/// Represents window positions used internally for calculations.
/// This is more granular than WindowAction - it includes orientation-specific
/// variants (landscape vs portrait) for sixths, etc.
///
/// Used primarily for calculating exact window rectangles and gap edges.
enum SubWindowAction {

    // MARK: Vertical Thirds (left to right)
    case leftThird
    case centerVerticalThird
    case rightThird
    case leftTwoThirds
    case rightTwoThirds

    // MARK: Horizontal Thirds (top to bottom)
    case topThird
    case centerHorizontalThird
    case bottomThird
    case topTwoThirds
    case bottomTwoThirds

    // MARK: Vertical Fourths (left to right)
    case leftFourth
    case centerLeftFourth
    case centerRightFourth
    case rightFourth

    // MARK: Horizontal Fourths (top to bottom)
    case topFourth
    case centerTopFourth
    case centerBottomFourth
    case bottomFourth

    // MARK: Three-Fourths Variations
    case rightThreeFourths
    case bottomThreeFourths
    case leftThreeFourths
    case topThreeFourths
    case centerVerticalThreeFourths
    case centerHorizontalThreeFourths

    // MARK: Centered Halves
    case centerVerticalHalf
    case centerHorizontalHalf

    // MARK: Sixths - Landscape (2 rows × 3 columns)
    case topLeftSixthLandscape
    case topCenterSixthLandscape
    case topRightSixthLandscape
    case bottomLeftSixthLandscape
    case bottomCenterSixthLandscape
    case bottomRightSixthLandscape

    // MARK: Sixths - Portrait (3 rows × 2 columns)
    case topLeftSixthPortrait
    case topRightSixthPortrait
    case leftCenterSixthPortrait
    case rightCenterSixthPortrait
    case bottomLeftSixthPortrait
    case bottomRightSixthPortrait

    // MARK: Two-Sixths Combinations
    case topLeftTwoSixthsLandscape
    case topLeftTwoSixthsPortrait
    case topRightTwoSixthsLandscape
    case topRightTwoSixthsPortrait
    case bottomLeftTwoSixthsLandscape
    case bottomLeftTwoSixthsPortrait
    case bottomRightTwoSixthsLandscape
    case bottomRightTwoSixthsPortrait

    // MARK: Ninths (3×3 grid)
    case topLeftNinth
    case topCenterNinth
    case topRightNinth
    case middleLeftNinth
    case middleCenterNinth
    case middleRightNinth
    case bottomLeftNinth
    case bottomCenterNinth
    case bottomRightNinth

    // MARK: Corner Thirds
    case topLeftThird
    case topRightThird
    case bottomLeftThird
    case bottomRightThird

    // MARK: Eighths (2×4 grid)
    case topLeftEighth
    case topCenterLeftEighth
    case topCenterRightEighth
    case topRightEighth
    case bottomLeftEighth
    case bottomCenterLeftEighth
    case bottomCenterRightEighth
    case bottomRightEighth

    // MARK: Special
    case maximize
    case leftTodo
    case rightTodo

    // MARK: - Properties

    /// Which edges are shared with adjacent windows for gap calculations.
    /// See WindowAction.gapSharedEdge for detailed explanation.
    var gapSharedEdge: Edge {
        switch self {
        case .leftThird: return .right
        case .centerVerticalThird: return [.right, .left]
        case .rightThird: return .left
        case .leftTwoThirds: return .right
        case .rightTwoThirds: return .left
        case .topThird: return .bottom
        case .centerHorizontalThird: return [.top, .bottom]
        case .bottomThird: return .top
        case .topTwoThirds: return .bottom
        case .bottomTwoThirds: return .top
        case .leftFourth: return .right
        case .centerLeftFourth: return [.right, .left]
        case .centerRightFourth: return [.right, .left]
        case .rightFourth: return .left
        case .topFourth: return .bottom
        case .centerTopFourth: return [.top, .bottom]
        case .centerBottomFourth: return [.top, .bottom]
        case .bottomFourth: return .top
        case .rightThreeFourths: return .left
        case .bottomThreeFourths: return .top
        case .leftThreeFourths: return .right
        case .topThreeFourths: return .bottom
        case .centerVerticalThreeFourths: return [.right, .left]
        case .centerHorizontalThreeFourths: return [.top, .bottom]
        case .centerVerticalHalf: return [.right, .left]
        case .centerHorizontalHalf: return [.top, .bottom]
        case .topLeftSixthLandscape: return [.right, .bottom]
        case .topCenterSixthLandscape: return [.right, .left, .bottom]
        case .topRightSixthLandscape: return [.left, .bottom]
        case .bottomLeftSixthLandscape: return [.top, .right]
        case .bottomCenterSixthLandscape: return [.left, .right, .top]
        case .bottomRightSixthLandscape: return [.left, .top]
        case .topLeftSixthPortrait: return [.right, .bottom]
        case .topRightSixthPortrait: return [.left, .bottom]
        case .leftCenterSixthPortrait: return [.top, .bottom, .right]
        case .rightCenterSixthPortrait: return [.left, .top, .bottom]
        case .bottomLeftSixthPortrait: return [.top, .right]
        case .bottomRightSixthPortrait: return [.left, .top]
        case .topLeftTwoSixthsLandscape: return [.right, .bottom]
        case .topLeftTwoSixthsPortrait: return [.right, .bottom]
        case .topRightTwoSixthsLandscape: return [.left, .bottom]
        case .topRightTwoSixthsPortrait: return [.left, .bottom]
        case .bottomLeftTwoSixthsLandscape: return [.right, .top]
        case .bottomLeftTwoSixthsPortrait: return [.right, .top]
        case .bottomRightTwoSixthsLandscape: return [.left, .top]
        case .bottomRightTwoSixthsPortrait: return [.left, .top]
        case .topLeftNinth: return [.right, .bottom]
        case .topCenterNinth: return [.right, .left, .bottom]
        case .topRightNinth: return [.left, .bottom]
        case .middleLeftNinth: return [.top, .right, .bottom]
        case .middleCenterNinth: return [.top, .right, .bottom, .left]
        case .middleRightNinth: return [.left, .top, .bottom]
        case .bottomLeftNinth: return [.top, .right]
        case .bottomCenterNinth: return [.left, .top, .right]
        case .bottomRightNinth: return [.left, .top]
        case .topLeftThird: return [.right, .bottom]
        case .topRightThird: return [.left, .bottom]
        case .bottomLeftThird: return [.right, .top]
        case .bottomRightThird: return [.left, .top]
        case .topLeftEighth: return  [.right, .bottom]
        case .topCenterLeftEighth: return  [.right, .left, .bottom]
        case .topCenterRightEighth: return  [.right, .left, .bottom]
        case .topRightEighth: return  [.left, .bottom]
        case .bottomLeftEighth: return  [.right, .top]
        case .bottomCenterLeftEighth: return  [.right, .left, .top]
        case .bottomCenterRightEighth: return  [.right, .left, .top]
        case .bottomRightEighth: return  [.left, .top]
        case .maximize: return .none
        case .leftTodo: return .right
        case .rightTodo: return .left
        }
    }
}

// MARK: - Shortcut Struct

/// Represents a keyboard shortcut (key + modifiers like Cmd, Ctrl, etc.)
/// Used to define and store keyboard shortcuts for window actions.
///
/// Example usage:
/// ```swift
/// // Create a shortcut for Ctrl+Option+Left Arrow
/// let shortcut = Shortcut(ctrl|alt, kVK_LeftArrow)
/// ```
struct Shortcut: Codable {

    /// The virtual key code (from Carbon/Events.h).
    /// Examples: kVK_LeftArrow, kVK_ANSI_F, kVK_Return
    let keyCode: Int

    /// Bitmask of modifier keys (Cmd, Ctrl, Option, Shift).
    /// Use the file-level constants: cmd, ctrl, alt, shift
    /// Combine with bitwise OR: ctrl|alt
    let modifierFlags: UInt

    // MARK: - Initializers

    /// Creates a shortcut from modifier flags and key code.
    /// - Parameters:
    ///   - modifierFlags: Bitmask of modifiers (e.g., ctrl|alt)
    ///   - keyCode: The virtual key code (e.g., kVK_LeftArrow)
    init(_ modifierFlags: UInt, _ keyCode: Int) {
        print(#function, "called")
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }
}
