//
//  ShortcutManager.swift
//  tiny_window_manager
//
//  Goal of this file:
//  - Register default keyboard shortcuts for each WindowAction
//  - Bind those shortcuts so pressing keys triggers WindowAction.post (which posts a Notification)
//  - Listen for those Notifications and run the actual window management logic
//

import Foundation
import MASShortcut

final class ShortcutManager {

    // MARK: - Dependencies (injected)

    /// The thing that ultimately executes a window action (move/resize/etc).
    private let windowManager: WindowManager

    /// Convenience accessor so we don’t repeat MASShortcutBinder.shared()? everywhere.
    /// If MASShortcutBinder is unavailable (nil), we just no-op safely.
    private var binder: MASShortcutBinder? { MASShortcutBinder.shared() }

    // MARK: - Lifecycle

    init(windowManager: WindowManager) {
        print(#function, "called")
        self.windowManager = windowManager

        configureMASShortcutBinder()
        setupShortcutsAndObservers()

        // If app defaults change (user edits shortcuts in preferences),
        // re-register the default shortcuts so MASShortcut can see them.
        Notification.Name.changeDefaults.onPost { [weak self] _ in
            self?.registerDefaultShortcuts()
        }
    }

    deinit {
        print(#function, "called")
        // Always clean up NotificationCenter observers when the object is going away.
        unsubscribeFromAllWindowActions()
    }

    // MARK: - Public API

    /// Rebuild everything from UserDefaults:
    /// - stop observing
    /// - unbind shortcuts
    /// - register defaults again
    /// - bind shortcuts again
    /// - start observing again
    public func reloadFromDefaults() {
        print(#function, "called")
        tearDown()
        setupShortcutsAndObservers()
    }

    /// Public wrapper so other code can explicitly enable shortcuts.
    /// (Calls the internal helper that binds all actions.)
    public func bindShortcuts() {
        print(#function, "called")
        bindAllShortcuts()
    }

    /// Public wrapper so other code can explicitly disable shortcuts.
    /// (Calls the internal helper that unbinds all actions.)
    public func unbindShortcuts() {
        print(#function, "called")
        unbindAllShortcuts()
    }

    /// Returns the key equivalent (like "⌘⌥M") and modifier flags for an action, if set.
    public func getKeyEquivalent(action: WindowAction) -> (String?, NSEvent.ModifierFlags)? {
        print(#function, "called")
        guard let shortcut = binder?.value(forKey: action.name) as? MASShortcut else {
            return nil
        }
        return (shortcut.keyCodeStringForKeyEquivalent, shortcut.modifierFlags)
    }

    // MARK: - Setup / Teardown helpers

    private func configureMASShortcutBinder() {
        print(#function, "called")
        // MASShortcut uses Cocoa bindings; this tells it how to transform dictionaries.
        binder?.bindingOptions = [
            NSBindingOption.valueTransformerName: MASDictionaryTransformerName
        ]
    }

    private func setupShortcutsAndObservers() {
        print(#function, "called")
        registerDefaultShortcuts()
        bindAllShortcuts()
        subscribeToAllWindowActions()
    }

    private func tearDown() {
        print(#function, "called")
        unsubscribeFromAllWindowActions()
        unbindAllShortcuts()
    }

    // MARK: - Binding shortcuts (internal helpers)

    private func bindAllShortcuts() {
        print(#function, "called")
        for action in WindowAction.active {
            binder?.bindShortcut(withDefaultsKey: action.name, toAction: action.post)
        }
    }

    
    
    
    
    
    
    
    private func unbindAllShortcuts() {
        print(#function, "called")
        for action in WindowAction.active {
            binder?.breakBinding(withDefaultsKey: action.name)
        }
    }

    // MARK: - Default shortcut registration

    /// Register “factory defaults” shortcuts for each WindowAction.
    /// MASShortcut stores shortcuts in UserDefaults keyed by action.name.
    private func registerDefaultShortcuts() {
        print(#function, "called")
        var defaults: [String: MASShortcut] = [:]

        for action in WindowAction.active {
            guard let defaultShortcut = defaultShortcutForAction(action) else {
                continue
            }

            // Convert your “defaultShortcut” model into MASShortcut’s object.
            let mas = MASShortcut(
                keyCode: defaultShortcut.keyCode,
                modifierFlags: NSEvent.ModifierFlags(rawValue: defaultShortcut.modifierFlags)
            )

            defaults[action.name] = mas
        }

        binder?.registerDefaultShortcuts(defaults)
    }

    /// Chooses which default shortcut set to use based on user preference.
    private func defaultShortcutForAction(_ action: WindowAction) -> Shortcut? {
        print(#function, "called")
        // NOTE: I'm assuming `alternateDefault` / `spectacleDefault` are of type `Shortcut?`.
        // Replace `Shortcut` with your actual type if it's named differently.
        if Defaults.alternateDefaultShortcuts.enabled {
            return action.alternateDefault
        } else {
            return action.spectacleDefault
        }
    }

    // MARK: - Notifications wiring

    private func subscribeToAllWindowActions() {
        print(#function, "called")
        for action in WindowAction.active {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowActionTriggered(notification:)),
                name: action.notificationName,
                object: nil
            )
        }
    }

    private func unsubscribeFromAllWindowActions() {
        print(#function, "called")
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notification handler (the “main entry point” when a shortcut fires)

    /// This is called when a WindowAction posts its notification.
    @objc private func windowActionTriggered(notification: NSNotification) {
        print(#function, "called")
        guard var parameters = notification.object as? ExecutionParameters else {
            return
        }

        // 1) Let special systems handle it first (if they claim it, we stop).
        if MultiWindowManager.execute(parameters: parameters) { return }
        if TodoManager.execute(parameters: parameters) { return }

        // 2) Optionally modify parameters if user wants repeated shortcuts to cycle monitors.
        parameters = adjustParametersForCycleMonitorIfNeeded(parameters)

        // 3) Execute the action.
        windowManager.execute(parameters)
    }

    // MARK: - Cycle-monitor logic (pulled out for readability)

    private func adjustParametersForCycleMonitorIfNeeded(_ parameters: ExecutionParameters) -> ExecutionParameters {
        print(#function, "called")
        // Only do cycle-monitor behavior when the preference is enabled…
        guard Defaults.subsequentExecutionMode.value == .cycleMonitor else {
            return parameters
        }

        // …and only for action categories where cycling makes sense.
        guard parameters.action.classification != .size,
              parameters.action.classification != .display else {
            return parameters
        }

        // We need a window element and window id to check "repeat action" logic.
        guard let windowElement = parameters.windowElement ?? AccessibilityElement.getFrontWindowElement(),
              let windowId = parameters.windowId ?? windowElement.getWindowId() else {
            NSSound.beep()
            return parameters
        }

        // If the user repeats the same action, switch to the next screen (if available).
        guard isRepeatAction(parameters: parameters, windowElement: windowElement, windowId: windowId) else {
            return parameters
        }

        guard let nextScreen = ScreenDetection()
            .detectScreens(using: windowElement)?
            .adjacentScreens?
            .next else {
            return parameters
        }

        // Build a new ExecutionParameters targeting the next screen.
        let updated = ExecutionParameters(
            parameters.action,
            updateRestoreRect: parameters.updateRestoreRect,
            screen: nextScreen,
            windowElement: windowElement,
            windowId: windowId
        )

        // Bypass “subsequent action” logic by clearing the last action for this window.
        AppDelegate.windowHistory.lasttiny_window_managerActions.removeValue(forKey: windowId)

        return updated
    }

    /// Returns true if the user is repeating the same action on the same window.
    private func isRepeatAction(parameters: ExecutionParameters,
                                windowElement: AccessibilityElement,
                                windowId: CGWindowID) -> Bool {
        print(#function, "called")

        // Special-case: maximize counts as a "repeat" if the window is already maximized.
        if parameters.action == .maximize {
            let screenSize = ScreenDetection()
                .detectScreens(using: windowElement)?
                .currentScreen
                .visibleFrame
                .size

            if screenSize == windowElement.frame.size {
                return true
            }
        }

        // General case: if last action for this window matches the current action.
        let lastAction = AppDelegate.windowHistory.lasttiny_window_managerActions[windowId]?.action
        return parameters.action == lastAction
    }
}
