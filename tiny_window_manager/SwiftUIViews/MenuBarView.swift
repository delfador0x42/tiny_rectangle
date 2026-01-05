//
//  MenuBarView.swift
//  tiny_window_manager
//
//  SwiftUI menu content for the MenuBarExtra.
//  Replaces the AppKit NSMenu-based status menu.
//
//  Uses the modern @Observable macro (macOS 14+) for cleaner state management.
//

import SwiftUI
import WindowManagerCore

// MARK: - Menu State

/// Observable state for the menu bar, shared between SwiftUI and AppKit components.
/// Uses the modern @Observable macro for automatic change tracking without @Published.
///
/// Access via AppServices:
/// - SwiftUI: `@Environment(AppServices.self) var services`
/// - AppKit: `AppServices.shared.menuBarState`
@Observable @MainActor
final class MenuBarState {
    /// Legacy accessor - use AppServices.shared.menuBarState instead for new code.
    static var shared: MenuBarState { AppServices.shared.menuBarState }

    var isAccessibilityAuthorized = false
    var isMenuBarVisible = true
    var frontAppName: String?
    var isAppIgnored = false
    var hasFrontWindow = false
    var screenCount = 1
    var isPortrait = false

    // Todo mode state
    var todoEnabled = false
    var todoModeActive = false
    var todoAppIsActive = false
    var isTodoWindowFront = false

    init() {
        // Initialize with safe defaults only - don't call refresh() here
        // because ApplicationToggle and other objects may not exist yet.
        // The menu's onAppear will call refresh() when actually shown.
        isMenuBarVisible = !Defaults.hideMenuBarIcon.enabled
    }

    /// Updates menu bar visibility based on user preference.
    func refreshVisibility() {
        isMenuBarVisible = !Defaults.hideMenuBarIcon.enabled
    }

    /// Refreshes all state from current system state.
    /// Safe to call at any time - guards against early initialization.
    func refresh() {
        // Guard against being called before AppDelegate is ready
        guard let appDelegate = NSApp.delegate as? AppDelegate,
              appDelegate.applicationToggle != nil else {
            return
        }

        frontAppName = ApplicationToggle.frontAppName
        isAppIgnored = ApplicationToggle.shortcutsDisabled
        hasFrontWindow = AccessibilityElement.getFrontWindowElement() != nil
        screenCount = NSScreen.screens.count
        isPortrait = NSScreen.main?.frame.isLandscape == false

        todoEnabled = Defaults.todo.userEnabled
        todoModeActive = Defaults.todoMode.enabled
        todoAppIsActive = appDelegate.applicationToggle?.todoAppIsActive() ?? false
        isTodoWindowFront = TodoManager.isTodoWindowFront()
    }
}

// MARK: - Main Menu View

/// The main menu content shown when the app is authorized.
struct MainMenuView: View {
    private var state: MenuBarState { .shared }
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        // Window Actions
        WindowActionsMenu()

        Divider()

        // Todo Mode Section
        if state.todoEnabled {
            TodoModeMenuSection()
            Divider()
        }

        // Ignore App
        if let appName = state.frontAppName {
            Toggle("Ignore \(appName)", isOn: Binding(
                get: { state.isAppIgnored },
                set: { _ in toggleIgnoreApp() }
            ))
        }

        Divider()

        // Standard Items
        Button("Preferences...") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Check for Updates...") {
            AppDelegate.updaterController.checkForUpdates(nil)
        }

        Button("About tiny_window_manager") {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.orderFrontStandardAboutPanel(nil)
        }

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    private func toggleIgnoreApp() {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        if state.isAppIgnored {
            appDelegate.applicationToggle.enableApp()
        } else {
            appDelegate.applicationToggle.disableApp()
        }
        state.refresh()
    }
}

// MARK: - Window Actions Menu

/// Menu section containing all window action items.
struct WindowActionsMenu: View {
    private var state: MenuBarState { .shared }

    var body: some View {
        let showAllActions = Defaults.showAllActionsInMenu.userEnabled

        if showAllActions {
            // Flat list of all actions
            FlatWindowActionsView()
        } else {
            // Grouped into category submenus
            GroupedWindowActionsView()
        }
    }
}

/// Flat list of window actions (when "Show All Actions" is enabled).
struct FlatWindowActionsView: View {
    private var state: MenuBarState { .shared }

    var body: some View {
        let actions = WindowAction.active.filter { $0.displayName != nil }

        ForEach(groupedActions(actions), id: \.0) { group in
            if group.0 > 0 {
                Divider()
            }
            ForEach(group.1, id: \.rawValue) { action in
                WindowActionButton(action: action)
            }
        }
    }

    /// Groups actions by their firstInGroup property.
    private func groupedActions(_ actions: [WindowAction]) -> [(Int, [WindowAction])] {
        var groups: [(Int, [WindowAction])] = []
        var currentGroup: [WindowAction] = []
        var groupIndex = 0

        for action in actions {
            if action.firstInGroup && !currentGroup.isEmpty {
                groups.append((groupIndex, currentGroup))
                currentGroup = []
                groupIndex += 1
            }
            currentGroup.append(action)
        }

        if !currentGroup.isEmpty {
            groups.append((groupIndex, currentGroup))
        }

        return groups
    }
}

/// Grouped window actions in category submenus.
struct GroupedWindowActionsView: View {
    var body: some View {
        let categories = categorizedActions()

        ForEach(categories, id: \.category) { group in
            Menu(group.category.displayName) {
                ForEach(group.actions, id: \.rawValue) { action in
                    WindowActionButton(action: action)
                }
            }
        }
    }

    private func categorizedActions() -> [(category: WindowActionCategory, actions: [WindowAction])] {
        var result: [(WindowActionCategory, [WindowAction])] = []
        var currentCategory: WindowActionCategory?
        var currentActions: [WindowAction] = []

        for action in WindowAction.active {
            guard action.displayName != nil, let category = action.category else { continue }

            if category != currentCategory {
                if let cat = currentCategory, !currentActions.isEmpty {
                    result.append((cat, currentActions))
                }
                currentCategory = category
                currentActions = []
            }
            currentActions.append(action)
        }

        if let cat = currentCategory, !currentActions.isEmpty {
            result.append((cat, currentActions))
        }

        return result
    }
}

/// A single window action button.
struct WindowActionButton: View {
    let action: WindowAction
    private var state: MenuBarState { .shared }

    var body: some View {
        Button {
            action.postMenu()
        } label: {
            Label {
                Text(action.displayName ?? action.name)
            } icon: {
                actionImage
            }
        }
        .disabled(!isEnabled)
    }

    private var isEnabled: Bool {
        if !state.hasFrontWindow { return false }
        if state.screenCount == 1 && (action == .nextDisplay || action == .previousDisplay) {
            return false
        }
        return true
    }

    @ViewBuilder
    private var actionImage: some View {
        if let nsImage = action.image.copy() as? NSImage {
            Image(nsImage: nsImage)
        }
    }
}

// MARK: - Todo Mode Section

/// Menu section for todo mode controls.
struct TodoModeMenuSection: View {
    private var state: MenuBarState { .shared }

    var body: some View {
        Toggle("Enable Todo Mode", isOn: Binding(
            get: { state.todoModeActive },
            set: { enabled in
                TodoManager.setTodoMode(enabled)
                state.refresh()
            }
        ))

        if let appName = state.frontAppName, !state.todoAppIsActive {
            Button("Use \(appName) as Todo App") {
                guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
                appDelegate.applicationToggle.setTodoApp()
                TodoManager.moveAllIfNeeded()
                state.refresh()
            }
        }

        if state.todoAppIsActive && !state.isTodoWindowFront {
            Button("Use as Todo Window") {
                TodoManager.resetTodoWindow()
                TodoManager.moveAllIfNeeded()
                state.refresh()
            }
        }

        Button("Reflow Todo") {
            TodoManager.moveAll()
        }
        .disabled(!state.todoModeActive)
    }
}

// MARK: - Unauthorized Menu View

/// Menu shown when accessibility permissions are not yet granted.
struct UnauthorizedMenuView: View {
    var body: some View {
        Button("Authorize Accessibility...") {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.authorizeAccessibility(self)
            }
        }

        Divider()

        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
