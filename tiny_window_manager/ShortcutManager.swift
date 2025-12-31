//
//  ShortcutManager.swift
//  tiny_window_manager
//
//  Manages keyboard shortcuts for window actions using KeyboardShortcuts library.
//

import Foundation
import KeyboardShortcuts

// MARK: - KeyboardShortcuts.Name Extension

extension KeyboardShortcuts.Name {
    /// Creates a shortcut name from a WindowAction.
    init(_ action: WindowAction) {
        self.init(action.name)
    }
}

// MARK: - ShortcutManager

final class ShortcutManager {

    private let windowManager: WindowManager

    init(windowManager: WindowManager) {
        print(#function, "called")
        self.windowManager = windowManager
        registerDefaults()
        bindAllShortcuts()
        subscribeToAllWindowActions()
    }

    deinit {
        print(#function, "called")
        unsubscribeFromAllWindowActions()
    }

    // MARK: - Public API

    func reloadFromDefaults() {
        print(#function, "called")
        registerDefaults()
    }

    func bindShortcuts() {
        print(#function, "called")
        for action in WindowAction.active {
            KeyboardShortcuts.enable(.init(action))
        }
    }

    func unbindShortcuts() {
        print(#function, "called")
        for action in WindowAction.active {
            KeyboardShortcuts.disable(.init(action))
        }
    }

    /// Returns the key equivalent string and modifier flags for menu display.
    func getKeyEquivalent(action: WindowAction) -> (String?, NSEvent.ModifierFlags)? {
        print(#function, "called")
        guard let shortcut = KeyboardShortcuts.getShortcut(for: .init(action)) else {
            return nil
        }
        // KeyboardShortcuts uses NSEvent.ModifierFlags directly
        let keyString = shortcut.key.flatMap { keyEquivalentString(for: $0) }
        return (keyString, shortcut.modifiers)
    }

    /// Converts a KeyboardShortcuts.Key to a string for menu display.
    private func keyEquivalentString(for key: KeyboardShortcuts.Key) -> String? {
        // Use the key's rawValue to get the character
        // KeyboardShortcuts.Key uses Carbon key codes
        let keyCode = key.rawValue

        // Try to get the character from the key code
        if let char = characterForKeyCode(Int(keyCode)) {
            return String(char)
        }
        return nil
    }

    /// Converts a Carbon key code to its character representation.
    private func characterForKeyCode(_ keyCode: Int) -> Character? {
        // Common key mappings (subset of Carbon key codes)
        switch keyCode {
        case 0: return "a"
        case 1: return "s"
        case 2: return "d"
        case 3: return "f"
        case 4: return "h"
        case 5: return "g"
        case 6: return "z"
        case 7: return "x"
        case 8: return "c"
        case 9: return "v"
        case 11: return "b"
        case 12: return "q"
        case 13: return "w"
        case 14: return "e"
        case 15: return "r"
        case 16: return "y"
        case 17: return "t"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "o"
        case 32: return "u"
        case 33: return "["
        case 34: return "i"
        case 35: return "p"
        case 37: return "l"
        case 38: return "j"
        case 39: return "'"
        case 40: return "k"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "n"
        case 46: return "m"
        case 47: return "."
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return nil
        }
    }

    // MARK: - Private: Setup

    private func registerDefaults() {
        print(#function, "called")
        for action in WindowAction.active {
            let name = KeyboardShortcuts.Name(action)
            // Only set default if user hasn't already set a shortcut
            guard KeyboardShortcuts.getShortcut(for: name) == nil else { continue }

            if let defaultShortcut = defaultShortcutForAction(action) {
                // KeyboardShortcuts.Key uses Int for rawValue (non-optional init)
                let key = KeyboardShortcuts.Key(rawValue: defaultShortcut.keyCode)
                let modifiers = NSEvent.ModifierFlags(rawValue: defaultShortcut.modifierFlags)
                // KeyboardShortcuts.Shortcut takes NSEvent.ModifierFlags directly
                KeyboardShortcuts.setShortcut(.init(key, modifiers: modifiers), for: name)
            }
        }
    }

    private func bindAllShortcuts() {
        print(#function, "called")
        for action in WindowAction.active {
            KeyboardShortcuts.onKeyUp(for: .init(action)) {
                action.post()
            }
        }
    }

    private func defaultShortcutForAction(_ action: WindowAction) -> Shortcut? {
        print(#function, "called")
        if Defaults.alternateDefaultShortcuts.enabled {
            return action.alternateDefault
        } else {
            return action.spectacleDefault
        }
    }

    // MARK: - Notifications

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

    @objc private func windowActionTriggered(notification: NSNotification) {
        print(#function, "called")
        guard var parameters = notification.object as? ExecutionParameters else {
            return
        }

        if MultiWindowManager.execute(parameters: parameters) { return }
        if TodoManager.execute(parameters: parameters) { return }

        parameters = adjustParametersForCycleMonitorIfNeeded(parameters)
        windowManager.execute(parameters)
    }

    // MARK: - Cycle Monitor Logic

    private func adjustParametersForCycleMonitorIfNeeded(_ parameters: ExecutionParameters) -> ExecutionParameters {
        print(#function, "called")
        guard Defaults.subsequentExecutionMode.value == .cycleMonitor else {
            return parameters
        }

        guard parameters.action.classification != .size,
              parameters.action.classification != .display else {
            return parameters
        }

        guard let windowElement = parameters.windowElement ?? AccessibilityElement.getFrontWindowElement(),
              let windowId = parameters.windowId ?? windowElement.getWindowId() else {
            NSSound.beep()
            return parameters
        }

        guard isRepeatAction(parameters: parameters, windowElement: windowElement, windowId: windowId) else {
            return parameters
        }

        guard let nextScreen = ScreenDetection()
            .detectScreens(using: windowElement)?
            .adjacentScreens?
            .next else {
            return parameters
        }

        let updated = ExecutionParameters(
            parameters.action,
            updateRestoreRect: parameters.updateRestoreRect,
            screen: nextScreen,
            windowElement: windowElement,
            windowId: windowId
        )

        AppDelegate.windowHistory.lasttiny_window_managerActions.removeValue(forKey: windowId)
        return updated
    }

    private func isRepeatAction(parameters: ExecutionParameters,
                                windowElement: AccessibilityElement,
                                windowId: CGWindowID) -> Bool {
        print(#function, "called")

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

        let lastAction = AppDelegate.windowHistory.lasttiny_window_managerActions[windowId]?.action
        return parameters.action == lastAction
    }
}
