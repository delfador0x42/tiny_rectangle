//
//  SnapAreaViewController.swift
//  tiny_window_manager
//
//  This view controller manages the "Snap Areas" preferences panel.
//  It lets users configure how windows snap when dragged to screen edges/corners.
//

import Cocoa

class SnapAreaViewController: NSViewController {

    // MARK: - General Settings Checkboxes

    @IBOutlet weak var windowSnappingCheckbox: NSButton!
    @IBOutlet weak var unsnapRestoreButton: NSButton!
    @IBOutlet weak var animateFootprintCheckbox: NSButton!
    @IBOutlet weak var hapticFeedbackCheckbox: NSButton!
    @IBOutlet weak var missionControlDraggingCheckbox: NSButton!

    // MARK: - Landscape Orientation Snap Area Dropdowns
    // These dropdowns let users pick what action happens when dragging to each screen edge/corner

    @IBOutlet weak var topLeftLandscapeSelect: NSPopUpButton!
    @IBOutlet weak var topLandscapeSelect: NSPopUpButton!
    @IBOutlet weak var topRightLandscapeSelect: NSPopUpButton!
    @IBOutlet weak var leftLandscapeSelect: NSPopUpButton!
    @IBOutlet weak var rightLandscapeSelect: NSPopUpButton!
    @IBOutlet weak var bottomLeftLandscapeSelect: NSPopUpButton!
    @IBOutlet weak var bottomLandscapeSelect: NSPopUpButton!
    @IBOutlet weak var bottomRightLandscapeSelect: NSPopUpButton!

    // MARK: - Portrait Orientation Snap Area Dropdowns
    // Only shown when a portrait-oriented display is connected

    @IBOutlet weak var portraitStackView: NSStackView!

    @IBOutlet weak var topLeftPortraitSelect: NSPopUpButton!
    @IBOutlet weak var topPortraitSelect: NSPopUpButton!
    @IBOutlet weak var topRightPortraitSelect: NSPopUpButton!
    @IBOutlet weak var leftPortraitSelect: NSPopUpButton!
    @IBOutlet weak var rightPortraitSelect: NSPopUpButton!
    @IBOutlet weak var bottomLeftPortraitSelect: NSPopUpButton!
    @IBOutlet weak var bottomPortraitSelect: NSPopUpButton!
    @IBOutlet weak var bottomRightPortraitSelect: NSPopUpButton!

    // MARK: - Checkbox Toggle Actions

    @IBAction func toggleWindowSnapping(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        Defaults.windowSnapping.enabled = isEnabled
        Notification.Name.windowSnapping.post(object: isEnabled)

        // When enabling snapping, check if macOS built-in tiling might conflict
        if isEnabled {
            MacTilingDefaults.checkForBuiltInTiling(skipIfAlreadyNotified: false)
        }
    }

    @IBAction func toggleUnsnapRestore(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        Defaults.unsnapRestore.enabled = isEnabled
    }

    @IBAction func toggleAnimateFootprint(_ sender: NSButton) {
        // Animation multiplier: 0 = no animation, 0.75 = animated
        let animationMultiplier: Float = sender.state == .on ? 0.75 : 0
        Defaults.footprintAnimationDurationMultiplier.value = animationMultiplier
    }

    @IBAction func toggleHapticFeedback(_ sender: NSButton) {
        let isEnabled = sender.state == .on
        Defaults.hapticFeedbackOnSnap.enabled = isEnabled
    }

    @IBAction func toggleMissionControlDragging(_ sender: NSButton) {
        // Note: This checkbox uses inverted logic (checked = disabled)
        let isEnabled = sender.state == .off
        Defaults.missionControlDragging.enabled = isEnabled
        Notification.Name.missionControlDragging.post(object: isEnabled)
    }

    // MARK: - Snap Area Dropdown Actions

    @IBAction func setLandscapeSnapArea(_ sender: NSPopUpButton) {
        setSnapArea(sender: sender, type: .landscape)
    }

    @IBAction func setPortraitSnapArea(_ sender: NSPopUpButton) {
        setSnapArea(sender: sender, type: .portrait)
    }

    /// Handles when user selects a new snap action from a dropdown
    private func setSnapArea(sender: NSPopUpButton, type: DisplayOrientation) {
        // The dropdown's tag identifies which screen edge/corner it controls
        guard let screenDirection = Directional(rawValue: sender.tag) else {
            return
        }

        let selectedTag = sender.selectedTag()
        let snapAreaConfig = createSnapAreaConfig(fromTag: selectedTag)

        SnapAreaModel.instance.setConfig(
            type: type,
            directional: screenDirection,
            snapAreaConfig: snapAreaConfig
        )
    }

    /// Converts a menu item tag into a SnapAreaConfig
    /// Tag meanings:
    ///   - Negative (< -1): Compound snap areas (e.g., thirds, quarters)
    ///   - Positive (> -1): Single window actions (e.g., left half, maximize)
    ///   - Exactly -1: No action assigned
    private func createSnapAreaConfig(fromTag tag: Int) -> SnapAreaConfig? {
        if tag < -1, let compound = CompoundSnapArea(rawValue: tag) {
            return SnapAreaConfig(compound: compound)
        } else if tag > -1, let action = WindowAction(rawValue: tag) {
            return SnapAreaConfig(action: action)
        }
        return nil
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        loadCheckboxStates()
        loadSnapAreas()
        showHidePortrait()
        registerForNotifications()
    }

    /// Sets checkbox states based on current user defaults
    private func loadCheckboxStates() {
        windowSnappingCheckbox.state = Defaults.windowSnapping.userDisabled ? .off : .on
        unsnapRestoreButton.state = Defaults.unsnapRestore.userDisabled ? .off : .on
        animateFootprintCheckbox.state = Defaults.footprintAnimationDurationMultiplier.value > 0 ? .on : .off
        hapticFeedbackCheckbox.state = Defaults.hapticFeedbackOnSnap.userEnabled ? .on : .off

        // Mission control checkbox is hidden unless user has explicitly disabled it
        missionControlDraggingCheckbox.state = Defaults.missionControlDragging.userDisabled ? .on : .off
        missionControlDraggingCheckbox.isHidden = !Defaults.missionControlDragging.userDisabled
    }

    /// Subscribes to notifications that require UI updates
    private func registerForNotifications() {
        // Reload snap areas when config is imported or reset to defaults
        Notification.Name.configImported.onPost { [weak self] _ in
            self?.loadSnapAreas()
        }
        Notification.Name.defaultSnapAreas.onPost { [weak self] _ in
            self?.loadSnapAreas()
        }

        // Refresh portrait section visibility when app becomes active
        Notification.Name.appWillBecomeActive.onPost { [weak self] _ in
            self?.showHidePortrait()
        }

        // Sync checkbox if window snapping is toggled elsewhere
        Notification.Name.windowSnapping.onPost { [weak self] _ in
            self?.windowSnappingCheckbox.state = Defaults.windowSnapping.userDisabled ? .off : .on
        }

        // Refresh portrait section when displays are connected/disconnected
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.showHidePortrait()
        }
    }

    // MARK: - Public Methods

    /// Shows or hides the portrait orientation settings based on connected displays
    func showHidePortrait() {
        portraitStackView.isHidden = !NSScreen.portraitDisplayConnected
    }

    /// Reloads all snap area dropdowns with current configuration
    func loadSnapAreas() {
        let landscapeDropdowns = [
            topLeftLandscapeSelect,
            topLandscapeSelect,
            topRightLandscapeSelect,
            leftLandscapeSelect,
            rightLandscapeSelect,
            bottomLeftLandscapeSelect,
            bottomLandscapeSelect,
            bottomRightLandscapeSelect
        ]

        let portraitDropdowns = [
            topLeftPortraitSelect,
            topPortraitSelect,
            topRightPortraitSelect,
            leftPortraitSelect,
            rightPortraitSelect,
            bottomLeftPortraitSelect,
            bottomPortraitSelect,
            bottomRightPortraitSelect
        ]

        landscapeDropdowns.forEach { dropdown in
            configureSnapAreaDropdown(dropdown!, orientation: .landscape)
        }
        portraitDropdowns.forEach { dropdown in
            configureSnapAreaDropdown(dropdown!, orientation: .portrait)
        }
    }

    // MARK: - Dropdown Configuration

    /// Populates a snap area dropdown with available options and selects the current setting
    private func configureSnapAreaDropdown(_ dropdown: NSPopUpButton, orientation: DisplayOrientation) {
        guard let screenDirection = Directional(rawValue: dropdown.tag) else {
            return
        }

        // Get the current config for this screen direction
        let currentConfig = getSnapAreaConfig(for: screenDirection, orientation: orientation)
        let currentlySelectedTag = currentConfig?.action?.rawValue ?? currentConfig?.compound?.rawValue ?? -1

        // Clear existing menu items
        dropdown.removeAllItems()

        // Add "no action" option
        addNoActionOption(to: dropdown)

        // Add compound snap areas (thirds, quarters, etc.)
        addCompoundSnapAreaOptions(
            to: dropdown,
            orientation: orientation,
            screenDirection: screenDirection,
            currentlySelectedTag: currentlySelectedTag
        )

        // Add separator between compound and single actions
        dropdown.menu?.addItem(NSMenuItem.separator())

        // Add single window actions (left half, right half, etc.)
        addWindowActionOptions(
            to: dropdown,
            currentlySelectedTag: currentlySelectedTag
        )
    }

    /// Gets the snap area configuration for a given screen direction and orientation
    private func getSnapAreaConfig(for direction: Directional, orientation: DisplayOrientation) -> SnapAreaConfig? {
        switch orientation {
        case .landscape:
            return SnapAreaModel.instance.landscape[direction]
        case .portrait:
            return SnapAreaModel.instance.portrait[direction]
        }
    }

    /// Adds the "-" (no action) option to a dropdown
    private func addNoActionOption(to dropdown: NSPopUpButton) {
        dropdown.addItem(withTitle: "-")
        dropdown.menu?.items.first?.tag = -1
    }

    /// Adds compound snap area options (e.g., left/right thirds) to a dropdown
    private func addCompoundSnapAreaOptions(
        to dropdown: NSPopUpButton,
        orientation: DisplayOrientation,
        screenDirection: Directional,
        currentlySelectedTag: Int
    ) {
        for compoundArea in CompoundSnapArea.all {
            // Only show options compatible with this orientation and screen direction
            let isCompatibleOrientation = compoundArea.compatibleOrientation.contains(orientation)
            let isCompatibleDirection = compoundArea.compatibleDirectionals.contains(screenDirection)

            guard isCompatibleOrientation && isCompatibleDirection else {
                continue
            }

            let menuItem = NSMenuItem(
                title: compoundArea.displayName,
                action: nil,
                keyEquivalent: ""
            )
            menuItem.tag = compoundArea.rawValue
            dropdown.menu?.addItem(menuItem)

            if currentlySelectedTag == menuItem.tag {
                dropdown.select(menuItem)
            }
        }
    }

    /// Adds single window action options (e.g., maximize, left half) to a dropdown
    private func addWindowActionOptions(to dropdown: NSPopUpButton, currentlySelectedTag: Int) {
        for windowAction in WindowAction.active {
            // Only include actions that support drag-snapping
            guard windowAction.isDragSnappable, let displayName = windowAction.displayName else {
                continue
            }

            let menuItem = NSMenuItem(
                title: displayName,
                action: nil,
                keyEquivalent: ""
            )
            menuItem.tag = windowAction.rawValue

            // Add a small icon showing the window position
            if let icon = windowAction.image.copy() as? NSImage {
                icon.size = NSSize(width: 18, height: 12)
                menuItem.image = icon
            }

            dropdown.menu?.addItem(menuItem)

            if currentlySelectedTag == menuItem.tag {
                dropdown.select(menuItem)
            }
        }
    }
}
