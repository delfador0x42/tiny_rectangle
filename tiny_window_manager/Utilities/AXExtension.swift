//
//  AXExtension.swift
//  tiny_window_manager
//
//

import Foundation

// MARK: - NSAccessibility.Attribute Extension

/// Adds custom accessibility attribute constants that aren't included in the standard SDK.
/// These are used to access special properties of UI elements.
extension NSAccessibility.Attribute {
    /// Enables enhanced accessibility features for an application.
    /// When set to true, some apps expose additional accessibility information.
    static let enhancedUserInterface = NSAccessibility.Attribute(rawValue: "AXEnhancedUserInterface")

    /// Returns the window IDs associated with an application.
    static let windowIds = NSAccessibility.Attribute(rawValue: "AXWindowsIDs")
}

// MARK: - AXValue Extension

/// Extends AXValue to provide convenient conversion between AXValue and Swift types.
/// AXValue is a Core Foundation type that wraps geometric values like CGPoint and CGSize.
extension AXValue {

    /// Extracts the underlying value from an AXValue wrapper.
    /// - Returns: The unwrapped value of type T, or nil if extraction fails.
    /// - Note: T should match the actual type stored in the AXValue (e.g., CGPoint, CGSize).
    func toValue<T>() -> T? {
        // Step 1: Allocate memory to store the extracted value
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)

        // Step 2: Try to extract the value from the AXValue into our pointer
        let success = AXValueGetValue(self, AXValueGetType(self), pointer)

        // Step 3: Read the value from the pointer
        let value = pointer.pointee

        // Step 4: Clean up the allocated memory (important to prevent memory leaks!)
        pointer.deallocate()

        // Step 5: Return the value only if extraction succeeded
        return success ? value : nil
    }

    /// Creates an AXValue wrapper from a Swift value.
    /// - Parameters:
    ///   - value: The value to wrap (e.g., a CGPoint or CGSize)
    ///   - type: The AXValueType that describes what kind of value this is
    /// - Returns: A new AXValue containing the wrapped value, or nil if creation fails.
    static func from<T>(value: T, type: AXValueType) -> AXValue? {
        // We need a mutable copy because withUnsafePointer requires an inout parameter
        var value = value
        return withUnsafePointer(to: &value) { valuePointer in
            AXValueCreate(type, valuePointer)
        }
    }
}

// MARK: - AXUIElement Extension

/// Extends AXUIElement with convenient methods for reading and writing accessibility attributes.
/// AXUIElement represents a UI element (window, button, etc.) in the accessibility hierarchy.
///
/// The macOS Accessibility API uses a C-style interface with error codes and output parameters.
/// These extensions wrap that interface to provide a more Swift-friendly API.
extension AXUIElement {

    // MARK: System-Wide Element

    /// A reference to the system-wide accessibility element.
    /// Use this to query elements across all applications (e.g., finding the element under the mouse).
    static let systemWide = AXUIElementCreateSystemWide()

    // MARK: Reading Attributes

    /// Checks if a specific attribute can be modified on this element.
    /// - Parameter attribute: The attribute to check
    /// - Returns: true if settable, false if read-only, nil if the query failed
    func isValueSettable(_ attribute: NSAccessibility.Attribute) -> Bool? {
        var isSettable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(self, attribute.rawValue as CFString, &isSettable)
        guard result == .success else { return nil }
        return isSettable.boolValue
    }

    /// Gets the raw value of an attribute from this element.
    /// - Parameter attribute: The attribute to read (e.g., .position, .size, .title)
    /// - Returns: The attribute value as AnyObject, or nil if the read failed
    func getValue(_ attribute: NSAccessibility.Attribute) -> AnyObject? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(self, attribute.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value
    }

    /// Gets an attribute value that's wrapped in an AXValue (like CGPoint or CGSize).
    /// - Parameter attribute: The attribute to read
    /// - Returns: The unwrapped value of type T, or nil if reading or unwrapping failed
    /// - Note: Use this for attributes like .position (CGPoint) or .size (CGSize)
    func getWrappedValue<T>(_ attribute: NSAccessibility.Attribute) -> T? {
        // First, get the raw value
        guard let value = getValue(attribute) else { return nil }

        // Make sure it's actually an AXValue type
        guard CFGetTypeID(value) == AXValueGetTypeID() else { return nil }

        // Unwrap the AXValue to get the underlying type
        return (value as! AXValue).toValue()
    }

    // MARK: Writing Attributes

    /// Sets an attribute to a raw AnyObject value.
    /// This is the base setter that other typed setters build upon.
    private func setValue(_ attribute: NSAccessibility.Attribute, _ value: AnyObject) {
        AXUIElementSetAttributeValue(self, attribute.rawValue as CFString, value)
    }

    /// Sets a boolean attribute value.
    /// - Parameters:
    ///   - attribute: The attribute to set
    ///   - value: The boolean value to set
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: Bool) {
        // Convert Swift Bool to CFBoolean for the C API
        setValue(attribute, value as CFBoolean)
    }

    /// Sets an attribute that requires an AXValue wrapper.
    /// This is a helper used by the CGPoint and CGSize setters.
    private func setWrappedValue<T>(_ attribute: NSAccessibility.Attribute, _ value: T, _ type: AXValueType) {
        guard let wrappedValue = AXValue.from(value: value, type: type) else { return }
        setValue(attribute, wrappedValue)
    }

    /// Sets a CGPoint attribute value (e.g., window position).
    /// - Parameters:
    ///   - attribute: The attribute to set (typically .position)
    ///   - value: The point value to set
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: CGPoint) {
        setWrappedValue(attribute, value, .cgPoint)
    }

    /// Sets a CGSize attribute value (e.g., window size).
    /// - Parameters:
    ///   - attribute: The attribute to set (typically .size)
    ///   - value: The size value to set
    func setValue(_ attribute: NSAccessibility.Attribute, _ value: CGSize) {
        setWrappedValue(attribute, value, .cgSize)
    }

    // MARK: Element Queries

    /// Finds the UI element at a specific screen position.
    /// - Parameter position: The screen coordinates to query
    /// - Returns: The AXUIElement at that position, or nil if none found
    func getElementAtPosition(_ position: CGPoint) -> AXUIElement? {
        var element: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(self, Float(position.x), Float(position.y), &element)
        guard result == .success else { return nil }
        return element
    }

    /// Gets the process ID of the application that owns this element.
    /// - Returns: The process ID (pid_t), or nil if the query failed
    func getPid() -> pid_t? {
        var pid = pid_t(0)
        let result = AXUIElementGetPid(self, &pid)
        guard result == .success else { return nil }
        return pid
    }

    /// Gets the Core Graphics window ID for this element (if it's a window).
    /// - Returns: The CGWindowID, or nil if the query failed or element isn't a window
    /// - Note: Uses a private API (_AXUIElementGetWindow) that may change in future macOS versions
    func getWindowId() -> CGWindowID? {
        var windowId = CGWindowID(0)
        let result = _AXUIElementGetWindow(self, &windowId)
        guard result == .success else { return nil }
        return windowId
    }
}
