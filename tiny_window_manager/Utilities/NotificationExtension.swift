//
//  NotificationExtension.swift
//  tiny_window_manager
//
//  Convenience extensions for working with NotificationCenter.
//
//  WHAT IS NOTIFICATIONCENTER?
//  NotificationCenter is Apple's publish-subscribe messaging system. It allows
//  different parts of an app to communicate without knowing about each other:
//
//    1. POSTING: One part of the app "posts" a notification (broadcasts a message)
//    2. OBSERVING: Other parts "observe" (listen for) that notification and react
//
//  This is useful for decoupling code - the sender doesn't need to know who's listening.
//
//  EXAMPLE FLOW:
//    - User toggles a setting → Settings screen posts .windowSnapping notification
//    - Window manager observes .windowSnapping → Updates its behavior accordingly
//
//  WHY THIS EXTENSION?
//  Apple's NotificationCenter API is verbose. Instead of:
//    NotificationCenter.default.post(name: .windowSnapping, object: nil)
//  We can write:
//    Notification.Name.windowSnapping.post()
//

import Cocoa

// MARK: - Notification.Name Extension

extension Notification.Name {

    // MARK: - Custom Notification Names

    // These are the app's custom notification "channels".
    // Each represents a specific event that parts of the app can broadcast or listen to.

    /// Posted when the user imports a configuration file.
    static let configImported = Notification.Name("configImported")

    /// Posted when the window snapping setting changes.
    static let windowSnapping = Notification.Name("windowSnapping")

    /// Posted when the frontmost application changes.
    static let frontAppChanged = Notification.Name("frontAppChanged")

    /// Posted when the "allow any shortcut" setting is toggled.
    static let allowAnyShortcut = Notification.Name("allowAnyShortcutToggle")

    /// Posted when any default setting changes.
    static let changeDefaults = Notification.Name("changeDefaults")

    /// Posted when the todo menu is toggled on or off.
    static let todoMenuToggled = Notification.Name("todoMenuToggled")

    /// Posted just before the app becomes the active (frontmost) app.
    static let appWillBecomeActive = Notification.Name("appWillBecomeActive")

    /// Posted when Mission Control dragging state changes.
    static let missionControlDragging = Notification.Name("missionControlDragging")

    /// Posted when the menu bar icon visibility changes.
    static let menuBarIconHidden = Notification.Name("menuBarIconHidden")

    /// Posted when window title bar settings change.
    static let windowTitleBar = Notification.Name("windowTitleBar")

    /// Posted when default snap areas are modified.
    static let defaultSnapAreas = Notification.Name("defaultSnapAreas")

    // MARK: - Posting Notifications

    /// Posts this notification to the specified notification center.
    ///
    /// This is a convenience method that makes posting notifications more readable.
    ///
    /// - Parameters:
    ///   - center: The notification center to post to. Defaults to `.default` (the main one).
    ///   - object: An optional object to send with the notification (the "sender").
    ///   - userInfo: An optional dictionary of additional data to include.
    ///
    /// Example usage:
    /// ```
    /// // Simple post with no data:
    /// Notification.Name.windowSnapping.post()
    ///
    /// // Post with an object (e.g., the new value):
    /// Notification.Name.windowSnapping.post(object: true)
    ///
    /// // Post with additional data:
    /// Notification.Name.configImported.post(userInfo: ["path": filePath])
    /// ```
    ///
    func post(
        center: NotificationCenter = NotificationCenter.default,
        object: Any? = nil,
        userInfo: [AnyHashable: Any]? = nil
    ) {
        center.post(name: self, object: object, userInfo: userInfo)
    }

    // MARK: - Observing Notifications

    /// Registers a handler to be called whenever this notification is posted.
    ///
    /// This is a convenience method that makes observing notifications more readable.
    ///
    /// - Parameters:
    ///   - center: The notification center to observe. Defaults to `.default`.
    ///   - object: Only receive notifications posted by this object. Nil = any sender.
    ///   - queue: The operation queue to run the handler on. Nil = same queue as poster.
    ///   - using: The closure to call when the notification is received.
    ///
    /// - Returns: An observer object. Keep a reference to this if you need to
    ///            remove the observer later. Marked @discardableResult so you
    ///            can ignore it if you want the observer to live forever.
    ///
    /// Example usage:
    /// ```
    /// // Basic observation:
    /// Notification.Name.windowSnapping.onPost { notification in
    ///     print("Window snapping changed!")
    /// }
    ///
    /// // Observation that extracts data from the notification:
    /// Notification.Name.windowSnapping.onPost { notification in
    ///     if let isEnabled = notification.object as? Bool {
    ///         self.updateSnapping(enabled: isEnabled)
    ///     }
    /// }
    ///
    /// // Observation on the main queue (for UI updates):
    /// Notification.Name.configImported.onPost(queue: .main) { _ in
    ///     self.refreshUI()
    /// }
    /// ```
    ///
    @discardableResult
    func onPost(
        center: NotificationCenter = NotificationCenter.default,
        object: Any? = nil,
        queue: OperationQueue? = nil,
        using: @escaping (Notification) -> Void
    ) -> NSObjectProtocol {
        // Register the observer with NotificationCenter
        // This returns an opaque observer token that can be used to remove the observer later
        return center.addObserver(
            forName: self,
            object: object,
            queue: queue,
            using: using
        )
    }
}

