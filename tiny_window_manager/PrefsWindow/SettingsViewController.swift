//
//  SettingsViewController.swift
//  tiny_window_manager
//
//  This file manages the Settings tab in the Preferences window.
//  It handles all the app-level settings like:
//  - Launch on login
//  - Menu bar icon visibility
//  - Window gaps/margins
//  - Title bar double-click behavior
//  - Todo mode configuration
//  - Import/export of settings
//
//  Each setting has a corresponding IBOutlet (connected in storyboard)
//  and an IBAction that handles when the user changes it.
//

import Cocoa
import ServiceManagement
import Sparkle
import MASShortcut

// MARK: - SettingsViewController Class

/// The view controller for the Settings tab in the Preferences window.
///
/// This controller manages all app-wide settings (not keyboard shortcuts - those
/// are in `PrefsViewController`). Settings are persisted via the `Defaults` class.
///
/// ## How settings work:
/// 1. User interacts with a control (checkbox, slider, popup button)
/// 2. The corresponding IBAction is called
/// 3. The action saves the new value to `Defaults`
/// 4. Some settings also post notifications to update other parts of the app
class SettingsViewController: NSViewController {

    // MARK: - Outlets (General Settings)

    /// Checkbox: Start app automatically when user logs in
    @IBOutlet weak var launchOnLoginCheckbox: NSButton!

    /// Label showing current app version (e.g., "v1.0.0 (123)")
    @IBOutlet weak var versionLabel: NSTextField!

    /// Checkbox: Hide the menu bar icon (access via keyboard shortcut only)
    @IBOutlet weak var hideMenuBarIconCheckbox: NSButton!

    /// Dropdown: What happens when the same shortcut is pressed twice
    /// Options: None, Resize (cycle through sizes), etc.
    @IBOutlet weak var subsequentExecutionPopUpButton: NSPopUpButton!

    /// Checkbox: Allow assigning shortcuts that conflict with system shortcuts
    @IBOutlet weak var allowAnyShortcutCheckbox: NSButton!

    // MARK: - Outlets (Updates)

    /// Checkbox: Automatically check for updates (via Sparkle framework)
    @IBOutlet weak var checkForUpdatesAutomaticallyCheckbox: NSButton!

    /// Button: Manually check for updates now
    @IBOutlet weak var checkForUpdatesButton: NSButton!

    // MARK: - Outlets (Window Gaps)

    /// Slider: Size of gaps between windows (in pixels)
    @IBOutlet weak var gapSlider: NSSlider!

    /// Label showing current gap size (e.g., "10 px")
    @IBOutlet weak var gapLabel: NSTextField!

    // MARK: - Outlets (Cursor & Screen Detection)

    /// Checkbox: Move cursor to new display when moving windows between displays
    @IBOutlet weak var cursorAcrossCheckbox: NSButton!

    /// Checkbox: Use cursor position to determine target screen (instead of window position)
    @IBOutlet weak var useCursorScreenDetectionCheckbox: NSButton!

    // MARK: - Outlets (Title Bar)

    /// Checkbox: Enable double-click on title bar to maximize
    @IBOutlet weak var doubleClickTitleBarCheckbox: NSButton!

    // MARK: - Outlets (Todo Mode)
    // Todo mode reserves a portion of the screen for a specific app (like a todo list)

    /// Checkbox: Enable todo mode
    @IBOutlet weak var todoCheckbox: NSButton!

    /// Container for all todo mode settings (shown/hidden based on checkbox)
    @IBOutlet weak var todoView: NSStackView!

    /// Text field: Width of the todo sidebar
    @IBOutlet weak var todoAppWidthField: AutoSaveFloatField!

    /// Dropdown: Unit for todo width (pixels or percentage)
    @IBOutlet weak var todoAppWidthUnitPopUpButton: NSPopUpButton!

    /// Dropdown: Which side of screen for todo sidebar (left or right)
    @IBOutlet weak var todoAppSidePopUpButton: NSPopUpButton!

    /// Shortcut view: Keyboard shortcut to toggle todo mode
    @IBOutlet weak var toggleTodoShortcutView: MASShortcutView!

    /// Shortcut view: Keyboard shortcut to reflow windows around todo sidebar
    @IBOutlet weak var reflowTodoShortcutView: MASShortcutView!

    // MARK: - Outlets (Stage Manager)
    // Stage Manager is a macOS feature for organizing windows

    /// Container for Stage Manager settings
    @IBOutlet weak var stageView: NSStackView!

    /// Slider: Stage Manager strip size
    @IBOutlet weak var stageSlider: NSSlider!

    /// Label showing current stage size (e.g., "200 px")
    @IBOutlet weak var stageLabel: NSTextField!

    // MARK: - Outlets (Cycle Sizes)
    // When "Resize" is selected for subsequent execution, user can choose which sizes to cycle through

    /// Container for cycle size checkboxes
    @IBOutlet weak var cycleSizesView: NSStackView!

    /// Constraint to collapse cycle sizes view when not needed
    @IBOutlet var cycleSizesViewHeightConstraint: NSLayoutConstraint!

    /// Constraint to collapse todo view when not needed
    @IBOutlet var todoViewHeightConstraint: NSLayoutConstraint!

    /// Button: Show extra settings popover
    @IBOutlet weak var extraSettingsButton: NSButton!

    // MARK: - Private Properties

    /// Window controller for the "About Todo Mode" help window
    private var aboutTodoWindowController: NSWindowController?

    /// Popover showing extra settings (larger/smaller width shortcuts)
    private var extraSettingsPopover: NSPopover?

    /// Dynamically created checkboxes for cycle size options
    private var cycleSizeCheckboxes = [NSButton]()

    // MARK: - Actions (General Settings)

    /// Called when user toggles "Launch on Login" checkbox.
    /// Uses different APIs for macOS 13+ vs older versions.
    @IBAction func toggleLaunchOnLogin(_ sender: NSButton) {
        print(#function, "called")
        let newSetting: Bool = sender.state == .on

        // macOS 13+ uses the new LaunchOnLogin API
        if #available(macOS 13, *) {
            LaunchOnLogin.isEnabled = newSetting
        } else {
            // Older macOS uses SMLoginItemSetEnabled (deprecated but still works)
            let smLoginSuccess = SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, newSetting)
            if !smLoginSuccess {
                Logger.log("Unable to set launch at login preference. Attempting one more time.")
                SMLoginItemSetEnabled(AppDelegate.launcherAppId as CFString, newSetting)
            }
        }

        Defaults.launchOnLogin.enabled = newSetting
    }

    /// Called when user toggles "Hide Menu Bar Icon" checkbox.
    /// Immediately updates the status item visibility.
    @IBAction func toggleHideMenuBarIcon(_ sender: NSButton) {
        print(#function, "called")
        let newSetting: Bool = sender.state == .on
        Defaults.hideMenuBarIcon.enabled = newSetting
        tiny_window_managerStatusItem.instance.refreshVisibility()
    }

    /// Called when user changes what happens on subsequent shortcut execution.
    /// Shows/hides the cycle sizes view based on selection.
    @IBAction func setSubsequentExecutionBehavior(_ sender: NSPopUpButton) {
        print(#function, "called")
        let tag = sender.selectedTag()
        guard let mode = SubsequentExecutionMode(rawValue: tag) else {
            Logger.log("Expected a pop up button to have a selected item with a valid tag matching a value of SubsequentExecutionMode. Got: \(String(describing: tag))")
            return
        }

        Defaults.subsequentExecutionMode.value = mode
        initializeCycleSizesView(animated: true)
    }

    // MARK: - Actions (Window Gaps)

    /// Called when user drags the gap slider.
    /// Updates label in real-time, but only saves on mouse up (to avoid excessive writes).
    @IBAction func gapSliderChanged(_ sender: NSSlider) {
        print(#function, "called")
        // Update label immediately for visual feedback
        gapLabel.stringValue = "\(sender.intValue) px"

        // Only save to defaults when user releases the mouse (not while dragging)
        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp || event.type == .keyDown {
                if Float(sender.intValue) != Defaults.gapSize.value {
                    Defaults.gapSize.value = Float(sender.intValue)
                }
            }
        }
    }

    // MARK: - Actions (Cursor & Screen Detection)

    /// Called when user toggles "Move cursor across displays" checkbox.
    @IBAction func toggleCursorMove(_ sender: NSButton) {
        print(#function, "called")
        let newSetting: Bool = sender.state == .on
        Defaults.moveCursorAcrossDisplays.enabled = newSetting
    }

    /// Called when user toggles "Use cursor for screen detection" checkbox.
    @IBAction func toggleUseCursorScreenDetection(_ sender: NSButton) {
        print(#function, "called")
        let newSetting: Bool = sender.state == .on
        Defaults.useCursorScreenDetection.enabled = newSetting
    }

    // MARK: - Actions (Shortcuts)

    /// Called when user toggles "Allow Any Shortcut" checkbox.
    /// Posts notification so shortcut views can update their validators.
    @IBAction func toggleAllowAnyShortcut(_ sender: NSButton) {
        print(#function, "called")
        let newSetting: Bool = sender.state == .on
        Defaults.allowAnyShortcut.enabled = newSetting

        // Notify PrefsViewController to update shortcut validators
        Notification.Name.allowAnyShortcut.post(object: newSetting)
    }

    // MARK: - Actions (Updates)

    /// Called when user clicks "Check for Updates" button.
    /// Delegates to the Sparkle update controller.
    @IBAction func checkForUpdates(_ sender: Any) {
        print(#function, "called")
        AppDelegate.updaterController.checkForUpdates(sender)
    }

    // MARK: - Actions (Title Bar)

    /// Called when user toggles "Double-click title bar to maximize" checkbox.
    /// Warns user if macOS system setting conflicts with this feature.
    @IBAction func toggleDoubleClickTitleBar(_ sender: NSButton) {
        print(#function, "called")
        let newSetting: Bool = sender.state == .on

        // If enabling and macOS's own title bar action is still set, warn the user
        if newSetting && !TitleBarManager.systemSettingDisabled {
            // Build localized alert text
            var openSystemSettingsButtonName = NSLocalizedString("iWV-c2-BJD.title", tableName: "Main", value: "Open System Preferences", comment: "")

            if #available(macOS 13, *) {
                openSystemSettingsButtonName = NSLocalizedString(
                    "Open System Settings", tableName: "Main", value: "", comment: "")
            }

            let conflictTitleText = NSLocalizedString(
                "Conflict with system setting", tableName: "Main", value: "", comment: "")
            let conflictDescriptionText = NSLocalizedString(
                "To let tiny_window_manager manage the title bar double click functionality, you need to disable the corresponding macOS setting.", tableName: "Main", value: "", comment: "")

            let closeText = NSLocalizedString("DVo-aG-piG.title", tableName: "Main", value: "Close", comment: "")

            // Show alert with option to open System Settings
            let response = AlertUtil.twoButtonAlert(question: conflictTitleText, text: conflictDescriptionText, confirmText: openSystemSettingsButtonName, cancelText: closeText)
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.dock")!)
            }
        }

        // Save setting: value is action rawValue + 1 (0 means disabled, so we offset by 1)
        Defaults.doubleClickTitleBar.value = (newSetting ? WindowAction.maximize.rawValue : -1) + 1
        Notification.Name.windowTitleBar.post()
    }

    // MARK: - Actions (Todo Mode)

    /// Called when user toggles the Todo Mode checkbox.
    /// Shows/hides the todo settings section.
    @IBAction func toggleTodoMode(_ sender: NSButton) {
        print(#function, "called")
        let newSetting: Bool = sender.state == .on
        Defaults.todo.enabled = newSetting
        showHideTodoModeSettings(animated: true)
        Notification.Name.todoMenuToggled.post()
    }

    /// Called when user clicks the "?" button next to Todo Mode.
    /// Opens a help window explaining what Todo Mode does.
    @IBAction func showTodoModeHelp(_ sender: Any) {
        print(#function, "called")
        // Lazily create the window controller
        if aboutTodoWindowController == nil {
            aboutTodoWindowController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "AboutTodoWindowController") as? NSWindowController
        }

        NSApp.activate(ignoringOtherApps: true)
        aboutTodoWindowController?.showWindow(self)
    }

    /// Called when user changes the todo sidebar width unit (px or %).
    /// Converts the current width value to the new unit.
    @IBAction func setTodoWidthUnit(_ sender: NSPopUpButton) {
        print(#function, "called")
        let tag = sender.selectedTag()
        guard let unit = TodoSidebarWidthUnit(rawValue: tag) else {
            Logger.log("Expected a pop up button to have a selected item with a valid tag matching a value of TodoSidebarWidthUnit. Got: \(String(describing: tag))")
            return
        }

        Defaults.todoSidebarWidthUnit.value = unit

        TodoManager.refreshTodoScreen()

        // Convert the width value to the new unit and update the text field
        if let visibleFrameWidth = TodoManager.todoScreen?.visibleFrame.width {
            let newValue = TodoManager.convert(width: Defaults.todoSidebarWidth.cgFloat, toUnit: unit, visibleFrameWidth: visibleFrameWidth)
            Defaults.todoSidebarWidth.value = Float(newValue)
            todoAppWidthField.stringValue = "\(newValue)"
        }

        TodoManager.moveAllIfNeeded(false)
    }

    /// Called when user changes which side of the screen the todo sidebar appears on.
    @IBAction func setTodoAppSide(_ sender: NSPopUpButton) {
        print(#function, "called")
        let tag = sender.selectedTag()
        guard let side = TodoSidebarSide(rawValue: tag) else {
            Logger.log("Expected a pop up button to have a selected item with a valid tag matching a value of TodoSidebarSide. Got: \(String(describing: tag))")
            return
        }

        Defaults.todoSidebarSide.value = side
        TodoManager.moveAllIfNeeded(false)
    }

    // MARK: - Actions (Stage Manager)

    /// Called when user drags the Stage Manager size slider.
    /// Similar to gap slider - updates label in real-time, saves on mouse up.
    @IBAction func stageSliderChanged(_ sender: NSSlider) {
        print(#function, "called")
        stageLabel.stringValue = "\(sender.intValue) px"

        if let event = NSApp.currentEvent {
            if event.type == .leftMouseUp || event.type == .keyDown {
                // -1 means "use system default" (slider at 0)
                let value: Float = sender.floatValue == 0 ? -1 : sender.floatValue
                if value != Defaults.stageSize.value {
                    Defaults.stageSize.value = value
                }
            }
        }
    }

    // MARK: - Actions (Import/Export)

    /// Called when user clicks "Restore Defaults".
    /// Asks user which default shortcut set to use (tiny_window_manager or Spectacle style).
    @IBAction func restoreDefaults(_ sender: Any) {
        print(#function, "called")
        // Show alert asking which defaults to restore to
        let currentDefaults = Defaults.alternateDefaultShortcuts.enabled ? "tiny_window_manager" : "Spectacle"
        let defaultShortcutsTitle = NSLocalizedString("Default Shortcuts", tableName: "Main", value: "", comment: "")
        let currentlyUsingText = NSLocalizedString("Currently using: ", tableName: "Main", value: "", comment: "")
        let cancelText = NSLocalizedString("Cancel", tableName: "Main", value: "", comment: "")

        let response = AlertUtil.threeButtonAlert(question: defaultShortcutsTitle, text: currentlyUsingText + currentDefaults, buttonOneText: "tiny_window_manager", buttonTwoText: "Spectacle", buttonThreeText: cancelText)

        // User clicked Cancel
        if response == .alertThirdButtonReturn { return }

        // Clear all custom shortcuts
        WindowAction.active.forEach { UserDefaults.standard.removeObject(forKey: $0.name) }

        // Apply the selected default set
        let tiny_window_managerDefaults = response == .alertFirstButtonReturn
        if tiny_window_managerDefaults != Defaults.alternateDefaultShortcuts.enabled {
            Defaults.alternateDefaultShortcuts.enabled = tiny_window_managerDefaults
            Notification.Name.changeDefaults.post()
        }

        // Also restore default snap areas
        Defaults.portraitSnapAreas.typedValue = nil
        Defaults.landscapeSnapAreas.typedValue = nil
        Notification.Name.defaultSnapAreas.post()
    }

    /// Called when user clicks "Export" button.
    /// Saves all settings to a JSON file.
    @IBAction func exportConfig(_ sender: NSButton) {
        print(#function, "called")
        // Temporarily disable window snapping while the save dialog is open
        Notification.Name.windowSnapping.post(object: false)

        let savePanel = NSSavePanel()
        savePanel.allowedFileTypes = ["json"]
        savePanel.nameFieldStringValue = "tiny_window_managerConfig"

        let response = savePanel.runModal()
        if response == .OK, let url = savePanel.url {
            do {
                if let jsonString = Defaults.encoded() {
                    try jsonString.write(to: url, atomically: false, encoding: .utf8)
                }
            } catch {
                Logger.log(error.localizedDescription)
            }
        }

        // Re-enable window snapping
        Notification.Name.windowSnapping.post(object: true)
    }

    /// Called when user clicks "Import" button.
    /// Loads settings from a previously exported JSON file.
    @IBAction func importConfig(_ sender: NSButton) {
        print(#function, "called")
        // Temporarily disable window snapping while the open dialog is open
        Notification.Name.windowSnapping.post(object: false)

        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = ["json"]

        let response = openPanel.runModal()
        if response == .OK, let url = openPanel.url {
            Defaults.load(fileUrl: url)
        }

        // Re-enable window snapping
        Notification.Name.windowSnapping.post(object: true)
    }

    // MARK: - Actions (Extra Settings Popover)

    /// Called when user clicks the "Extra Settings" button.
    /// Shows a popover with additional shortcuts (larger/smaller width).
    @IBAction func showExtraSettings(_ sender: NSButton) {
        print(#function, "called")
        // Create the popover lazily (only once)
        if extraSettingsPopover == nil {
            extraSettingsPopover = createExtraSettingsPopover()
        }

        extraSettingsPopover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .maxY)
    }

    // MARK: - Lifecycle

    /// Called after the view is loaded from the storyboard.
    /// Initializes all UI controls to match current settings.
    override func awakeFromNib() {
        print(#function, "called")
        // STEP 1: Initialize all toggle controls to match saved settings
        initializeToggles()

        // STEP 2: Bind auto-update checkbox directly to Sparkle's property
        checkForUpdatesAutomaticallyCheckbox.bind(.value, to: AppDelegate.updaterController.updater, withKeyPath: "automaticallyChecksForUpdates", options: nil)

        // STEP 3: Display version info
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        versionLabel.stringValue = "v" + appVersionString + " (" + buildString + ")"

        checkForUpdatesButton.title = NSLocalizedString("HIK-3r-i7E.title", tableName: "Main", value: "Check for Updates…", comment: "")

        // STEP 4: Set up Todo Mode settings
        initializeTodoModeSettings()

        // STEP 5: Set up cycle size checkboxes
        self.cycleSizeCheckboxes.forEach {
            $0.removeFromSuperview()
        }

        let cycleSizeCheckboxes = makeCycleSizeCheckboxes()
        cycleSizeCheckboxes.forEach { checkbox in
            cycleSizesView.addArrangedSubview(checkbox)
        }
        self.cycleSizeCheckboxes = cycleSizeCheckboxes

        initializeCycleSizesView(animated: false)

        // STEP 6: Listen for notifications that require UI updates
        Notification.Name.configImported.onPost(using: { _ in
            self.initializeTodoModeSettings()
            self.initializeToggles()
            self.initializeCycleSizesView(animated: false)
        })

        Notification.Name.menuBarIconHidden.onPost(using: { _ in
            self.hideMenuBarIconCheckbox.state = .on
        })
    }

    // MARK: - Initialization Helpers

    /// Sets up all Todo Mode related controls.
    func initializeTodoModeSettings() {
        print(#function, "called")
        todoCheckbox.state = Defaults.todo.userEnabled ? .on : .off
        todoAppWidthField.stringValue = String(Defaults.todoSidebarWidth.value)
        todoAppWidthField.delegate = self
        todoAppWidthField.defaults = Defaults.todoSidebarWidth
        todoAppWidthField.defaultsSetAction = {
            TodoManager.moveAllIfNeeded(false)
        }

        todoAppWidthUnitPopUpButton.selectItem(withTag: Defaults.todoSidebarWidthUnit.value.rawValue)
        todoAppSidePopUpButton.selectItem(withTag: Defaults.todoSidebarSide.value.rawValue)

        // Initialize shortcut views
        TodoManager.initToggleShortcut()
        TodoManager.initReflowShortcut()
        toggleTodoShortcutView.setAssociatedUserDefaultsKey(TodoManager.toggleDefaultsKey, withTransformerName: MASDictionaryTransformerName)
        reflowTodoShortcutView.setAssociatedUserDefaultsKey(TodoManager.reflowDefaultsKey, withTransformerName: MASDictionaryTransformerName)

        showHideTodoModeSettings(animated: false)
    }

    /// Shows or hides the Todo Mode settings section based on whether it's enabled.
    private func showHideTodoModeSettings(animated: Bool) {
        print(#function, "called")
        animateChanges(animated: animated) {
            let isEnabled = Defaults.todo.userEnabled
            todoView.isHidden = !isEnabled
            todoViewHeightConstraint.isActive = !isEnabled
        }
    }

    /// Sets all toggle controls (checkboxes, sliders, popups) to match current settings.
    func initializeToggles() {
        print(#function, "called")
        checkForUpdatesAutomaticallyCheckbox.state = Defaults.SUEnableAutomaticChecks.enabled ? .on : .off
        launchOnLoginCheckbox.state = Defaults.launchOnLogin.enabled ? .on : .off
        hideMenuBarIconCheckbox.state = Defaults.hideMenuBarIcon.enabled ? .on : .off
        subsequentExecutionPopUpButton.selectItem(withTag: Defaults.subsequentExecutionMode.value.rawValue)
        allowAnyShortcutCheckbox.state = Defaults.allowAnyShortcut.enabled ? .on : .off

        // Gap slider
        gapSlider.intValue = Int32(Defaults.gapSize.value)
        gapLabel.stringValue = "\(gapSlider.intValue) px"
        gapSlider.isContinuous = true

        // Cursor settings
        cursorAcrossCheckbox.state = Defaults.moveCursorAcrossDisplays.userEnabled ? .on : .off
        useCursorScreenDetectionCheckbox.isHidden = !Defaults.useCursorScreenDetection.enabled
        useCursorScreenDetectionCheckbox.state = Defaults.useCursorScreenDetection.enabled ? .on : .off

        // Title bar double-click
        doubleClickTitleBarCheckbox.state = WindowAction(rawValue: Defaults.doubleClickTitleBar.value - 1) != nil ? .on : .off

        // Stage Manager (only available on supported macOS versions)
        if StageUtil.stageCapable {
            stageSlider.intValue = Int32(Defaults.stageSize.value)
            stageSlider.isContinuous = true
            stageLabel.stringValue = "\(stageSlider.intValue) px"
        } else {
            stageView.isHidden = true
        }

        setToggleStatesForCycleSizeCheckboxes()
    }

    /// Shows or hides the cycle sizes view based on subsequent execution mode.
    private func initializeCycleSizesView(animated: Bool = false) {
        print(#function, "called")
        let showOptionsView = Defaults.subsequentExecutionMode.resizes

        if showOptionsView {
            setToggleStatesForCycleSizeCheckboxes()
        }

        animateChanges(animated: animated) {
            cycleSizesView.isHidden = !showOptionsView
            cycleSizesViewHeightConstraint.isActive = !showOptionsView
        }
    }

    // MARK: - Animation Helper

    /// Wraps view changes in an animation block if animated is true.
    private func animateChanges(animated: Bool, block: () -> Void) {
        print(#function, "called")
        if animated {
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.3
                context.allowsImplicitAnimation = true

                block()
                view.layoutSubtreeIfNeeded()
            }, completionHandler: nil)
        } else {
            block()
        }
    }

    // MARK: - Cycle Size Checkboxes

    /// Creates checkbox controls for each available cycle size option.
    private func makeCycleSizeCheckboxes() -> [NSButton] {
        print(#function, "called")
        return CycleSize.sortedSizes.map { division in
            let button = NSButton(checkboxWithTitle: division.title, target: self, action: #selector(didCheckCycleSizeCheckbox(sender:)))
            button.tag = division.rawValue
            button.setContentCompressionResistancePriority(.required, for: .vertical)
            return button
        }
    }

    /// Called when user toggles a cycle size checkbox.
    @objc private func didCheckCycleSizeCheckbox(sender: Any?) {
        print(#function, "called")
        guard let checkbox = sender as? NSButton else {
            Logger.log("Expected action to be sent from NSButton. Instead, sender is: \(String(describing: sender))")
            return
        }

        let rawValue = checkbox.tag

        guard let cycleSize = CycleSize(rawValue: rawValue) else {
            Logger.log("Expected tag of cycle size checkbox to match a value of CycleSize. Got: \(String(describing: rawValue))")
            return
        }

        // On first change, copy defaults to the user's selected set
        if !Defaults.cycleSizesIsChanged.enabled {
            Defaults.selectedCycleSizes.value = CycleSize.defaultSizes
        }

        Defaults.cycleSizesIsChanged.enabled = true

        // Add or remove the cycle size based on checkbox state
        if checkbox.state == .on {
            Defaults.selectedCycleSizes.value.insert(cycleSize)
        } else {
            Defaults.selectedCycleSizes.value.remove(cycleSize)
        }
    }

    /// Updates all cycle size checkboxes to match current settings.
    private func setToggleStatesForCycleSizeCheckboxes() {
        print(#function, "called")
        let useDefaultCycleSizes = !Defaults.cycleSizesIsChanged.enabled
        let cycleSizes = useDefaultCycleSizes ? CycleSize.defaultSizes : Defaults.selectedCycleSizes.value

        cycleSizeCheckboxes.forEach { checkbox in
            guard let cycleSizeForCheckbox = CycleSize(rawValue: checkbox.tag) else {
                return
            }

            let isAlwaysEnabled = cycleSizeForCheckbox.isAlwaysEnabled
            let isChecked = isAlwaysEnabled || cycleSizes.contains(cycleSizeForCheckbox)
            checkbox.state = isChecked ? .on : .off

            // Some sizes can't be disabled (they're required)
            if isAlwaysEnabled {
                checkbox.isEnabled = false
            }
        }
    }

    // MARK: - Extra Settings Popover

    /// Builds the popover UI for extra settings (larger/smaller width shortcuts).
    /// This is created programmatically rather than in the storyboard.
    private func createExtraSettingsPopover() -> NSPopover {
        print(#function, "called")
        let popover = NSPopover()
        popover.behavior = .transient
        let viewController = NSViewController()

        // Create main vertical stack
        let mainStackView = NSStackView()
        mainStackView.orientation = .vertical
        mainStackView.alignment = .leading
        mainStackView.spacing = 5
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        // Header
        let headerLabel = NSTextField(labelWithString: NSLocalizedString("Extra Shortcuts", tableName: "Main", value: "", comment: ""))
        headerLabel.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        headerLabel.alignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        // Labels for each row
        let largerWidthLabel = NSTextField(labelWithString: NSLocalizedString("Larger Width", tableName: "Main", value: "", comment: ""))
        largerWidthLabel.alignment = .right
        let smallerWidthLabel = NSTextField(labelWithString: NSLocalizedString("Smaller Width", tableName: "Main", value: "", comment: ""))
        smallerWidthLabel.alignment = .right
        let widthStepLabel = NSTextField(labelWithString: NSLocalizedString("Width Step (px)", tableName: "Main", value: "", comment: ""))
        widthStepLabel.alignment = .right

        largerWidthLabel.translatesAutoresizingMaskIntoConstraints = false
        smallerWidthLabel.translatesAutoresizingMaskIntoConstraints = false
        widthStepLabel.translatesAutoresizingMaskIntoConstraints = false

        // Shortcut views for width actions
        let largerWidthShortcutView = MASShortcutView(frame: NSRect(x: 0, y: 0, width: 160, height: 19))
        let smallerWidthShortcutView = MASShortcutView(frame: NSRect(x: 0, y: 0, width: 160, height: 19))

        // Width step size field
        let widthStepField = AutoSaveFloatField(frame: NSRect(x: 0, y: 0, width: 160, height: 19))
        widthStepField.stringValue = String(Int(Defaults.widthStepSize.value))
        widthStepField.delegate = self
        widthStepField.defaults = Defaults.widthStepSize
        widthStepField.translatesAutoresizingMaskIntoConstraints = false
        widthStepField.refusesFirstResponder = true
        widthStepField.alignment = .right

        // Only allow positive integers
        let integerFormatter = NumberFormatter()
        integerFormatter.allowsFloats = false
        integerFormatter.minimum = 1
        widthStepField.formatter = integerFormatter

        // Bind shortcut views to UserDefaults
        largerWidthShortcutView.setAssociatedUserDefaultsKey(WindowAction.largerWidth.name, withTransformerName: MASDictionaryTransformerName)
        smallerWidthShortcutView.setAssociatedUserDefaultsKey(WindowAction.smallerWidth.name, withTransformerName: MASDictionaryTransformerName)

        // Apply permissive validator if "Allow Any Shortcut" is enabled
        if Defaults.allowAnyShortcut.enabled {
            let passThroughValidator = PassthroughShortcutValidator()
            largerWidthShortcutView.shortcutValidator = passThroughValidator
            smallerWidthShortcutView.shortcutValidator = passThroughValidator
        }

        // Icons for the actions
        let largerWidthIcon = NSImageView(frame: NSRect(x: 0, y: 0, width: 21, height: 14))
        largerWidthIcon.image = WindowAction.largerWidth.image
        largerWidthIcon.image?.size = NSSize(width: 21, height: 14)

        let smallerWidthIcon = NSImageView(frame: NSRect(x: 0, y: 0, width: 21, height: 14))
        smallerWidthIcon.image = WindowAction.smallerWidth.image
        smallerWidthIcon.image?.size = NSSize(width: 21, height: 14)

        // Build label + icon stacks
        let largerWidthLabelStack = NSStackView()
        largerWidthLabelStack.orientation = .horizontal
        largerWidthLabelStack.alignment = .centerY
        largerWidthLabelStack.spacing = 8
        largerWidthLabelStack.addArrangedSubview(largerWidthLabel)
        largerWidthLabelStack.addArrangedSubview(largerWidthIcon)

        let smallerWidthLabelStack = NSStackView()
        smallerWidthLabelStack.orientation = .horizontal
        smallerWidthLabelStack.alignment = .centerY
        smallerWidthLabelStack.spacing = 8
        smallerWidthLabelStack.addArrangedSubview(smallerWidthLabel)
        smallerWidthLabelStack.addArrangedSubview(smallerWidthIcon)

        // Build complete rows (label stack + control)
        let largerWidthRow = NSStackView()
        largerWidthRow.orientation = .horizontal
        largerWidthRow.alignment = .centerY
        largerWidthRow.spacing = 18
        largerWidthRow.addArrangedSubview(largerWidthLabelStack)
        largerWidthRow.addArrangedSubview(largerWidthShortcutView)

        let smallerWidthRow = NSStackView()
        smallerWidthRow.orientation = .horizontal
        smallerWidthRow.alignment = .centerY
        smallerWidthRow.spacing = 18
        smallerWidthRow.addArrangedSubview(smallerWidthLabelStack)
        smallerWidthRow.addArrangedSubview(smallerWidthShortcutView)

        let widthStepRow = NSStackView()
        widthStepRow.orientation = .horizontal
        widthStepRow.alignment = .centerY
        widthStepRow.spacing = 18
        widthStepRow.addArrangedSubview(widthStepLabel)
        widthStepRow.addArrangedSubview(widthStepField)

        // Assemble main stack
        mainStackView.addArrangedSubview(headerLabel)
        mainStackView.setCustomSpacing(10, after: headerLabel)
        mainStackView.addArrangedSubview(largerWidthRow)
        mainStackView.addArrangedSubview(smallerWidthRow)
        mainStackView.addArrangedSubview(widthStepRow)

        // Set up constraints for alignment
        NSLayoutConstraint.activate([
            headerLabel.widthAnchor.constraint(equalTo: mainStackView.widthAnchor),
            largerWidthLabel.widthAnchor.constraint(equalTo: smallerWidthLabel.widthAnchor),
            smallerWidthLabel.widthAnchor.constraint(equalTo: widthStepLabel.widthAnchor),
            largerWidthLabelStack.widthAnchor.constraint(equalTo: smallerWidthLabelStack.widthAnchor),
            largerWidthShortcutView.widthAnchor.constraint(equalToConstant: 160),
            smallerWidthShortcutView.widthAnchor.constraint(equalToConstant: 160),
            widthStepField.widthAnchor.constraint(equalToConstant: 160),
            widthStepField.trailingAnchor.constraint(equalTo: largerWidthShortcutView.trailingAnchor)
        ])

        // Wrap in container with padding
        let containerView = NSView()
        containerView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15)
        ])

        viewController.view = containerView
        popover.contentViewController = viewController

        return popover
    }

}

// MARK: - Storyboard Instantiation

extension SettingsViewController {

    /// Creates a new SettingsViewController from the storyboard.
    ///
    /// This is the proper way to create this controller since it's
    /// defined in the Main storyboard file.
    static func freshController() -> SettingsViewController {
        print(#function, "called")
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = "SettingsViewController"
        guard let viewController = storyboard.instantiateController(withIdentifier: identifier) as? SettingsViewController else {
            fatalError("Unable to find ViewController - Check Main.storyboard")
        }
        return viewController
    }
}

// MARK: - NSTextFieldDelegate

extension SettingsViewController: NSTextFieldDelegate {

    /// Called when text changes in an AutoSaveFloatField.
    /// Uses debouncing to avoid saving on every keystroke.
    func controlTextDidChange(_ obj: Notification) {
        print(#function, "called")
        guard let sender = obj.object as? AutoSaveFloatField,
              let defaults: FloatDefault = sender.defaults else { return }

        // Debounce: wait for user to stop typing before saving
        Debounce<Float>.input(sender.floatValue, comparedAgainst: sender.floatValue) { floatValue in
            defaults.value = floatValue
            sender.defaultsSetAction?()
        }
    }

    /// Called when user finishes editing (tabs out, presses Enter, etc.).
    /// Resets to default value if field is empty.
    func controlTextDidEndEditing(_ obj: Notification) {
        print(#function, "called")
        guard let sender = obj.object as? AutoSaveFloatField,
              let defaults: FloatDefault = sender.defaults else { return }

        // Don't allow empty values - reset to default
        if sender.stringValue.isEmpty {
            sender.stringValue = "30"
            defaults.value = 30
            sender.defaultsSetAction?()
        }
    }
}

// MARK: - AutoSaveFloatField Class

/// A custom text field that automatically saves its value to UserDefaults.
///
/// Used for numeric settings like todo sidebar width and width step size.
/// When the user types, the value is debounced and saved to the associated
/// `FloatDefault` after a short delay.
///
/// ## Usage:
/// ```swift
/// let field = AutoSaveFloatField()
/// field.defaults = Defaults.todoSidebarWidth
/// field.defaultsSetAction = { TodoManager.moveAllIfNeeded(false) }
/// ```
class AutoSaveFloatField: NSTextField {

    /// The UserDefaults key this field saves to
    var defaults: FloatDefault?

    /// Optional callback executed after the value is saved to defaults
    var defaultsSetAction: (() -> Void)?
}
