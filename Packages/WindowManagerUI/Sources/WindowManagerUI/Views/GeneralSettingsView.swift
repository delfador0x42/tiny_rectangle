//  GeneralSettingsView.swift - General settings view
//
//  SwiftUI view for configuring app-wide settings.

import SwiftUI
import WindowManagerCore

// MARK: - GeneralSettingsView

/// Displays and allows configuration of general app settings.
public struct GeneralSettingsView<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                GeneralSection(viewModel: viewModel)
                Divider()
                WindowGapsSection(viewModel: viewModel)
                Divider()
                CursorAndDisplaySection(viewModel: viewModel)
                Divider()
                TitleBarSection(viewModel: viewModel)
                Divider()
                TodoModeSection(viewModel: viewModel)
                if viewModel.stageManagerSupported {
                    Divider()
                    StageManagerSection(viewModel: viewModel)
                }
                Divider()
                ImportExportSection(viewModel: viewModel)
                Spacer()
            }
            .padding(24)
        }
    }
}

// MARK: - General Section

private struct GeneralSection<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)

            Toggle("Launch at login", isOn: $viewModel.launchOnLogin)

            Toggle("Hide menu bar icon", isOn: $viewModel.hideMenuBarIcon)

            Toggle("Allow any shortcut (bypass system shortcut validation)", isOn: $viewModel.allowAnyShortcut)

            HStack {
                Text("Repeated shortcut action:")
                Picker("", selection: $viewModel.subsequentMode) {
                    ForEach(SubsequentMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            HStack(spacing: 16) {
                Text(viewModel.versionString)
                    .foregroundColor(.secondary)
                    .font(.caption)

                Button("Check for Updates...") {
                    viewModel.checkForUpdates()
                }
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Window Gaps Section

private struct WindowGapsSection<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Window Gaps")
                .font(.headline)

            HStack {
                Text("Gap between windows:")
                Slider(value: $viewModel.gapSize, in: 0...30, step: 1)
                    .frame(width: 150)
                Text("\(Int(viewModel.gapSize)) px")
                    .frame(width: 50, alignment: .trailing)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Cursor and Display Section

private struct CursorAndDisplaySection<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cursor & Display")
                .font(.headline)

            Toggle("Move cursor when moving windows across displays", isOn: $viewModel.moveCursorAcrossDisplays)

            Toggle("Use cursor position for screen detection", isOn: $viewModel.useCursorScreenDetection)
        }
    }
}

// MARK: - Title Bar Section

private struct TitleBarSection<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Title Bar")
                .font(.headline)

            Toggle("Double-click title bar to maximize", isOn: $viewModel.doubleClickToMaximize)
        }
    }
}

// MARK: - Todo Mode Section

private struct TodoModeSection<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Todo Mode")
                    .font(.headline)

                Button {
                    // Show help
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.plain)
            }

            Toggle("Enable Todo Mode (pin an app as sidebar)", isOn: $viewModel.todoEnabled)

            if viewModel.todoEnabled {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sidebar width:")
                        TextField("Width", value: $viewModel.todoWidth, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)

                        Picker("", selection: $viewModel.todoWidthUnit) {
                            ForEach(TodoWidthUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 60)

                        Text("on")

                        Picker("", selection: $viewModel.todoSide) {
                            ForEach(TodoSide.allCases, id: \.self) { side in
                                Text(side.displayName).tag(side)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 80)
                    }
                }
                .padding(.leading, 20)
            }
        }
    }
}

// MARK: - Stage Manager Section

private struct StageManagerSection<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stage Manager")
                .font(.headline)

            HStack {
                Text("Stage strip size:")
                Slider(value: $viewModel.stageSize, in: 0...300, step: 10)
                    .frame(width: 150)
                Text("\(Int(viewModel.stageSize)) px")
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

private struct ImportExportSection<ViewModel: SettingsViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Export Settings...") {
                    viewModel.exportSettings()
                }

                Button("Import Settings...") {
                    viewModel.importSettings()
                }

                Button("Restore Defaults...") {
                    viewModel.restoreDefaults()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView(viewModel: PreviewSettingsViewModel())
        .frame(width: 600, height: 700)
}
