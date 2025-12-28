//
//  tiny_window_managerStatusItem.swift
//  tiny_window_manager
//
//  This class manages the app's menu bar icon (the small icon in the top-right of macOS).
//  It handles showing, hiding, and clicking the status item.
//

import Cocoa

/// Manages the app's presence in the macOS menu bar.
/// Uses the Singleton pattern - access via `tiny_window_managerStatusItem.instance`
class tiny_window_managerStatusItem {

    // MARK: - Singleton

    /// The single shared instance of this class.
    /// Usage: `tiny_window_managerStatusItem.instance.refreshVisibility()`
    static let instance = tiny_window_managerStatusItem()

    // MARK: - Properties

    /// The actual macOS status bar item (the icon you see in the menu bar)
    private var nsStatusItem: NSStatusItem?

    /// Tracks whether the status item is currently added to the menu bar
    private var isCurrentlyInMenuBar: Bool = false

    /// Watches for changes to the status item's visibility (e.g., user drags it off)
    private var visibilityObserver: NSKeyValueObservation?

    /// The menu that appears when the user clicks the status item.
    /// When you set this, it automatically updates the underlying NSStatusItem.
    public var statusMenu: NSMenu? {
        didSet {
            nsStatusItem?.menu = statusMenu
        }
    }

    // MARK: - Initialization

    /// Private init enforces the singleton pattern - you can't create new instances
    private init() {}

    // MARK: - Public Methods

    /// Shows or hides the menu bar icon based on user preferences.
    /// Call this when the app launches or when the user changes their preference.
    public func refreshVisibility() {
        let shouldHideIcon = Defaults.hideMenuBarIcon.enabled

        if shouldHideIcon {
            removeFromMenuBar()
        } else {
            addToMenuBar()
        }
    }

    /// Programmatically opens the status item's menu.
    /// Temporarily shows the icon if it's hidden, opens the menu, then respects visibility settings.
    public func openMenu() {
        // Make sure the icon exists before trying to click it
        if !isCurrentlyInMenuBar {
            addToMenuBar()
        }

        // Simulate a click on the status item to open the menu
        nsStatusItem?.button?.performClick(self)

        // After the menu closes, hide the icon again if user prefers it hidden
        refreshVisibility()
    }

    // MARK: - Private Methods

    /// Creates and adds the status item to the macOS menu bar
    private func addToMenuBar() {
        isCurrentlyInMenuBar = true

        // Create the status item with automatic width based on content
        nsStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Configure the status item
        configureStatusItem()

        // Watch for when user manually hides the icon (cmd+drag off menu bar)
        startObservingVisibilityChanges()

        // Make it visible
        nsStatusItem?.isVisible = true
    }

    /// Configures the status item's appearance and behavior
    private func configureStatusItem() {
        // Set the icon image (should be a template image for proper dark/light mode support)
        nsStatusItem?.button?.image = NSImage(named: "StatusTemplate")

        // Attach the dropdown menu
        nsStatusItem?.menu = statusMenu

        // Allow user to remove this icon by cmd+dragging it off the menu bar
        nsStatusItem?.behavior = .removalAllowed
    }

    /// Sets up an observer to detect when the user manually hides the icon
    private func startObservingVisibilityChanges() {
        visibilityObserver = nsStatusItem?.observe(\.isVisible, options: [.old, .new]) { [weak self] _, change in
            self?.handleVisibilityChange(oldValue: change.oldValue, newValue: change.newValue)
        }
    }

    /// Called when the status item's visibility changes
    private func handleVisibilityChange(oldValue: Bool?, newValue: Bool?) {
        let wasVisible = oldValue == true
        let isNowHidden = newValue == false

        // User manually dragged the icon off the menu bar
        if wasVisible && isNowHidden {
            // Notify other parts of the app
            Notification.Name.menuBarIconHidden.post()

            // Remember this preference so it stays hidden on next launch
            Defaults.hideMenuBarIcon.enabled = true
        }
    }

    /// Removes the status item from the macOS menu bar
    private func removeFromMenuBar() {
        isCurrentlyInMenuBar = false

        // Only remove if it exists
        guard let statusItem = nsStatusItem else { return }

        NSStatusBar.system.removeStatusItem(statusItem)
    }
}
