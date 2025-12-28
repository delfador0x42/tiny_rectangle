//
//  AccessibilityElement.swift
//  tiny_window_manager
//
//  Ported from Spectacle, combined with snippets from ModMove.
//
//  This file provides a Swift-friendly wrapper around macOS Accessibility APIs (AXUIElement).
//
//  WHAT IS THIS FILE FOR?
//  -----------------------
//  macOS provides "Accessibility APIs" that allow apps to inspect and control windows
//  from other applications. This is how screen readers work, and also how window managers
//  can move/resize windows that belong to other apps.
//
//  The native API (AXUIElement) is C-based and awkward to use in Swift.
//  This class wraps it to provide a cleaner, more Swift-like interface.
//
//  KEY CONCEPTS:
//  -------------
//  - AXUIElement: Apple's C-based type representing any UI element (window, button, app, etc.)
//  - Accessibility Attributes: Properties you can read/write (position, size, role, etc.)
//  - Role: What type of element this is (window, application, button, etc.)
//  - Subrole: More specific type info (e.g., a window might have subrole "systemDialog")
//
//  HOW THIS FITS IN THE APP:
//  -------------------------
//  User Action → WindowManager → WindowCalculation → WindowMover → AccessibilityElement
//                                                                        ↓
//                                                               macOS Accessibility API
//                                                                        ↓
//                                                               Window actually moves!
//

import Foundation

// MARK: - Main Class

/// A Swift wrapper around macOS Accessibility API's AXUIElement.
///
/// This class lets you interact with UI elements (windows, apps, buttons, etc.)
/// from any application on the system. You can read properties like position and size,
/// and write to them to move/resize windows.
///
/// Example usage:
/// ```swift
/// // Get the frontmost window and move it
/// if let window = AccessibilityElement.getFrontWindowElement() {
///     window.setFrame(CGRect(x: 0, y: 0, width: 800, height: 600))
/// }
/// ```
class AccessibilityElement {

    // MARK: - Properties

    /// The underlying macOS accessibility element.
    /// This is the actual C-based AXUIElement that we're wrapping.
    /// Marked `fileprivate` so subclasses (like StageWindowAccessibilityElement) can access it.
    fileprivate let wrappedElement: AXUIElement

    // MARK: - Initializers

    /// Creates an AccessibilityElement from a raw AXUIElement.
    /// This is the designated initializer - all other initializers call this one.
    ///
    /// - Parameter element: The raw macOS accessibility element to wrap.
    init(_ element: AXUIElement) {
        wrappedElement = element
    }

    /// Creates an AccessibilityElement for an application by its process ID.
    ///
    /// - Parameter pid: The process identifier of the running application.
    ///
    /// Example:
    /// ```swift
    /// let finderPid: pid_t = 123
    /// let finderApp = AccessibilityElement(finderPid)
    /// ```
    convenience init(_ pid: pid_t) {
        // AXUIElementCreateApplication is the macOS API to get an app's accessibility element
        self.init(AXUIElementCreateApplication(pid))
    }

    /// Creates an AccessibilityElement for an application by its bundle identifier.
    /// Returns nil if the app isn't running.
    ///
    /// - Parameter bundleIdentifier: The app's bundle ID (e.g., "com.apple.Safari").
    ///
    /// Example:
    /// ```swift
    /// if let safari = AccessibilityElement("com.apple.Safari") {
    ///     // Safari is running, we can interact with it
    /// }
    /// ```
    convenience init?(_ bundleIdentifier: String) {
        // Find the running app with this bundle ID
        let runningApps = NSWorkspace.shared.runningApplications
        guard let app = runningApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return nil  // App isn't running
        }
        self.init(app.processIdentifier)
    }

    /// Creates an AccessibilityElement for whatever UI element is at a screen position.
    /// Returns nil if nothing is found at that position.
    ///
    /// - Parameter position: A point in screen coordinates (top-left origin).
    ///
    /// This is useful for "what's under the mouse cursor?" queries.
    convenience init?(_ position: CGPoint) {
        guard let element = AXUIElement.systemWide.getElementAtPosition(position) else {
            return nil
        }
        self.init(element)
    }

    // MARK: - Private Helpers for Reading Attributes

    /// Reads an attribute that contains a single AXUIElement and wraps it.
    ///
    /// - Parameter attribute: The accessibility attribute to read.
    /// - Returns: The wrapped element, or nil if the attribute doesn't exist or isn't an element.
    private func getElementValue(_ attribute: NSAccessibility.Attribute) -> AccessibilityElement? {
        // Get the raw value from the wrapped element
        guard let value = wrappedElement.getValue(attribute) else { return nil }

        // Verify it's actually an AXUIElement (not some other type)
        guard CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }

        // Wrap it in our Swift class
        return AccessibilityElement(value as! AXUIElement)
    }

    /// Reads an attribute that contains an array of AXUIElements and wraps them all.
    ///
    /// - Parameter attribute: The accessibility attribute to read.
    /// - Returns: Array of wrapped elements, or nil if the attribute doesn't exist.
    private func getElementsValue(_ attribute: NSAccessibility.Attribute) -> [AccessibilityElement]? {
        guard let value = wrappedElement.getValue(attribute) else { return nil }
        guard let array = value as? [AXUIElement] else { return nil }

        // Wrap each element in the array
        return array.map { AccessibilityElement($0) }
    }

    // MARK: - Role Detection (What Type of Element Is This?)

    /// The accessibility role of this element (window, application, button, etc.).
    /// Private because callers should use the specific `isWindow`, `isApplication`, etc. checks.
    private var role: NSAccessibility.Role? {
        guard let value = wrappedElement.getValue(.role) as? String else { return nil }
        return NSAccessibility.Role(rawValue: value)
    }

    /// The accessibility subrole provides more specific type info.
    /// For example, a window might have subrole "systemDialog" for system dialogs.
    private var subrole: NSAccessibility.Subrole? {
        guard let value = wrappedElement.getValue(.subrole) as? String else { return nil }
        return NSAccessibility.Subrole(rawValue: value)
    }

    /// Returns true if this element is an application.
    private var isApplication: Bool? {
        guard let role = role else { return nil }
        return role == .application
    }

    /// Returns true if this element is a window.
    var isWindow: Bool? {
        guard let role = role else { return nil }
        return role == .window
    }

    /// Returns true if this element is a sheet (attached dialog).
    var isSheet: Bool? {
        guard let role = role else { return nil }
        return role == .sheet
    }

    /// Returns true if this element is a toolbar.
    var isToolbar: Bool? {
        guard let role = role else { return nil }
        return role == .toolbar
    }

    /// Returns true if this element is a generic group container.
    var isGroup: Bool? {
        guard let role = role else { return nil }
        return role == .group
    }

    /// Returns true if this element is a tab group.
    var isTabGroup: Bool? {
        guard let role = role else { return nil }
        return role == .tabGroup
    }

    /// Returns true if this element is static text (a label).
    var isStaticText: Bool? {
        guard let role = role else { return nil }
        return role == .staticText
    }

    /// Returns true if this element is a system dialog (like permission prompts).
    var isSystemDialog: Bool? {
        guard let subrole = subrole else { return nil }
        return subrole == .systemDialog
    }

    // MARK: - Position and Size (The Core Window Management Stuff)

    /// The position of this element's top-left corner in screen coordinates.
    /// Setting this moves the element.
    private var position: CGPoint? {
        get {
            wrappedElement.getWrappedValue(.position)
        }
        set {
            guard let newValue = newValue else { return }
            wrappedElement.setValue(.position, newValue)
            Logger.log("AX position proposed: \(newValue.debugDescription), result: \(position?.debugDescription ?? "N/A")")
        }
    }

    /// The size of this element.
    /// Setting this resizes the element.
    var size: CGSize? {
        get {
            wrappedElement.getWrappedValue(.size)
        }
        set {
            guard let newValue = newValue else { return }
            wrappedElement.setValue(.size, newValue)
            Logger.log("AX sizing proposed: \(newValue.debugDescription), result: \(size?.debugDescription ?? "N/A")")
        }
    }

    /// The frame (position + size) of this element.
    /// Returns CGRect.null if position or size can't be determined.
    var frame: CGRect {
        guard let position = position, let size = size else { return .null }
        return CGRect(origin: position, size: size)
    }

    /// Checks if this window can be resized.
    /// Some windows (like dialogs) have fixed sizes.
    ///
    /// - Returns: true if resizable, false if fixed size. Defaults to true if we can't determine.
    func isResizable() -> Bool {
        if let isResizable = wrappedElement.isValueSettable(.size) {
            return isResizable
        }
        Logger.log("Unable to determine if window is resizeable. Assuming it is.")
        return true
    }

    /// Moves and resizes this window to the specified frame.
    ///
    /// This is the main method used by WindowMover to actually move windows.
    ///
    /// WHY IS THIS COMPLICATED?
    /// The Accessibility API only allows setting size OR position, not both at once.
    /// When moving windows between displays, we have to be careful:
    /// 1. Set size first (so macOS knows we want a window this big)
    /// 2. Set position (move to new display)
    /// 3. Set size again (because macOS may have adjusted it to fit old display)
    ///
    /// - Parameters:
    ///   - frame: The target frame (position and size) for the window.
    ///   - adjustSizeFirst: If true, sets size before position. Set to false for smoother
    ///                      restore animations (slightly less accurate but less visual stutter).
    func setFrame(_ frame: CGRect, adjustSizeFirst: Bool = true) {
        // Get the application element (needed for Enhanced UI handling)
        let appElement = applicationElement
        var enhancedUIWasEnabled: Bool? = nil

        // ENHANCED UI HANDLING
        // Some apps (like Terminal) use "Enhanced User Interface" mode which can interfere
        // with window manipulation. We temporarily disable it, move the window, then re-enable.
        if let appElement = appElement {
            enhancedUIWasEnabled = appElement.enhancedUserInterface
            if enhancedUIWasEnabled == true {
                Logger.log("AXEnhancedUserInterface was enabled, will disable before resizing")
                appElement.enhancedUserInterface = false
            }
        }

        // THE ACTUAL MOVE/RESIZE SEQUENCE
        // Step 1 (optional): Set size first
        if adjustSizeFirst {
            size = frame.size
        }

        // Step 2: Set position (this actually moves the window)
        position = frame.origin

        // Step 3: Set size again (in case macOS adjusted it when we moved)
        size = frame.size

        // Restore Enhanced UI if it was enabled and user wants it re-enabled
        if Defaults.enhancedUI.value == .disableEnable,
           let appElement = appElement,
           enhancedUIWasEnabled == true {
            appElement.enhancedUserInterface = true
        }
    }

    // MARK: - Child Element Navigation

    /// All child elements of this element.
    /// For a window, this might include buttons, text fields, toolbars, etc.
    private var childElements: [AccessibilityElement]? {
        getElementsValue(.children)
    }

    /// Finds the first child element with a specific role.
    ///
    /// - Parameter role: The role to search for (e.g., .closeButton, .toolbar).
    /// - Returns: The first matching child, or nil if none found.
    func getChildElement(_ role: NSAccessibility.Role) -> AccessibilityElement? {
        return childElements?.first { $0.role == role }
    }

    /// Finds all child elements with a specific role.
    ///
    /// - Parameter role: The role to search for.
    /// - Returns: Array of matching children, or nil if none found.
    func getChildElements(_ role: NSAccessibility.Role) -> [AccessibilityElement]? {
        let matchingElements = childElements?.filter { $0.role == role }
        guard let elements = matchingElements, !elements.isEmpty else {
            return nil
        }
        return elements
    }

    /// Finds the first child element with a specific subrole.
    ///
    /// - Parameter subrole: The subrole to search for.
    /// - Returns: The first matching child, or nil if none found.
    func getChildElement(_ subrole: NSAccessibility.Subrole) -> AccessibilityElement? {
        return childElements?.first { $0.subrole == subrole }
    }

    /// Finds all child elements with a specific subrole.
    ///
    /// - Parameter subrole: The subrole to search for.
    /// - Returns: Array of matching children, or nil if none found.
    func getChildElements(_ subrole: NSAccessibility.Subrole) -> [AccessibilityElement]? {
        let matchingElements = childElements?.filter { $0.subrole == subrole }
        guard let elements = matchingElements, !elements.isEmpty else {
            return nil
        }
        return elements
    }

    /// Recursively finds the smallest child element that contains a given point.
    ///
    /// This drills down through the element hierarchy to find the most specific
    /// element at a position. Useful for precise hit-testing.
    ///
    /// - Parameter position: The screen position to search at.
    /// - Returns: The smallest element containing the position, or self if no children match.
    func getSelfOrChildElementRecursively(_ position: CGPoint) -> AccessibilityElement? {
        // Start with self as the current element
        var currentElement = self

        // Track visited elements to avoid infinite loops
        var visitedElements = Set<AccessibilityElement>()

        // Keep drilling down until we can't find a smaller child
        while true {
            // Find the smallest child that contains the position
            let smallestChild = currentElement.childElements?
                // Pair each element with its frame for filtering and sorting
                .map { (element: $0, frame: $0.frame) }
                // Only consider children that contain the position
                .filter { $0.frame.contains(position) }
                // Find the one with smallest area (most specific)
                .min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }?
                .element

            // If we found a child and haven't visited it yet, drill down
            guard let child = smallestChild, visitedElements.insert(child).inserted else {
                break
            }
            currentElement = child
        }

        return currentElement
    }

    // MARK: - Window and Process Identification

    /// The unique window ID assigned by the macOS window server.
    /// This ID is used to track windows across the system.
    var windowId: CGWindowID? {
        wrappedElement.getWindowId()
    }

    /// Gets the window ID, with a fallback to searching by frame if needed.
    ///
    /// Some accessibility elements don't directly expose their window ID,
    /// so we fall back to matching by process ID and frame geometry.
    ///
    /// - Returns: The window ID, or nil if it can't be determined.
    func getWindowId() -> CGWindowID? {
        // Try the direct approach first
        if let windowId = windowId {
            return windowId
        }

        // Fallback: search the window list for a matching window
        let currentFrame = frame
        if let pid = pid {
            // Find a window with matching PID and frame
            let matchingWindow = WindowUtil.getWindowList().first {
                $0.pid == pid && $0.frame == currentFrame
            }
            if let info = matchingWindow {
                return info.id
            }
        }

        Logger.log("Unable to obtain window id")
        return nil
    }

    /// The process ID of the application that owns this element.
    var pid: pid_t? {
        wrappedElement.getPid()
    }

    // MARK: - Window Relationships

    /// Gets the window element for this element.
    /// If this IS a window, returns self. Otherwise, finds the containing window.
    var windowElement: AccessibilityElement? {
        if isWindow == true {
            return self
        }
        return getElementValue(.window)
    }

    /// Whether this is the main (focused) window of its application.
    private var isMainWindow: Bool? {
        get {
            windowElement?.wrappedElement.getValue(.main) as? Bool
        }
        set {
            guard let newValue = newValue else { return }
            windowElement?.wrappedElement.setValue(.main, newValue)
        }
    }

    /// Whether this window is currently minimized to the Dock.
    var isMinimized: Bool? {
        windowElement?.wrappedElement.getValue(.minimized) as? Bool
    }

    /// Whether this window is in full-screen mode.
    /// Detection works by checking if the full-screen button's subrole is "zoomButton".
    var isFullScreen: Bool? {
        guard let subrole = windowElement?.getElementValue(.fullScreenButton)?.subrole else {
            return nil
        }
        return subrole == .zoomButton
    }

    /// The frame of this window's title bar.
    /// Calculated based on the close button's position.
    var titleBarFrame: CGRect? {
        guard let windowElement = windowElement else { return nil }

        let windowFrame = windowElement.frame
        guard windowFrame != .null else { return nil }

        guard let closeButtonFrame = windowElement.getChildElement(.closeButton)?.frame,
              closeButtonFrame != .null else {
            return nil
        }

        // Calculate title bar height based on close button position
        // The title bar extends from the top of the window to below the close button
        let gapAboveButton = closeButtonFrame.minY - windowFrame.minY
        let titleBarHeight = 2 * gapAboveButton + closeButtonFrame.height

        return CGRect(
            origin: windowFrame.origin,
            size: CGSize(width: windowFrame.width, height: titleBarHeight)
        )
    }

    // MARK: - Application-Level Properties

    /// Gets the application element for this element.
    /// If this IS an application, returns self. Otherwise, looks up the app by PID.
    private var applicationElement: AccessibilityElement? {
        if isApplication == true {
            return self
        }
        guard let pid = pid else { return nil }
        return AccessibilityElement(pid)
    }

    /// The currently focused window of this application.
    private var focusedWindowElement: AccessibilityElement? {
        applicationElement?.getElementValue(.focusedWindow)
    }

    /// All windows belonging to this application.
    var windowElements: [AccessibilityElement]? {
        applicationElement?.getElementsValue(.windows)
    }

    /// Whether this application is hidden.
    var isHidden: Bool? {
        applicationElement?.wrappedElement.getValue(.hidden) as? Bool
    }

    /// The "Enhanced User Interface" setting for this application.
    ///
    /// Some apps (like Terminal) use this for special accessibility features.
    /// It can interfere with window manipulation, so we sometimes need to toggle it.
    var enhancedUserInterface: Bool? {
        get {
            applicationElement?.wrappedElement.getValue(.enhancedUserInterface) as? Bool
        }
        set {
            guard let newValue = newValue else { return }
            applicationElement?.wrappedElement.setValue(.enhancedUserInterface, newValue)
        }
    }

    /// Window IDs for Stage Manager window groups.
    /// Only used when Stage Manager is enabled on macOS Ventura+.
    var windowIds: [CGWindowID]? {
        wrappedElement.getValue(.windowIds) as? [CGWindowID]
    }

    // MARK: - Window Actions

    /// Brings this window to the front and activates its application.
    ///
    /// - Parameter force: If true, activates even if already active.
    func bringToFront(force: Bool = false) {
        // First, make this the main window of its app
        if isMainWindow != true {
            isMainWindow = true
        }

        // Then activate the app itself
        if let pid = pid,
           let app = NSRunningApplication(processIdentifier: pid),
           !app.isActive || force {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }
}

// MARK: - Static Factory Methods

extension AccessibilityElement {

    /// Gets the accessibility element for the frontmost (active) application.
    ///
    /// - Returns: The application element, or nil if there's no frontmost app.
    static func getFrontApplicationElement() -> AccessibilityElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return AccessibilityElement(app.processIdentifier)
    }

    /// Gets the frontmost window of the active application.
    ///
    /// This is the main entry point for "do something to the current window" operations.
    ///
    /// - Returns: The window element, or nil if no window is found.
    static func getFrontWindowElement() -> AccessibilityElement? {
        // First, get the frontmost application
        guard let appElement = getFrontApplicationElement() else {
            Logger.log("Failed to find the application that currently has focus.")
            return nil
        }

        // Try to get the app's focused window
        if let focusedWindow = appElement.focusedWindowElement {
            return focusedWindow
        }

        // Fallback: just get the first window
        if let firstWindow = appElement.windowElements?.first {
            return firstWindow
        }

        Logger.log("Failed to find frontmost window.")
        return nil
    }

    /// Finds window info for a window at the given screen location.
    ///
    /// Filters out system windows like Dock and Notification Center.
    ///
    /// - Parameter location: The screen position to check.
    /// - Returns: Window info if found, nil otherwise.
    private static func getWindowInfo(_ location: CGPoint) -> WindowInfo? {
        WindowUtil.getWindowList().first { windowInfo in
            // Level 23 is Notification Center - skip windows at that level or higher
            let isNotSystemLevel = windowInfo.level < 23

            // Skip Dock and WindowManager windows
            let isNotSystemApp = !["Dock", "WindowManager"].contains(windowInfo.processName)

            // Check if the window contains this location
            let containsLocation = windowInfo.frame.contains(location)

            return isNotSystemLevel && isNotSystemApp && containsLocation
        }
    }

    /// Gets the window element that's under the mouse cursor.
    ///
    /// This is used for drag-to-snap functionality - we need to know which
    /// window the user is dragging without requiring it to be the frontmost window.
    ///
    /// The detection strategy varies based on user preferences and app settings.
    ///
    /// - Returns: The window element under cursor, or nil if none found.
    static func getWindowElementUnderCursor() -> AccessibilityElement? {
        // Get mouse position in screen coordinates (flipped for accessibility API)
        let cursorPosition = NSEvent.mouseLocation.screenFlipped

        // Determine detection strategy based on settings
        // "System-wide" mode uses accessibility hit-testing first
        // Otherwise, we use window list matching first (more reliable for some apps)
        var useSystemWideFirst = Defaults.systemWideMouseDown.userEnabled
        if Defaults.systemWideMouseDown.notSet, let frontAppId = ApplicationToggle.frontAppId {
            useSystemWideFirst = Defaults.systemWideMouseDownApps.typedValue?.contains(frontAppId) == true
        }

        // STRATEGY 1: System-wide accessibility hit-test (if enabled)
        if useSystemWideFirst,
           let element = AccessibilityElement(cursorPosition),
           let windowElement = element.windowElement {
            return windowElement
        }

        // STRATEGY 2: Window list matching
        if let windowInfo = getWindowInfo(cursorPosition) {

            // Special handling for Stage Manager (macOS Ventura+)
            // Windows in the Stage Manager strip have different positions
            if !Defaults.dragFromStage.userDisabled {
                if StageUtil.stageCapable && StageUtil.stageEnabled,
                   let group = StageUtil.getStageStripWindowGroup(windowInfo.id),
                   let windowId = group.first,
                   windowId != windowInfo.id,
                   let element = StageWindowAccessibilityElement(windowId) {
                    return element
                }
            }

            // Try to find the window by ID first, then by frame
            if let windowElements = AccessibilityElement(windowInfo.pid).windowElements {
                // Match by window ID (most reliable)
                if let window = windowElements.first(where: { $0.windowId == windowInfo.id }) {
                    return window
                }

                // Fall back to matching by frame geometry
                if let window = windowElements.first(where: { $0.frame == windowInfo.frame }) {
                    return window
                }
            }
        }

        // STRATEGY 3: System-wide fallback (if not used first)
        if !useSystemWideFirst,
           let element = AccessibilityElement(cursorPosition),
           let windowElement = element.windowElement {

            if Logger.logging, let pid = windowElement.pid {
                let appName = NSRunningApplication(processIdentifier: pid)?.localizedName ?? ""
                Logger.log("Window under cursor fallback matched: \(appName)")
            }
            return windowElement
        }

        Logger.log("Unable to obtain the accessibility element with the specified attribute at mouse location")
        return nil
    }

    /// Gets a window element by its window ID.
    ///
    /// - Parameter windowId: The CGWindowID to look up.
    /// - Returns: The window element, or nil if not found.
    static func getWindowElement(_ windowId: CGWindowID) -> AccessibilityElement? {
        // First find the PID from the window list
        guard let pid = WindowUtil.getWindowList(ids: [windowId]).first?.pid else {
            return nil
        }

        // Then find the window in that app's windows
        return AccessibilityElement(pid).windowElements?.first { $0.windowId == windowId }
    }

    /// Gets all window elements from all applications.
    ///
    /// - Returns: Array of all window elements across all running apps.
    static func getAllWindowElements() -> [AccessibilityElement] {
        // Get unique PIDs from window list, then get all windows for each PID
        return WindowUtil.getWindowList()
            .uniqueMap { $0.pid }
            .compactMap { AccessibilityElement($0).windowElements }
            .flatMap { $0 }
    }
}

// MARK: - Protocol Conformances

extension AccessibilityElement: Equatable {
    static func == (lhs: AccessibilityElement, rhs: AccessibilityElement) -> Bool {
        return lhs.wrappedElement == rhs.wrappedElement
    }
}

extension AccessibilityElement: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedElement)
    }
}

// MARK: - Stage Manager Support

/// A specialized AccessibilityElement for windows in macOS Stage Manager's sidebar strip.
///
/// In Stage Manager, windows shown in the strip (on the left side of the screen) have
/// a different visual position than their actual accessibility-reported position.
/// This class corrects for that discrepancy.
class StageWindowAccessibilityElement: AccessibilityElement {

    /// The stored window ID (since we need to look it up differently for Stage Manager).
    private let _windowId: CGWindowID

    /// Creates a StageWindowAccessibilityElement for a window ID.
    ///
    /// - Parameter windowId: The window ID to wrap.
    /// - Returns: nil if the window can't be found.
    init?(_ windowId: CGWindowID) {
        guard let element = AccessibilityElement.getWindowElement(windowId) else {
            return nil
        }
        _windowId = windowId
        super.init(element.wrappedElement)
    }

    /// The frame, corrected for Stage Manager positioning.
    /// Uses the position from the window list (visual position) combined with
    /// the size from accessibility (actual size).
    override var frame: CGRect {
        let accessibilityFrame = super.frame
        guard !accessibilityFrame.isNull,
              let windowId = windowId,
              let windowInfo = WindowUtil.getWindowList(ids: [windowId]).first else {
            return accessibilityFrame
        }

        // Use visual position from window list, but accessibility size
        return CGRect(origin: windowInfo.frame.origin, size: accessibilityFrame.size)
    }

    /// Returns the stored window ID.
    override var windowId: CGWindowID? {
        _windowId
    }
}

// MARK: - Enhanced UI Options

/// Options for handling "Enhanced User Interface" mode in applications.
///
/// Some apps (like Terminal) enable this mode for better accessibility features,
/// but it can interfere with window manipulation. These options control how
/// the window manager handles it.
enum EnhancedUI: Int {
    /// Disable Enhanced UI before moving/resizing, re-enable after.
    /// This is the default and most compatible behavior.
    case disableEnable = 1

    /// Disable Enhanced UI but don't re-enable it after.
    /// Use if re-enabling causes issues.
    case disableOnly = 2

    /// Disable Enhanced UI every time the frontmost app changes.
    /// More aggressive approach for problematic apps.
    case frontmostDisable = 3
}
