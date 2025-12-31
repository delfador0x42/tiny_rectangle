//
//  GeneralSettingsView.swift
//  tiny_window_manager
//
//  SwiftUI replacement for SettingsViewController.
//  Manages all app-wide settings (not keyboard shortcuts for window actions).
//

import SwiftUI
import ServiceManagement
import Sparkle

// MARK: - General Settings View

struct GeneralSettingsView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GeneralSection()
                Divider()
                WindowGapsSection()
                Divider()
                CursorAndDisplaySection()
                Divider()
                TitleBarSection()
                Divider()
                TodoModeSection()
                Divider()
                if StageUtil.stageCapable {
                    StageManagerSection()
                    Divider()
                }
                ImportExportSection()
                Spacer()
            }
            .padding(24)
        }
    }
}

// MARK: - General Section

private struct GeneralSection: View {
    @State private var launchOnLogin = Defaults.launchOnLogin.enabled
    @State private var hideMenuBarIcon = Defaults.hideMenuBarIcon.enabled
    @State private var allowAnyShortcut = Defaults.allowAnyShortcut.enabled
    @State private var subsequentMode = Defaults.subsequentExecutionMode.value

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)

            Toggle("Launch at login", isOn: $launchOnLogin)
                .onChange(of: launchOnLogin) { _, newValue in
                    setLaunchOnLogin(newValue)
                }

            Toggle("Hide menu bar icon", isOn: $hideMenuBarIcon)
                .onChange(of: hideMenuBarIcon) { _, newValue in
                    Defaults.hideMenuBarIcon.enabled = newValue
                    tiny_window_managerStatusItem.instance.refreshVisibility()
                }

            Toggle("Allow any shortcut (bypass system shortcut validation)", isOn: $allowAnyShortcut)
                .onChange(of: allowAnyShortcut) { _, newValue in
                    Defaults.allowAnyShortcut.enabled = newValue
                    Notification.Name.allowAnyShortcut.post(object: newValue)
                }

            HStack {
                Text("Repeated shortcut action:")
                Picker("", selection: $subsequentMode) {
                    Text("Cycle sizes").tag(SubsequentExecutionMode.resize)
                    Text("Move across monitors").tag(SubsequentExecutionMode.acrossMonitor)
                    Text("Do nothing").tag(SubsequentExecutionMode.none)
                    Text("Across + Resize").tag(SubsequentExecutionMode.acrossAndResize)
                    Text("Cycle monitors").tag(SubsequentExecutionMode.cycleMonitor)
                }
                .labelsHidden()
                .frame(width: 180)
                .onChange(of: subsequentMode) { _, newValue in
                    Defaults.subsequentExecutionMode.value = newValue
                }
            }

            // Version and updates
            HStack(spacing: 16) {
                Text(versionString)
                    .foregroundColor(.secondary)
                    .font(.caption)

                Button("Check for Updates...") {
                    AppDelegate.updaterController.checkForUpdates(nil)
                }
            }
            .padding(.top, 8)
        }
    }

    private var versionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "v\(version) (\(build))"
    }

    private func setLaunchOnLogin(_ enabled: Bool) {
        LaunchOnLogin.isEnabled = enabled
        Defaults.launchOnLogin.enabled = enabled
    }
}

// MARK: - Window Gaps Section

private struct WindowGapsSection: View {
    @State private var gapSize: Float = Defaults.gapSize.value

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Window Gaps")
                .font(.headline)

            HStack {
                Text("Gap between windows:")
                Slider(value: $gapSize, in: 0...30, step: 1) { editing in
                    if !editing {
                        Defaults.gapSize.value = gapSize
                    }
                }
                .frame(width: 150)
                Text("\(Int(gapSize)) px")
                    .frame(width: 50, alignment: .trailing)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Cursor and Display Section

private struct CursorAndDisplaySection: View {
    @State private var moveCursorAcross = Defaults.moveCursorAcrossDisplays.userEnabled
    @State private var useCursorDetection = Defaults.useCursorScreenDetection.enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cursor & Display")
                .font(.headline)

            Toggle("Move cursor when moving windows across displays", isOn: $moveCursorAcross)
                .onChange(of: moveCursorAcross) { _, newValue in
                    Defaults.moveCursorAcrossDisplays.enabled = newValue
                }

            Toggle("Use cursor position for screen detection", isOn: $useCursorDetection)
                .onChange(of: useCursorDetection) { _, newValue in
                    Defaults.useCursorScreenDetection.enabled = newValue
                }
        }
    }
}

// MARK: - Title Bar Section

private struct TitleBarSection: View {
    @State private var doubleClickEnabled: Bool = WindowAction(rawValue: Defaults.doubleClickTitleBar.value - 1) != nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Title Bar")
                .font(.headline)

            Toggle("Double-click title bar to maximize", isOn: $doubleClickEnabled)
                .onChange(of: doubleClickEnabled) { _, newValue in
                    if newValue && !TitleBarManager.systemSettingDisabled {
                        showConflictAlert()
                    }
                    Defaults.doubleClickTitleBar.value = (newValue ? WindowAction.maximize.rawValue : -1) + 1
                    Notification.Name.windowTitleBar.post()
                }
        }
    }

    private func showConflictAlert() {
        let alert = NSAlert()
        alert.messageText = "Conflict with system setting"
        alert.informativeText = "To let tiny_window_manager manage the title bar double click functionality, you need to disable the corresponding macOS setting."
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Close")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.dock")!)
        }
    }
}

// MARK: - Todo Mode Section

private struct TodoModeSection: View {
    @State private var todoEnabled = Defaults.todo.userEnabled
    @State private var todoWidth: String = String(Int(Defaults.todoSidebarWidth.value))
    @State private var todoWidthUnit = Defaults.todoSidebarWidthUnit.value
    @State private var todoSide = Defaults.todoSidebarSide.value

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Todo Mode")
                    .font(.headline)

                Button {
                    showTodoHelp()
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
            }

            Toggle("Enable Todo Mode (pin an app as sidebar)", isOn: $todoEnabled)
                .onChange(of: todoEnabled) { _, newValue in
                    Defaults.todo.enabled = newValue
                    Notification.Name.todoMenuToggled.post()
                }

            if todoEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    // Width settings
                    HStack {
                        Text("Sidebar width:")
                        TextField("Width", text: $todoWidth)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: todoWidth) { _, newValue in
                                if let value = Float(newValue) {
                                    Defaults.todoSidebarWidth.value = value
                                    TodoManager.moveAllIfNeeded(false)
                                }
                            }

                        Picker("", selection: $todoWidthUnit) {
                            Text("px").tag(TodoSidebarWidthUnit.pixels)
                            //Text("%").tag(TodoSidebarWidthUnit.percentage)
                        }
                        .labelsHidden()
                        .frame(width: 60)
                        .onChange(of: todoWidthUnit) { _, newValue in
                            Defaults.todoSidebarWidthUnit.value = newValue
                            TodoManager.refreshTodoScreen()
                            if let visibleFrameWidth = TodoManager.todoScreen?.visibleFrame.width {
                                let converted = TodoManager.convert(
                                    width: Defaults.todoSidebarWidth.cgFloat,
                                    toUnit: newValue,
                                    visibleFrameWidth: visibleFrameWidth
                                )
                                Defaults.todoSidebarWidth.value = Float(converted)
                                todoWidth = String(Int(converted))
                            }
                            TodoManager.moveAllIfNeeded(false)
                        }

                        Text("on")

                        Picker("", selection: $todoSide) {
                            Text("Left").tag(TodoSidebarSide.left)
                            Text("Right").tag(TodoSidebarSide.right)
                        }
                        .labelsHidden()
                        .frame(width: 80)
                        .onChange(of: todoSide) { _, newValue in
                            Defaults.todoSidebarSide.value = newValue
                            TodoManager.moveAllIfNeeded(false)
                        }
                    }

                    // Shortcuts removed - todo shortcuts are no longer supported
                }
                .padding(.leading, 20)
            }
        }
    }

    private func showTodoHelp() {
        let alert = NSAlert()
        alert.messageText = "About Todo Mode"
        alert.informativeText = """
        Todo Mode reserves a portion of your screen for a designated app (like a todo list or notes app).

        When enabled:
        - A sidebar is pinned to the left or right edge
        - Other windows automatically avoid that area
        - Use the Toggle shortcut to show/hide
        - Use the Reflow shortcut to rearrange windows
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Stage Manager Section

private struct StageManagerSection: View {
    @State private var stageSize: Float = max(0, Defaults.stageSize.value)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stage Manager")
                .font(.headline)

            HStack {
                Text("Stage strip size:")
                Slider(value: $stageSize, in: 0...300, step: 10) { editing in
                    if !editing {
                        Defaults.stageSize.value = stageSize == 0 ? -1 : stageSize
                    }
                }
                .frame(width: 150)
                Text("\(Int(stageSize)) px")
                    .frame(width: 50, alignment: .trailing)
                    .monospacedDigit()
            }

            Text("Set to 0 to use system default")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Import/Export Section

private struct ImportExportSection: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Export Settings...") {
                    exportConfig()
                }

                Button("Import Settings...") {
                    importConfig()
                }

                Button("Restore Defaults...") {
                    restoreDefaults()
                }
            }
        }
    }

    private func exportConfig() {
        Notification.Name.windowSnapping.post(object: false)

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "tiny_window_managerConfig"

        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let jsonString = Defaults.encoded() {
                try? jsonString.write(to: url, atomically: false, encoding: .utf8)
            }
        }

        Notification.Name.windowSnapping.post(object: true)
    }

    private func importConfig() {
        Notification.Name.windowSnapping.post(object: false)

        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]

        if openPanel.runModal() == .OK, let url = openPanel.url {
            Defaults.load(fileUrl: url)
        }

        Notification.Name.windowSnapping.post(object: true)
    }

    private func restoreDefaults() {
        let alert = NSAlert()
        alert.messageText = "Restore Default Shortcuts"
        alert.informativeText = "Choose which default shortcut set to restore:"
        alert.addButton(withTitle: "tiny_window_manager")
        alert.addButton(withTitle: "Spectacle")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertThirdButtonReturn { return }

        // Clear all custom shortcuts
        WindowAction.active.forEach { UserDefaults.standard.removeObject(forKey: $0.name) }

        // Apply selected defaults
        let useTinyDefaults = response == .alertFirstButtonReturn
        if useTinyDefaults != Defaults.alternateDefaultShortcuts.enabled {
            Defaults.alternateDefaultShortcuts.enabled = useTinyDefaults
            Notification.Name.changeDefaults.post()
        }

        // Reset snap areas
        Defaults.portraitSnapAreas.typedValue = nil
        Defaults.landscapeSnapAreas.typedValue = nil
        Notification.Name.defaultSnapAreas.post()
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView()
        .frame(width: 600, height: 700)
}
