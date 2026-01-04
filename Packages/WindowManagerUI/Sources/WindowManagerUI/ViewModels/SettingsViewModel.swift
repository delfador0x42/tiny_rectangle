//  SettingsViewModel.swift - View model for general settings
//
//  Provides an abstraction for the settings view to read and write
//  app settings.

import SwiftUI
import WindowManagerCore

// MARK: - Subsequent Execution Mode

/// How the app behaves when the same shortcut is pressed repeatedly.
public enum SubsequentMode: Int, CaseIterable, Sendable {
    case none = 0
    case resize = 1
    case acrossMonitor = 2
    case acrossAndResize = 3
    case cycleMonitor = 4

    public var displayName: String {
        switch self {
        case .none: return "Do nothing"
        case .resize: return "Cycle sizes"
        case .acrossMonitor: return "Move across monitors"
        case .acrossAndResize: return "Across + Resize"
        case .cycleMonitor: return "Cycle monitors"
        }
    }
}

// MARK: - Todo Sidebar Settings

/// Which side the todo sidebar appears on.
public enum TodoSide: Int, CaseIterable, Sendable {
    case left = 0
    case right = 1

    public var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

/// Unit for the todo sidebar width.
public enum TodoWidthUnit: Int, CaseIterable, Sendable {
    case pixels = 0
    case percentage = 1

    public var displayName: String {
        switch self {
        case .pixels: return "px"
        case .percentage: return "%"
        }
    }
}

// MARK: - SettingsViewModelProtocol

/// Protocol for settings view models.
///
/// Implement this to provide settings data to the GeneralSettingsView.
public protocol SettingsViewModelProtocol: ObservableObject {
    // General settings
    var launchOnLogin: Bool { get set }
    var hideMenuBarIcon: Bool { get set }
    var allowAnyShortcut: Bool { get set }
    var subsequentMode: SubsequentMode { get set }

    // Gap settings
    var gapSize: Float { get set }

    // Cursor & Display settings
    var moveCursorAcrossDisplays: Bool { get set }
    var useCursorScreenDetection: Bool { get set }

    // Title bar settings
    var doubleClickToMaximize: Bool { get set }

    // Todo mode settings
    var todoEnabled: Bool { get set }
    var todoWidth: Float { get set }
    var todoWidthUnit: TodoWidthUnit { get set }
    var todoSide: TodoSide { get set }

    // Stage manager settings
    var stageManagerSupported: Bool { get }
    var stageSize: Float { get set }

    // Actions
    func checkForUpdates()
    func exportSettings()
    func importSettings()
    func restoreDefaults()

    // Version info
    var versionString: String { get }
}

// MARK: - Preview Implementation

/// A preview implementation for SwiftUI previews.
public class PreviewSettingsViewModel: SettingsViewModelProtocol {
    @Published public var launchOnLogin = false
    @Published public var hideMenuBarIcon = false
    @Published public var allowAnyShortcut = false
    @Published public var subsequentMode = SubsequentMode.resize

    @Published public var gapSize: Float = 10

    @Published public var moveCursorAcrossDisplays = false
    @Published public var useCursorScreenDetection = true

    @Published public var doubleClickToMaximize = false

    @Published public var todoEnabled = false
    @Published public var todoWidth: Float = 400
    @Published public var todoWidthUnit = TodoWidthUnit.pixels
    @Published public var todoSide = TodoSide.left

    public var stageManagerSupported = true
    @Published public var stageSize: Float = 150

    public var versionString = "v1.0.0 (100)"

    public init() {}

    public func checkForUpdates() {}
    public func exportSettings() {}
    public func importSettings() {}
    public func restoreDefaults() {}
}
