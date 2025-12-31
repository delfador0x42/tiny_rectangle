//
//  PrefsViewController.swift
//  tiny_window_manager
//
//  This file manages the Preferences window where users configure keyboard shortcuts.
//  NOTE: This is legacy storyboard-based UI. Consider using PreferencesView.swift (SwiftUI) instead.
//

import Cocoa
import SwiftUI
import ServiceManagement
import KeyboardShortcuts

// MARK: - PrefsViewController Class

/// The view controller for the keyboard shortcuts preferences panel.
///
/// NOTE: This is a legacy storyboard-based controller. The outlets connect to
/// container views in the storyboard that are replaced at runtime with
/// KeyboardShortcuts.Recorder views wrapped in NSHostingView.
class PrefsViewController: NSViewController {

    // MARK: - Properties

    /// Maps each window action to its corresponding container view in the UI.
    var actionsToContainers = [WindowAction: NSView]()

    // MARK: - Shortcut View Outlets (Halves)

    @IBOutlet weak var leftHalfShortcutView: NSView!
    @IBOutlet weak var rightHalfShortcutView: NSView!
    @IBOutlet weak var centerHalfShortcutView: NSView!
    @IBOutlet weak var topHalfShortcutView: NSView!
    @IBOutlet weak var bottomHalfShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Corners)

    @IBOutlet weak var topLeftShortcutView: NSView!
    @IBOutlet weak var topRightShortcutView: NSView!
    @IBOutlet weak var bottomLeftShortcutView: NSView!
    @IBOutlet weak var bottomRightShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Display)

    @IBOutlet weak var nextDisplayShortcutView: NSView!
    @IBOutlet weak var previousDisplayShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Size)

    @IBOutlet weak var makeLargerShortcutView: NSView!
    @IBOutlet weak var makeSmallerShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Maximize & Other)

    @IBOutlet weak var maximizeShortcutView: NSView!
    @IBOutlet weak var almostMaximizeShortcutView: NSView!
    @IBOutlet weak var maximizeHeightShortcutView: NSView!
    @IBOutlet weak var centerShortcutView: NSView!
    @IBOutlet weak var restoreShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Thirds)

    @IBOutlet weak var firstThirdShortcutView: NSView!
    @IBOutlet weak var firstTwoThirdsShortcutView: NSView!
    @IBOutlet weak var centerThirdShortcutView: NSView!
    @IBOutlet weak var centerTwoThirdsShortcutView: NSView!
    @IBOutlet weak var lastTwoThirdsShortcutView: NSView!
    @IBOutlet weak var lastThirdShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Move)

    @IBOutlet weak var moveLeftShortcutView: NSView!
    @IBOutlet weak var moveRightShortcutView: NSView!
    @IBOutlet weak var moveUpShortcutView: NSView!
    @IBOutlet weak var moveDownShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Fourths)

    @IBOutlet weak var firstFourthShortcutView: NSView!
    @IBOutlet weak var secondFourthShortcutView: NSView!
    @IBOutlet weak var thirdFourthShortcutView: NSView!
    @IBOutlet weak var lastFourthShortcutView: NSView!
    @IBOutlet weak var firstThreeFourthsShortcutView: NSView!
    @IBOutlet weak var centerThreeFourthsShortcutView: NSView!
    @IBOutlet weak var lastThreeFourthsShortcutView: NSView!

    // MARK: - Shortcut View Outlets (Sixths)

    @IBOutlet weak var topLeftSixthShortcutView: NSView!
    @IBOutlet weak var topCenterSixthShortcutView: NSView!
    @IBOutlet weak var topRightSixthShortcutView: NSView!
    @IBOutlet weak var bottomLeftSixthShortcutView: NSView!
    @IBOutlet weak var bottomCenterSixthShortcutView: NSView!
    @IBOutlet weak var bottomRightSixthShortcutView: NSView!

    // MARK: - UI Control Outlets

    @IBOutlet weak var showMoreButton: NSButton!
    @IBOutlet weak var additionalShortcutsStackView: NSStackView!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        print(#function, "called")

        // Build the action-to-container mapping
        actionsToContainers = [
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

        // Replace each container with a KeyboardShortcuts.Recorder
        for (action, container) in actionsToContainers {
            embedRecorder(for: action, in: container)
        }

        // Hide additional shortcuts section by default
        additionalShortcutsStackView.isHidden = true
    }

    // MARK: - Actions

    @IBAction func toggleShowMore(_ sender: NSButton) {
        print(#function, "called")
        additionalShortcutsStackView.isHidden = !additionalShortcutsStackView.isHidden
        showMoreButton.title = additionalShortcutsStackView.isHidden ? "▶︎ ⋯" : "▼"
    }

    // MARK: - Private Methods

    /// Embeds a KeyboardShortcuts.Recorder in the given container view.
    private func embedRecorder(for action: WindowAction, in container: NSView) {
        let recorder = KeyboardShortcuts.Recorder(for: .init(action))
        let hostingView = NSHostingView(rootView: recorder)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        // Remove existing subviews
        container.subviews.forEach { $0.removeFromSuperview() }

        // Add the hosting view
        container.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }
}
