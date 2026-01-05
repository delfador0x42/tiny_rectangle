//
//  AppServices.swift
//  tiny_window_manager
//
//  Centralized service container for dependency injection.
//  This is a "controlled singleton" pattern - one singleton that manages dependencies.
//

import SwiftUI

// MARK: - App Services Container

/// Central container for shared application services.
///
/// This replaces scattered singletons with a single, managed dependency container.
/// - SwiftUI views access services via @Environment
/// - AppKit code accesses via AppServices.shared
///
/// Usage in SwiftUI:
/// ```swift
/// @Environment(AppServices.self) var services
/// let menuState = services.menuBarState
/// ```
///
/// Usage in AppKit:
/// ```swift
/// let menuState = AppServices.shared.menuBarState
/// ```
@Observable @MainActor
final class AppServices {
    /// The shared instance for AppKit code that can't use @Environment.
    static let shared = AppServices()

    // MARK: - Services

    /// State for the menu bar, shared between SwiftUI and AppKit.
    let menuBarState: MenuBarState

    /// History of window actions for undo/cycling.
    let windowHistory: WindowHistory

    /// Observable settings for SwiftUI views.
    let settings: ObservableSettings

    /// Calculators for window positioning.
    let simpleCalculation: SimpleCalculation
    let nextPrevDisplayCalculation: NextPrevDisplayCalculation
    let specifiedCalculation: SpecifiedCalculation

    // MARK: - Initialization

    private init() {
        self.menuBarState = MenuBarState()
        self.windowHistory = WindowHistory()
        self.settings = ObservableSettings.shared
        self.simpleCalculation = SimpleCalculation()
        self.nextPrevDisplayCalculation = NextPrevDisplayCalculation()
        self.specifiedCalculation = SpecifiedCalculation()
    }
}

// MARK: - SwiftUI Environment Integration

extension EnvironmentValues {
    /// Access to the app services container.
    @Entry var appServices: AppServices = .shared
}

// MARK: - Convenience Accessors

extension AppServices {
    /// Shorthand for menu bar state.
    var menu: MenuBarState { menuBarState }
}
