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
import MASShortcut

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
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self))
    }

    /// Triggers this action as if it came from the menu bar
    func postMenu() {
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self, source: .menuItem))
    }

    /// Triggers this action from a drag-to-snap gesture
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

    /// Triggers this action from a URL scheme
    func postUrl() {
        NotificationCenter.default.post(name: notificationName, object: ExecutionParameters(self, source: .url))
    }

    /// Triggers this action from a title bar interaction
    func postTitleBar(windowElement: AccessibilityElement?) {
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
        // Using String(describing:) would be cleaner, but this explicit mapping
        // ensures stability if case names ever change
        switch self {
        case .leftHalf: return "leftHalf"
        case .rightHalf: return "rightHalf"
        case .maximize: return "maximize"
        case .maximizeHeight: return "maximizeHeight"
        case .previousDisplay: return "previousDisplay"
        case .nextDisplay: return "nextDisplay"
        case .larger: return "larger"
        case .smaller: return "smaller"
        case .bottomHalf: return "bottomHalf"
        case .topHalf: return "topHalf"
        case .center: return "center"
        case .bottomLeft: return "bottomLeft"
        case .bottomRight: return "bottomRight"
        case .topLeft: return "topLeft"
        case .topRight: return "topRight"
        case .restore: return "restore"
        case .firstThird: return "firstThird"
        case .firstTwoThirds: return "firstTwoThirds"
        case .centerThird: return "centerThird"
        case .centerTwoThirds: return "centerTwoThirds"
        case .lastTwoThirds: return "lastTwoThirds"
        case .lastThird: return "lastThird"
        case .moveLeft: return "moveLeft"
        case .moveRight: return "moveRight"
        case .moveUp: return "moveUp"
        case .moveDown: return "moveDown"
        case .almostMaximize: return "almostMaximize"
        case .centerHalf: return "centerHalf"
        case .firstFourth: return "firstFourth"
        case .secondFourth: return "secondFourth"
        case .thirdFourth: return "thirdFourth"
        case .lastFourth: return "lastFourth"
        case .firstThreeFourths: return "firstThreeFourths"
        case .centerThreeFourths: return "centerThreeFourths"
        case .lastThreeFourths: return "lastThreeFourths"
        case .topLeftSixth: return "topLeftSixth"
        case .topCenterSixth: return "topCenterSixth"
        case .topRightSixth: return "topRightSixth"
        case .bottomLeftSixth: return "bottomLeftSixth"
        case .bottomCenterSixth: return "bottomCenterSixth"
        case .bottomRightSixth: return "bottomRightSixth"
        case .specified: return "specified"
        case .reverseAll: return "reverseAll"
        case .topLeftNinth: return "topLeftNinth"
        case .topCenterNinth: return "topCenterNinth"
        case .topRightNinth: return "topRightNinth"
        case .middleLeftNinth: return "middleLeftNinth"
        case .middleCenterNinth: return "middleCenterNinth"
        case .middleRightNinth: return "middleRightNinth"
        case .bottomLeftNinth: return "bottomLeftNinth"
        case .bottomCenterNinth: return "bottomCenterNinth"
        case .bottomRightNinth: return "bottomRightNinth"
        case .topLeftThird: return "topLeftThird"
        case .topRightThird: return "topRightThird"
        case .bottomLeftThird: return "bottomLeftThird"
        case .bottomRightThird: return "bottomRightThird"
        case .topLeftEighth: return "topLeftEighth"
        case .topCenterLeftEighth: return "topCenterLeftEighth"
        case .topCenterRightEighth: return "topCenterRightEighth"
        case .topRightEighth: return "topRightEighth"
        case .bottomLeftEighth: return "bottomLeftEighth"
        case .bottomCenterLeftEighth: return "bottomCenterLeftEighth"
        case .bottomCenterRightEighth: return "bottomCenterRightEighth"
        case .bottomRightEighth: return "bottomRightEighth"
        case .doubleHeightUp: return "doubleHeightUp"
        case .doubleHeightDown: return "doubleHeightDown"
        case .doubleWidthLeft: return "doubleWidthLeft"
        case .doubleWidthRight: return "doubleWidthRight"
        case .halveHeightUp: return "halveHeightUp"
        case .halveHeightDown: return "halveHeightDown"
        case .halveWidthLeft: return "halveWidthLeft"
        case .halveWidthRight: return "halveWidthRight"
        case .tileAll: return "tileAll"
        case .cascadeAll: return "cascadeAll"
        case .leftTodo: return "leftTodo"
        case .rightTodo: return "rightTodo"
        case .cascadeActiveApp: return "cascadeActiveApp"
        case .centerProminently: return "centerProminently"
        case .largerWidth: return "largerWidth"
        case .smallerWidth: return "smallerWidth"
        case .largerHeight: return "largerHeight"
        case .smallerHeight: return "smallerHeight"
        }
    }

    // MARK: - Localization

    /// The human-readable name shown in the UI (localized).
    /// Returns nil for actions that don't appear in standard menus.
    /// The `key` is used to look up the localized string in Main.strings.
    var displayName: String? {
        var key: String
        var value: String

        switch self {
        case .leftHalf:
            key = "Xc8-Sm-pig.title"
            value = "Left Half"
        case .rightHalf:
            key = "F8S-GI-LiB.title"
            value = "Right Half"
        case .maximize:
            key = "8oe-J2-oUU.title"
            value = "Maximize"
        case .maximizeHeight:
            key = "6DV-cd-fda.title"
            value = "Maximize Height"
        case .previousDisplay:
            key = "QwF-QN-YH7.title"
            value = "Previous Display"
        case .nextDisplay:
            key = "Jnd-Lc-nlh.title"
            value = "Next Display"
        case .larger:
            key = "Eah-KL-kbn.title"
            value = "Larger"
        case .smaller:
            key = "MzN-CJ-ASD.title"
            value = "Smaller"
        case .bottomHalf:
            key = "ec4-FB-fMa.title"
            value = "Bottom Half"
        case .topHalf:
            key = "d7y-s8-7GE.title"
            value = "Top Half"
        case .center:
            key = "8Bg-SZ-hDO.title"
            value = "Center"
        case .bottomLeft:
            key = "6ma-hP-5xX.title"
            value = "Bottom Left"
        case .bottomRight:
            key = "J6t-sg-Wwz.title"
            value = "Bottom Right"
        case .topLeft:
            key = "adp-cN-qkh.title"
            value = "Top Left"
        case .topRight:
            key = "0Ak-33-SM7.title"
            value = "Top Right"
        case .restore:
            key = "C9v-g0-DH8.title"
            value = "Restore"
        case .firstThird:
            key = "F12-EV-Lfz.title"
            value = "First Third"
        case .firstTwoThirds:
            key = "3zd-xE-oWl.title"
            value = "First Two Thirds"
        case .centerThird:
            key = "7YK-9Z-lzw.title"
            value = "Center Third"
        case .centerTwoThirds:
            key = "oSu-n4-8Yu.title"
            value = "Center Two Thirds"
        case .lastTwoThirds:
            key = "08q-Ce-1QL.title"
            value = "Last Two Thirds"
        case .lastThird:
            key = "cRm-wn-Yv6.title"
            value = "Last Third"
        case .moveLeft:
            key = "v2f-bX-xiM.title"
            value = "Move Left"
        case .moveRight:
            key = "rzr-Qq-702.title"
            value = "Move Right"
        case .moveUp:
            key = "HOm-BV-2jc.title"
            value = "Move Up"
        case .moveDown:
            key = "1Rc-Od-eP5.title"
            value = "Move Down"
        case .almostMaximize:
            key = "e57-QJ-6bL.title"
            value = "Almost Maximize"
        case .centerHalf:
            key = "bRX-dV-iAR.title"
            value = "Center Half"
        case .firstFourth:
            key = "Q6Q-6J-okH.title"
            value = "First Fourth"
        case .secondFourth:
            key = "Fko-xs-gN5.title"
            value = "Second Fourth"
        case .thirdFourth:
            key = "ZTK-rS-b17.title"
            value = "Third Fourth"
        case .lastFourth:
            key = "6HX-rn-VIp.title"
            value = "Last Fourth"
        case .firstThreeFourths:
            key = "T9Z-QF-gwc.title"
            value = "First Three Fourths"
        case .centerThreeFourths:
            key = "Vph-Z0-euH.title"
            value = "Center Three Fourths"
        case .lastThreeFourths:
            key = "nwX-h6-fwm.title"
            value = "Last Three Fourths"
        case .topLeftSixth:
            key = "mFt-Kg-UYG.title"
            value = "Top Left Sixth"
        case .topCenterSixth:
            key = "TTx-7X-Wie.title"
            value = "Top Center Sixth"
        case .topRightSixth:
            key = "f3Q-q7-Pcy.title"
            value = "Top Right Sixth"
        case .bottomLeftSixth:
            key = "LqQ-pM-jRN.title"
            value = "Bottom Left Sixth"
        case .bottomCenterSixth:
            key = "iOQ-1e-esP.title"
            value = "Bottom Center Sixth"
        case .bottomRightSixth:
            key = "m2F-eA-g7w.title"
            value = "Bottom Right Sixth"
        case .topLeftNinth, .topCenterNinth, .topRightNinth, .middleLeftNinth, .middleCenterNinth, .middleRightNinth, .bottomLeftNinth, .bottomCenterNinth, .bottomRightNinth:
            return nil
        case .topLeftThird, .topRightThird, .bottomLeftThird, .bottomRightThird:
            return nil
        case .topLeftEighth, .topCenterLeftEighth, .topCenterRightEighth, .topRightEighth,
                .bottomLeftEighth, .bottomCenterLeftEighth, .bottomCenterRightEighth, .bottomRightEighth:
            return nil
        case .doubleHeightUp, .doubleHeightDown, .doubleWidthLeft, .doubleWidthRight, .halveHeightUp, .halveHeightDown, .halveWidthLeft, .halveWidthRight:
            return nil
        case .specified, .reverseAll, .tileAll, .cascadeAll, .leftTodo, .rightTodo, .cascadeActiveApp:
            return nil
        case .centerProminently, .largerWidth, .smallerWidth, .largerHeight, .smallerHeight:
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
        switch self {
        case .leftHalf: return NSImage(imageLiteralResourceName: "leftHalfTemplate")
        case .rightHalf: return NSImage(imageLiteralResourceName: "rightHalfTemplate")
        case .maximize: return NSImage(imageLiteralResourceName: "maximizeTemplate")
        case .maximizeHeight: return NSImage(imageLiteralResourceName: "maximizeHeightTemplate")
        case .previousDisplay: return NSImage(imageLiteralResourceName: "prevDisplayTemplate")
        case .nextDisplay: return NSImage(imageLiteralResourceName: "nextDisplayTemplate")
        case .larger: return NSImage(imageLiteralResourceName: "makeLargerTemplate")
        case .smaller: return NSImage(imageLiteralResourceName: "makeSmallerTemplate")
        case .bottomHalf: return NSImage(imageLiteralResourceName: "bottomHalfTemplate")
        case .topHalf: return NSImage(imageLiteralResourceName: "topHalfTemplate")
        case .center: return NSImage(imageLiteralResourceName: "centerTemplate")
        case .bottomLeft: return NSImage(imageLiteralResourceName: "bottomLeftTemplate")
        case .bottomRight: return NSImage(imageLiteralResourceName: "bottomRightTemplate")
        case .topLeft: return NSImage(imageLiteralResourceName: "topLeftTemplate")
        case .topRight: return NSImage(imageLiteralResourceName: "topRightTemplate")
        case .restore: return NSImage(imageLiteralResourceName: "restoreTemplate")
        case .firstThird: return NSImage(imageLiteralResourceName: "firstThirdTemplate")
        case .firstTwoThirds: return NSImage(imageLiteralResourceName: "firstTwoThirdsTemplate")
        case .centerThird: return NSImage(imageLiteralResourceName: "centerThirdTemplate")
        case .centerTwoThirds: return NSImage(imageLiteralResourceName: "centerTwoThirdsTemplate")
        case .lastTwoThirds: return NSImage(imageLiteralResourceName: "lastTwoThirdsTemplate")
        case .lastThird: return NSImage(imageLiteralResourceName: "lastThirdTemplate")
        case .moveLeft: return NSImage(imageLiteralResourceName: "moveLeftTemplate")
        case .moveRight: return NSImage(imageLiteralResourceName: "moveRightTemplate")
        case .moveUp: return NSImage(imageLiteralResourceName: "moveUpTemplate")
        case .moveDown: return NSImage(imageLiteralResourceName: "moveDownTemplate")
        case .almostMaximize: return NSImage(imageLiteralResourceName: "almostMaximizeTemplate")
        case .centerHalf: return NSImage(imageLiteralResourceName: "halfWidthCenterTemplate")
        case .firstFourth: return NSImage(imageLiteralResourceName: "leftFourthTemplate")
        case .secondFourth: return NSImage(imageLiteralResourceName: "centerLeftFourthTemplate")
        case .thirdFourth: return NSImage(imageLiteralResourceName: "centerRightFourthTemplate")
        case .lastFourth: return NSImage(imageLiteralResourceName: "rightFourthTemplate")
        case .firstThreeFourths: return NSImage(imageLiteralResourceName: "firstThreeFourthsTemplate")
        case .centerThreeFourths: return NSImage(imageLiteralResourceName: "centerThreeFourthsTemplate")
        case .lastThreeFourths: return NSImage(imageLiteralResourceName: "lastThreeFourthsTemplate")
        case .topLeftSixth: return NSImage(imageLiteralResourceName: "topLeftSixthTemplate")
        case .topCenterSixth: return NSImage(imageLiteralResourceName: "topCenterSixthTemplate")
        case .topRightSixth: return NSImage(imageLiteralResourceName: "topRightSixthTemplate")
        case .bottomLeftSixth: return NSImage(imageLiteralResourceName: "bottomLeftSixthTemplate")
        case .bottomCenterSixth: return NSImage(imageLiteralResourceName: "bottomCenterSixthTemplate")
        case .bottomRightSixth: return NSImage(imageLiteralResourceName: "bottomRightSixthTemplate")
        case .topLeftNinth: return NSImage()
        case .topCenterNinth: return NSImage()
        case .topRightNinth: return NSImage()
        case .middleLeftNinth: return NSImage()
        case .middleCenterNinth: return NSImage()
        case .middleRightNinth: return NSImage()
        case .bottomLeftNinth: return NSImage()
        case .bottomCenterNinth: return NSImage()
        case .bottomRightNinth: return NSImage()
        case .topLeftThird: return NSImage()
        case .topRightThird: return NSImage()
        case .bottomLeftThird: return NSImage()
        case .bottomRightThird: return NSImage()
        case .topLeftEighth: return  NSImage()
        case .topCenterLeftEighth: return  NSImage()
        case .topCenterRightEighth: return  NSImage()
        case .topRightEighth: return  NSImage()
        case .bottomLeftEighth: return  NSImage()
        case .bottomCenterLeftEighth: return  NSImage()
        case .bottomCenterRightEighth: return  NSImage()
        case .bottomRightEighth: return  NSImage()
        case .doubleHeightUp: return  NSImage()
        case .doubleHeightDown: return  NSImage()
        case .doubleWidthLeft: return  NSImage()
        case .doubleWidthRight: return  NSImage()
        case .halveHeightUp: return  NSImage()
        case .halveHeightDown: return  NSImage()
        case .halveWidthLeft: return  NSImage()
        case .halveWidthRight: return  NSImage()
        case .specified, .reverseAll: return NSImage()
        case .tileAll: return NSImage()
        case .cascadeAll: return NSImage()
        case .leftTodo: return NSImage()
        case .rightTodo: return NSImage()
        case .cascadeActiveApp: return NSImage()
        case .centerProminently: return NSImage()
        case .largerWidth: return NSImage(imageLiteralResourceName: "largerWidthTemplate")
        case .smallerWidth: return NSImage(imageLiteralResourceName: "smallerWidthTemplate")
        case .largerHeight: return NSImage()
        case .smallerHeight: return NSImage()
        }
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
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }

    /// Creates a shortcut from a MASShortcut object.
    /// Used when reading shortcuts from the MASShortcut framework.
    init(masShortcut: MASShortcut) {
        self.keyCode = masShortcut.keyCode
        self.modifierFlags = masShortcut.modifierFlags.rawValue
    }

    // MARK: - Conversion Methods

    /// Converts this shortcut to a MASShortcut for use with the MASShortcut framework.
    func toMASSHortcut() -> MASShortcut {
        MASShortcut(keyCode: keyCode, modifierFlags: NSEvent.ModifierFlags(rawValue: modifierFlags))
    }

    /// Returns a human-readable string like "⌃⌥←" for display in the UI.
    func displayString() -> String {
        let masShortcut = toMASSHortcut()
        return masShortcut.modifierFlagsString + (masShortcut.keyCodeString ?? "")
    }
}
