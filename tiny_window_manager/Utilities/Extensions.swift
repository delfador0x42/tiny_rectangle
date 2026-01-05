//
//  Extensions.swift
//  tiny_window_manager
//
//  Consolidated extensions for Foundation, Core Graphics, Accessibility, and Cocoa types.
//

import Cocoa
import Foundation

// ============================================================================
// MARK: - String Extension
// ============================================================================

extension String {

    /// Returns the localized version of this string from the "Main" strings table.
    var localized: String {
        return NSLocalizedString(self, tableName: "Main", comment: "")
    }

    /// Converts camelCase to words with spaces.
    /// Example: "leftHalf" → "Left Half", "topRightSixth" → "Top Right Sixth"
    var camelCaseToWords: String {
        var result = ""
        for char in self {
            if char.isUppercase && !result.isEmpty {
                result.append(" ")
            }
            result.append(char)
        }
        // Capitalize first letter
        return result.prefix(1).uppercased() + result.dropFirst()
    }
}

// ============================================================================
// MARK: - DispatchTime Extension
// ============================================================================

extension DispatchTime {

    /// Returns the system uptime in milliseconds.
    ///
    /// Converts `uptimeNanoseconds` to milliseconds for easier timing calculations.
    var uptimeMilliseconds: UInt64 {
        return uptimeNanoseconds / 1_000_000
    }
}

// ============================================================================
// MARK: - CGPoint Extension
// ============================================================================

extension CGPoint {

    /// Converts this point from Core Graphics coordinates to screen (AppKit) coordinates.
    ///
    /// Core Graphics: Y increases upward (bottom = 0)
    /// Screen/AppKit: Y increases downward (top = 0)
    var screenFlipped: CGPoint {
        let mainScreenHeight = NSScreen.screens[0].frame.maxY
        let flippedY = mainScreenHeight - y
        return CGPoint(x: x, y: flippedY)
    }
}

// ============================================================================
// MARK: - CGRect Extension
// ============================================================================

extension CGRect {

    /// Converts this rectangle from Core Graphics coordinates to screen (AppKit) coordinates.
    var screenFlipped: CGRect {
        guard !isNull else { return self }

        let mainScreenHeight = NSScreen.screens[0].frame.maxY
        let flippedY = mainScreenHeight - maxY
        let newOrigin = CGPoint(x: origin.x, y: flippedY)

        return CGRect(origin: newOrigin, size: size)
    }

    /// Returns true if the rectangle is wider than it is tall.
    var isLandscape: Bool {
        return width > height
    }

    /// Returns the center point of this rectangle.
    var centerPoint: CGPoint {
        let centerX = NSMidX(self)
        let centerY = NSMidY(self)
        return NSMakePoint(centerX, centerY)
    }

    /// Counts how many edges this rectangle shares with another rectangle.
    func numSharedEdges(withRect rect: CGRect) -> Int {
        var sharedEdgeCount = 0
        if minX == rect.minX { sharedEdgeCount += 1 }
        if maxX == rect.maxX { sharedEdgeCount += 1 }
        if minY == rect.minY { sharedEdgeCount += 1 }
        if maxY == rect.maxY { sharedEdgeCount += 1 }
        return sharedEdgeCount
    }
}

// ============================================================================
// MARK: - NSAccessibility.Attribute Extension
// ============================================================================

extension NSAccessibility.Attribute {
    /// Enables enhanced accessibility features for an application.
    static let enhancedUserInterface = NSAccessibility.Attribute(rawValue: "AXEnhancedUserInterface")

    /// Returns the window IDs associated with an application.
    static let windowIds = NSAccessibility.Attribute(rawValue: "AXWindowsIDs")
}

// ============================================================================
// MARK: - AXValue Extension
// ============================================================================

extension AXValue {

    /// Extracts the underlying value from an AXValue wrapper.
    func toValue<T>() -> T? {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        let success = AXValueGetValue(self, AXValueGetType(self), pointer)
        let value = pointer.pointee
        pointer.deallocate()
        return success ? value : nil
    }

    /// Creates an AXValue wrapper from a Swift value.
    static func from<T>(value: T, type: AXValueType) -> AXValue? {
        var value = value
        return withUnsafePointer(to: &value) { valuePointer in
            AXValueCreate(type, valuePointer)
        }
    }
}

// ============================================================================
// MARK: - AXUIElement Extension
// ============================================================================

extension AXUIElement {

    /// A reference to the system-wide accessibility element.
    static let systemWide = AXUIElementCreateSystemWide()

    /// Checks if a specific attribute can be modified on this element.
    func isValueSettable(_ attribute: NSAccessibility.Attribute) -> Bool? {
        var isSettable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(self, attribute.rawValue as CFString, &isSettable)
        guard result == .success else { return nil }
        return isSettable.boolValue
    }

    /// Gets the raw value of an attribute from this element.
    func getValue(_ attribute: NSAccessibility.Attribute) -> AnyObject? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(self, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value
    }

    /// Gets an attribute value that's wrapped in an AXValue (like CGPoint or CGSize).
    func getWrappedValue<T>(_ attribute: NSAccessibility.Attribute) -> T? {
        guard let value = getValue(attribute) else { return nil }
        guard CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue).toValue()
    }

    /// Sets an attribute to a raw AnyObject value.
    private func setValue(_ attribute: NSAccessibility.Attribute, _ value: AnyObject) {
        AXUIElementSetAttributeValue(self, attribute.rawValue as CFString, value)
    }

    /// Sets a boolean attribute value.
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: Bool) {
        setValue(attribute, value as CFBoolean)
    }

    /// Sets an attribute that requires an AXValue wrapper.
    private func setWrappedValue<T>(_ attribute: NSAccessibility.Attribute, _ value: T, _ type: AXValueType) {
        guard let wrappedValue = AXValue.from(value: value, type: type) else { return }
        setValue(attribute, wrappedValue)
    }

    /// Sets a CGPoint attribute value (e.g., window position).
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: CGPoint) {
        setWrappedValue(attribute, value, .cgPoint)
    }

    /// Sets a CGSize attribute value (e.g., window size).
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: CGSize) {
        setWrappedValue(attribute, value, .cgSize)
    }

    /// Finds the UI element at a specific screen position.
    func getElementAtPosition(_ position: CGPoint) -> AXUIElement? {
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(self, Float(position.x), Float(position.y), &element)
        guard result == .success else { return nil }
        return element
    }

    /// Gets the process ID of the application that owns this element.
    func getPid() -> pid_t? {
        var pid = pid_t(0)
        let result = AXUIElementGetPid(self, &pid)
        guard result == .success else { return nil }
        return pid
    }

    /// Gets the Core Graphics window ID for this element (if it's a window).
    func getWindowId() -> CGWindowID? {
        var windowId = CGWindowID(0)
        let result = _AXUIElementGetWindow(self, &windowId)
        guard result == .success else { return nil }
        return windowId
    }
}

// ============================================================================
// MARK: - CFArray Extension
// ============================================================================

extension CFArray {

    /// Retrieves a value from the array at the specified index and casts it to the desired type.
    func getValue<T>(_ index: CFIndex) -> T {
        let rawPointer = CFArrayGetValueAtIndex(self, index)
        let typedValue: T = unsafeBitCast(rawPointer, to: T.self)
        return typedValue
    }

    /// Returns the number of elements in the array.
    func getCount() -> CFIndex {
        return CFArrayGetCount(self)
    }
}

// ============================================================================
// MARK: - CFDictionary Extension
// ============================================================================

extension CFDictionary {

    /// Retrieves a value from the dictionary for the specified key and casts it to the desired type.
    func getValue<T>(_ key: CFString) -> T {
        let keyAsPointer = unsafeBitCast(key, to: UnsafeRawPointer.self)
        let valuePointer = CFDictionaryGetValue(self, keyAsPointer)
        let typedValue: T = unsafeBitCast(valuePointer, to: T.self)
        return typedValue
    }
}

// ============================================================================
// MARK: - Notification.Name Extension
// ============================================================================

extension Notification.Name {

    // MARK: Custom Notification Names

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

    // MARK: Posting Notifications

    /// Posts this notification to the specified notification center.
    func post(
        center: NotificationCenter = NotificationCenter.default,
        object: Any? = nil,
        userInfo: [AnyHashable: Any]? = nil
    ) {
        center.post(name: self, object: object, userInfo: userInfo)
    }

    // MARK: Observing Notifications

    /// Registers a handler to be called whenever this notification is posted.
    @discardableResult
    func onPost(
        center: NotificationCenter = NotificationCenter.default,
        object: Any? = nil,
        queue: OperationQueue? = nil,
        using: @escaping (Notification) -> Void
    ) -> NSObjectProtocol {
        return center.addObserver(
            forName: self,
            object: object,
            queue: queue,
            using: using
        )
    }
}

// ============================================================================
// MARK: - Sequence Extension
// ============================================================================

extension Sequence {

    /// Transforms each element and returns only unique results, preserving order.
    func uniqueMap<T>(_ transform: (Element) -> T) -> [T] where T: Hashable {
        var seenElements = Set<T>()
        var uniqueResults = Array<T>()

        for originalElement in self {
            let transformedElement = transform(originalElement)
            let insertResult = seenElements.insert(transformedElement)
            let isNewElement = insertResult.inserted

            if isNewElement {
                uniqueResults.append(transformedElement)
            }
        }

        return uniqueResults
    }
}

// ============================================================================
// MARK: - NSImage Extension
// ============================================================================

extension NSImage {

    /// Creates a new image by rotating this image by the specified degrees.
    ///
    /// - Parameter degrees: The rotation angle in degrees. Positive = counter-clockwise.
    /// - Returns: A new NSImage containing the rotated version of this image.
    func rotated(by degrees: CGFloat) -> NSImage {
        let degreesInRadians = degrees * CGFloat.pi / 180.0
        let sinOfAngle = abs(sin(degreesInRadians))
        let cosOfAngle = abs(cos(degreesInRadians))

        let newSize = CGSize(
            width: size.height * sinOfAngle + size.width * cosOfAngle,
            height: size.width * sinOfAngle + size.height * cosOfAngle
        )

        let horizontalOffset = (newSize.width - size.width) / 2
        let verticalOffset = (newSize.height - size.height) / 2

        let imageBounds = NSRect(
            x: horizontalOffset,
            y: verticalOffset,
            width: size.width,
            height: size.height
        )

        let rotationTransform = NSAffineTransform()
        rotationTransform.translateX(by: newSize.width / 2, yBy: newSize.height / 2)
        rotationTransform.rotate(byDegrees: degrees)
        rotationTransform.translateX(by: -newSize.width / 2, yBy: -newSize.height / 2)

        let rotatedImage = NSImage(size: newSize)
        rotatedImage.lockFocus()
        rotationTransform.concat()
        draw(
            in: imageBounds,
            from: CGRect.zero,
            operation: .copy,
            fraction: 1.0
        )
        rotatedImage.unlockFocus()

        return rotatedImage
    }
}

// ============================================================================
// MARK: - SwiftUI Alert State
// ============================================================================

/// Observable state for displaying alerts in SwiftUI views.
///
/// Usage in SwiftUI:
/// ```swift
/// @Environment(AlertState.self) var alertState
///
/// .alert(alertState.title, isPresented: alertState.isPresented) {
///     Button("OK") { alertState.dismiss() }
/// } message: {
///     Text(alertState.message)
/// }
/// ```
///
/// Triggering from anywhere:
/// ```swift
/// AlertState.shared.show(title: "Error", message: "Something went wrong")
/// ```
@Observable @MainActor
final class AlertState {
    static let shared = AlertState()

    var title = ""
    var message = ""
    var isPresented = false

    private init() {}

    func show(title: String, message: String) {
        self.title = title
        self.message = message
        self.isPresented = true
    }

    func dismiss() {
        isPresented = false
    }
}

// ============================================================================
// MARK: - Alert Utilities (AppKit)
// ============================================================================

/// Utility functions for displaying alert dialogs in AppKit contexts.
/// For SwiftUI contexts, use AlertState instead.
enum AlertUtil {

    /// Shows a simple alert with one button (typically "OK").
    static func oneButtonAlert(question: String, text: String, confirmText: String = "OK") {
        let alert = createBaseAlert(question: question, text: text)
        alert.addButton(withTitle: confirmText)
        alert.runModal()
    }

    /// Shows an alert with two buttons (typically "OK" and "Cancel").
    static func twoButtonAlert(question: String, text: String, confirmText: String = "OK", cancelText: String = "Cancel") -> NSApplication.ModalResponse {
        let alert = createBaseAlert(question: question, text: text)
        alert.addButton(withTitle: confirmText)
        alert.addButton(withTitle: cancelText)
        return alert.runModal()
    }

    /// Shows an alert with three buttons for more complex choices.
    static func threeButtonAlert(question: String, text: String, buttonOneText: String, buttonTwoText: String, buttonThreeText: String) -> NSApplication.ModalResponse {
        let alert = createBaseAlert(question: question, text: text)
        alert.addButton(withTitle: buttonOneText)
        alert.addButton(withTitle: buttonTwoText)
        alert.addButton(withTitle: buttonThreeText)
        return alert.runModal()
    }

    private static func createBaseAlert(question: String, text: String) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        return alert
    }
}
