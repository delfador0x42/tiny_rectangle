//
//  PrefsViewController.swift
//  tiny_window_manager
//
//  This file manages the Preferences window where users configure keyboard shortcuts.
//  Each window action (left half, maximize, etc.) has a corresponding shortcut view
//  where users can record their preferred key combination.
//
//  The MASShortcut framework handles the actual keyboard shortcut recording and storage.
//

import Cocoa
import MASShortcut
import ServiceManagement

// MARK: - PrefsViewController Class

/// The view controller for the keyboard shortcuts preferences panel.
///
/// This controller:
/// - Connects storyboard shortcut views to their corresponding window actions
/// - Persists shortcuts to UserDefaults via MASShortcut
/// - Handles the "Show More" toggle for additional shortcuts
/// - Supports "Allow Any Shortcut" mode to bypass system shortcut validation
///
/// ## How shortcuts are saved:
/// Each `MASShortcutView` is linked to UserDefaults using the action's name as the key.
/// When the user records a shortcut, MASShortcut automatically saves it.
class PrefsViewController: NSViewController {

    // MARK: - Properties

    /// Maps each window action to its corresponding shortcut view in the UI.
    /// This dictionary is built in `awakeFromNib()` and used to:
    /// - Bind shortcuts to UserDefaults
    /// - Apply validators to all shortcut views at once
    var actionsToViews = [WindowAction: MASShortcutView]()

    // MARK: - Shortcut View Outlets (Halves)

    /// Shortcut for moving window to left half of screen
    @IBOutlet weak var leftHalfShortcutView: MASShortcutView!
    /// Shortcut for moving window to right half of screen
    @IBOutlet weak var rightHalfShortcutView: MASShortcutView!
    /// Shortcut for moving window to center half of screen
    @IBOutlet weak var centerHalfShortcutView: MASShortcutView!
    /// Shortcut for moving window to top half of screen
    @IBOutlet weak var topHalfShortcutView: MASShortcutView!
    /// Shortcut for moving window to bottom half of screen
    @IBOutlet weak var bottomHalfShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Corners)

    /// Shortcut for moving window to top-left corner
    @IBOutlet weak var topLeftShortcutView: MASShortcutView!
    /// Shortcut for moving window to top-right corner
    @IBOutlet weak var topRightShortcutView: MASShortcutView!
    /// Shortcut for moving window to bottom-left corner
    @IBOutlet weak var bottomLeftShortcutView: MASShortcutView!
    /// Shortcut for moving window to bottom-right corner
    @IBOutlet weak var bottomRightShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Display)

    /// Shortcut for moving window to next display/monitor
    @IBOutlet weak var nextDisplayShortcutView: MASShortcutView!
    /// Shortcut for moving window to previous display/monitor
    @IBOutlet weak var previousDisplayShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Size)

    /// Shortcut for making window larger
    @IBOutlet weak var makeLargerShortcutView: MASShortcutView!
    /// Shortcut for making window smaller
    @IBOutlet weak var makeSmallerShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Maximize & Other)

    /// Shortcut for maximizing window to full screen
    @IBOutlet weak var maximizeShortcutView: MASShortcutView!
    /// Shortcut for almost-maximize (leaves small margin)
    @IBOutlet weak var almostMaximizeShortcutView: MASShortcutView!
    /// Shortcut for maximizing window height only
    @IBOutlet weak var maximizeHeightShortcutView: MASShortcutView!
    /// Shortcut for centering window on screen
    @IBOutlet weak var centerShortcutView: MASShortcutView!
    /// Shortcut for restoring window to previous position
    @IBOutlet weak var restoreShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Thirds) - Additional Section

    /// Shortcut for first third of screen
    @IBOutlet weak var firstThirdShortcutView: MASShortcutView!
    /// Shortcut for first two-thirds of screen
    @IBOutlet weak var firstTwoThirdsShortcutView: MASShortcutView!
    /// Shortcut for center third of screen
    @IBOutlet weak var centerThirdShortcutView: MASShortcutView!
    /// Shortcut for center two-thirds of screen
    @IBOutlet weak var centerTwoThirdsShortcutView: MASShortcutView!
    /// Shortcut for last two-thirds of screen
    @IBOutlet weak var lastTwoThirdsShortcutView: MASShortcutView!
    /// Shortcut for last third of screen
    @IBOutlet weak var lastThirdShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Move) - Additional Section

    /// Shortcut for moving window left (without resizing)
    @IBOutlet weak var moveLeftShortcutView: MASShortcutView!
    /// Shortcut for moving window right (without resizing)
    @IBOutlet weak var moveRightShortcutView: MASShortcutView!
    /// Shortcut for moving window up (without resizing)
    @IBOutlet weak var moveUpShortcutView: MASShortcutView!
    /// Shortcut for moving window down (without resizing)
    @IBOutlet weak var moveDownShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Fourths) - Additional Section

    /// Shortcut for first fourth of screen
    @IBOutlet weak var firstFourthShortcutView: MASShortcutView!
    /// Shortcut for second fourth of screen
    @IBOutlet weak var secondFourthShortcutView: MASShortcutView!
    /// Shortcut for third fourth of screen
    @IBOutlet weak var thirdFourthShortcutView: MASShortcutView!
    /// Shortcut for last fourth of screen
    @IBOutlet weak var lastFourthShortcutView: MASShortcutView!
    /// Shortcut for first three-fourths of screen
    @IBOutlet weak var firstThreeFourthsShortcutView: MASShortcutView!
    /// Shortcut for center three-fourths of screen
    @IBOutlet weak var centerThreeFourthsShortcutView: MASShortcutView!
    /// Shortcut for last three-fourths of screen
    @IBOutlet weak var lastThreeFourthsShortcutView: MASShortcutView!

    // MARK: - Shortcut View Outlets (Sixths) - Additional Section

    /// Shortcut for top-left sixth of screen
    @IBOutlet weak var topLeftSixthShortcutView: MASShortcutView!
    /// Shortcut for top-center sixth of screen
    @IBOutlet weak var topCenterSixthShortcutView: MASShortcutView!
    /// Shortcut for top-right sixth of screen
    @IBOutlet weak var topRightSixthShortcutView: MASShortcutView!
    /// Shortcut for bottom-left sixth of screen
    @IBOutlet weak var bottomLeftSixthShortcutView: MASShortcutView!
    /// Shortcut for bottom-center sixth of screen
    @IBOutlet weak var bottomCenterSixthShortcutView: MASShortcutView!
    /// Shortcut for bottom-right sixth of screen
    @IBOutlet weak var bottomRightSixthShortcutView: MASShortcutView!

    // MARK: - UI Control Outlets

    /// Button that toggles visibility of additional shortcuts section
    @IBOutlet weak var showMoreButton: NSButton!
    /// Stack view containing less common shortcuts (hidden by default)
    @IBOutlet weak var additionalShortcutsStackView: NSStackView!

    // MARK: - Lifecycle

    /// Called after the view is loaded from the storyboard.
    /// Sets up the mapping between actions and views, binds shortcuts to UserDefaults,
    /// and configures initial UI state.
    override func awakeFromNib() {
        print(#function, "called")
        // STEP 1: Build the action-to-view mapping
        // This lets us iterate over all shortcuts programmatically
        actionsToViews = [
            // Halves
            .leftHalf: leftHalfShortcutView,
            .rightHalf: rightHalfShortcutView,
            .centerHalf: centerHalfShortcutView,
            .topHalf: topHalfShortcutView,
            .bottomHalf: bottomHalfShortcutView,
            // Corners
            .topLeft: topLeftShortcutView,
            .topRight: topRightShortcutView,
            .bottomLeft: bottomLeftShortcutView,
            .bottomRight: bottomRightShortcutView,
            // Display
            .nextDisplay: nextDisplayShortcutView,
            .previousDisplay: previousDisplayShortcutView,
            // Maximize & Other
            .maximize: maximizeShortcutView,
            .almostMaximize: almostMaximizeShortcutView,
            .maximizeHeight: maximizeHeightShortcutView,
            .center: centerShortcutView,
            .restore: restoreShortcutView,
            // Size
            .larger: makeLargerShortcutView,
            .smaller: makeSmallerShortcutView,
            // Thirds
            .firstThird: firstThirdShortcutView,
            .firstTwoThirds: firstTwoThirdsShortcutView,
            .centerThird: centerThirdShortcutView,
            .centerTwoThirds: centerTwoThirdsShortcutView,
            .lastTwoThirds: lastTwoThirdsShortcutView,
            .lastThird: lastThirdShortcutView,
            // Move
            .moveLeft: moveLeftShortcutView,
            .moveRight: moveRightShortcutView,
            .moveUp: moveUpShortcutView,
            .moveDown: moveDownShortcutView,
            // Fourths
            .firstFourth: firstFourthShortcutView,
            .secondFourth: secondFourthShortcutView,
            .thirdFourth: thirdFourthShortcutView,
            .lastFourth: lastFourthShortcutView,
            .firstThreeFourths: firstThreeFourthsShortcutView,
            .centerThreeFourths: centerThreeFourthsShortcutView,
            .lastThreeFourths: lastThreeFourthsShortcutView,
            // Sixths
            .topLeftSixth: topLeftSixthShortcutView,
            .topCenterSixth: topCenterSixthShortcutView,
            .topRightSixth: topRightSixthShortcutView,
            .bottomLeftSixth: bottomLeftSixthShortcutView,
            .bottomCenterSixth: bottomCenterSixthShortcutView,
            .bottomRightSixth: bottomRightSixthShortcutView
        ]

        // STEP 2: Bind each shortcut view to UserDefaults
        // The action's name becomes the UserDefaults key (e.g., "leftHalf")
        // MASShortcut uses a dictionary transformer to serialize the shortcut
        for (action, view) in actionsToViews {
            view.setAssociatedUserDefaultsKey(action.name, withTransformerName: MASDictionaryTransformerName)
        }

        // STEP 3: Apply permissive validator if "Allow Any Shortcut" is enabled
        // This lets users assign shortcuts that would normally conflict with system shortcuts
        if Defaults.allowAnyShortcut.enabled {
            let passThroughValidator = PassthroughShortcutValidator()
            actionsToViews.values.forEach { $0.shortcutValidator = passThroughValidator }
        }

        // STEP 4: Listen for changes to the "Allow Any Shortcut" setting
        subscribeToAllowAnyShortcutToggle()

        // STEP 5: Hide additional shortcuts section by default (user can expand)
        additionalShortcutsStackView.isHidden = true
    }

    // MARK: - Actions

    /// Toggles the visibility of the additional shortcuts section.
    ///
    /// - Parameter sender: The "Show More" button that was clicked
    @IBAction func toggleShowMore(_ sender: NSButton) {
        print(#function, "called")
        // Toggle visibility
        additionalShortcutsStackView.isHidden = !additionalShortcutsStackView.isHidden

        // Update button appearance to indicate state
        // "▶︎ ⋯" = collapsed (click to expand), "▼" = expanded (click to collapse)
        showMoreButton.title = additionalShortcutsStackView.isHidden
            ? "▶︎ ⋯" : "▼"
    }

    // MARK: - Private Methods

    /// Listens for changes to the "Allow Any Shortcut" setting and updates validators.
    ///
    /// When the user toggles this setting in preferences:
    /// - Enabled: Uses `PassthroughShortcutValidator` (accepts any shortcut)
    /// - Disabled: Uses default `MASShortcutValidator` (blocks system shortcuts)
    private func subscribeToAllowAnyShortcutToggle() {
        print(#function, "called")
        Notification.Name.allowAnyShortcut.onPost { notification in
            guard let enabled = notification.object as? Bool else { return }

            // Choose the appropriate validator based on the setting
            let validator = enabled ? PassthroughShortcutValidator() : MASShortcutValidator()

            // Apply to all shortcut views
            self.actionsToViews.values.forEach { $0.shortcutValidator = validator }
        }
    }
}

// MARK: - PassthroughShortcutValidator Class

/// A permissive shortcut validator that accepts any keyboard shortcut.
///
/// By default, `MASShortcutValidator` prevents users from assigning shortcuts that:
/// - Are already used by the system (e.g., Cmd+Q, Cmd+W)
/// - Conflict with the app's menu bar shortcuts
///
/// This subclass overrides all validation to return "valid" / "not taken",
/// allowing power users to assign any shortcut they want.
///
/// ## Why would someone want this?
/// Some users prefer to use shortcuts that conflict with system defaults,
/// especially if they've remapped those system shortcuts elsewhere.
class PassthroughShortcutValidator: MASShortcutValidator {

    /// Always returns true - any shortcut is considered valid.
    override func isShortcutValid(_ shortcut: MASShortcut!) -> Bool {
        print(#function, "called")
        return true
    }

    /// Always returns false - pretends no shortcut is taken by the system.
    override func isShortcutAlreadyTaken(bySystem shortcut: MASShortcut!, explanation: AutoreleasingUnsafeMutablePointer<NSString?>!) -> Bool {
        print(#function, "called")
        return false
    }

    /// Always returns false - pretends no shortcut conflicts with app menus.
    override func isShortcut(_ shortcut: MASShortcut!, alreadyTakenIn menu: NSMenu!, explanation: AutoreleasingUnsafeMutablePointer<NSString?>!) -> Bool {
        print(#function, "called")
        return false
    }
}
