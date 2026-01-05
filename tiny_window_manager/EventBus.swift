//
//  EventBus.swift
//  tiny_window_manager
//
//  Modern event bus using Combine, replacing NotificationCenter patterns.
//  Provides type-safe events with Combine publishers.
//

import Combine
import Foundation

// MARK: - Event Bus

/// Central event bus for app-wide events using Combine.
///
/// This provides a modern, type-safe alternative to NotificationCenter.
///
/// Usage:
/// ```swift
/// // Posting an event
/// EventBus.shared.configImported.send()
///
/// // Subscribing to an event
/// EventBus.shared.configImported
///     .sink { _ in print("Config was imported") }
///     .store(in: &cancellables)
/// ```
@MainActor
final class EventBus {
    static let shared = EventBus()

    private init() {}

    // MARK: - Settings Events

    /// Fired when configuration/settings are imported from a file.
    let configImported = PassthroughSubject<Void, Never>()

    /// Fired when any default setting changes.
    let defaultsChanged = PassthroughSubject<Void, Never>()

    /// Fired when todo menu is toggled.
    let todoMenuToggled = PassthroughSubject<Void, Never>()

    // MARK: - Window Snapping Events

    /// Fired when window snapping is enabled/disabled.
    let windowSnappingChanged = PassthroughSubject<Bool, Never>()

    /// Fired when mission control dragging is enabled/disabled.
    let missionControlDraggingChanged = PassthroughSubject<Bool, Never>()

    /// Fired when snap areas should reset to defaults.
    let defaultSnapAreas = PassthroughSubject<Void, Never>()

    // MARK: - App State Events

    /// Fired when the frontmost application changes.
    let frontAppChanged = PassthroughSubject<Void, Never>()

    /// Fired when this app is about to become active.
    let appWillBecomeActive = PassthroughSubject<Void, Never>()

    // MARK: - Feature Toggle Events

    /// Fired when "allow any shortcut" setting changes.
    let allowAnyShortcutChanged = PassthroughSubject<Bool, Never>()

    /// Fired when title bar behavior changes.
    let titleBarSettingsChanged = PassthroughSubject<Void, Never>()

    /// Fired when menu bar icon visibility changes.
    let menuBarIconVisibilityChanged = PassthroughSubject<Bool, Never>()
}

// MARK: - Window Action Dispatcher

/// Centralized dispatcher for window actions.
///
/// This replaces the NotificationCenter-based action posting with direct method calls.
///
/// Usage:
/// ```swift
/// WindowActionDispatcher.shared.execute(action, params: params)
/// ```
@MainActor
final class WindowActionDispatcher {
    static let shared = WindowActionDispatcher()

    /// Subscribers to window actions.
    typealias ActionHandler = (WindowAction, ExecutionParameters) -> Void
    private var handlers: [ActionHandler] = []

    private init() {}

    /// Register a handler for window actions.
    func register(handler: @escaping ActionHandler) {
        handlers.append(handler)
    }

    /// Dispatch a window action to all registered handlers.
    func dispatch(_ action: WindowAction, params: ExecutionParameters) {
        for handler in handlers {
            handler(action, params)
        }
    }
}

// MARK: - NotificationCenter Bridge

/// Extension to bridge existing Notification.Name events to EventBus.
/// This allows gradual migration from NotificationCenter to EventBus.
extension EventBus {
    /// Sets up bridges from NotificationCenter to EventBus publishers.
    /// Call this once during app initialization.
    nonisolated func bridgeNotifications() {
        // Bridge configImported
        NotificationCenter.default.addObserver(
            forName: .configImported,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                EventBus.shared.configImported.send()
            }
        }

        // Bridge windowSnapping
        NotificationCenter.default.addObserver(
            forName: .windowSnapping,
            object: nil,
            queue: .main
        ) { notification in
            if let enabled = notification.object as? Bool {
                MainActor.assumeIsolated {
                    EventBus.shared.windowSnappingChanged.send(enabled)
                }
            }
        }

        // Bridge frontAppChanged
        NotificationCenter.default.addObserver(
            forName: .frontAppChanged,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                EventBus.shared.frontAppChanged.send()
            }
        }

        // Bridge todoMenuToggled
        NotificationCenter.default.addObserver(
            forName: .todoMenuToggled,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                EventBus.shared.todoMenuToggled.send()
            }
        }

        // Bridge appWillBecomeActive
        NotificationCenter.default.addObserver(
            forName: .appWillBecomeActive,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                EventBus.shared.appWillBecomeActive.send()
            }
        }
    }
}
