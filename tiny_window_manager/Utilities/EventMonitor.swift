//
//  EventMonitor.swift
//  tiny_window_manager
//
//  Utilities for monitoring keyboard and mouse events system-wide.
//
//  TWO TYPES OF EVENT MONITORING:
//
//  1. PASSIVE MONITORING (PassiveEventMonitor):
//     - Observes events without modifying them
//     - Uses NSEvent's built-in monitoring API
//     - Good for: reacting to events (e.g., "user pressed a key")
//     - Cannot block or modify events
//
//  2. ACTIVE MONITORING (ActiveEventMonitor):
//     - Can intercept and BLOCK events before they reach other apps
//     - Uses CGEvent taps (lower-level, more powerful)
//     - Good for: global hotkeys that shouldn't trigger other apps
//     - Requires Accessibility permissions
//
//  LOCAL vs GLOBAL EVENTS:
//  - Local events: happen within YOUR app's windows
//  - Global events: happen in OTHER apps' windows
//  - We monitor both to catch events regardless of which app is focused
//

import Cocoa

// MARK: - EventMonitor Protocol

/// Common interface for both passive and active event monitors.
///
protocol EventMonitor {
    /// Returns true if the monitor is currently active.
    var running: Bool { get }

    /// Starts monitoring for events.
    func start()

    /// Stops monitoring for events.
    func stop()
}

// MARK: - Passive Event Monitor

/// Monitors events without modifying them.
///
/// Use this when you just need to OBSERVE events (e.g., tracking mouse movement).
/// This monitor cannot block events from reaching other applications.
///
/// Example usage:
/// ```
/// let monitor = PassiveEventMonitor(mask: .keyDown) { event in
///     print("Key pressed: \(event.keyCode)")
/// }
/// monitor.start()
/// ```
///
public class PassiveEventMonitor: EventMonitor {

    // MARK: - Properties

    /// Monitor for events within our own app's windows.
    private var localMonitor: Any?

    /// Monitor for events in other apps' windows.
    private var globalMonitor: Any?

    /// Which event types to listen for (e.g., .keyDown, .mouseMoved).
    private let mask: NSEvent.EventTypeMask

    /// Closure called whenever a matching event occurs.
    private let handler: (NSEvent) -> Void

    /// Returns true if both monitors are active.
    var running: Bool {
        print(#function, "called")
        // Both monitors must be active for us to consider it "running"
        return localMonitor != nil && globalMonitor != nil
    }

    // MARK: - Initialization

    /// Creates a new passive event monitor.
    ///
    /// - Parameters:
    ///   - mask: The types of events to monitor (e.g., `.keyDown`, `.leftMouseUp`).
    ///   - handler: A closure called whenever a matching event occurs.
    ///
    public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) {
        print(#function, "called")
        self.mask = mask
        self.handler = handler
    }

    /// Automatically stops monitoring when this object is deallocated.
    deinit {
        print(#function, "called")
        stop()
    }

    // MARK: - Start/Stop

    /// Begins monitoring for events matching the mask.
    ///
    public func start() {
        print(#function, "called")
        // Monitor events within our own app
        // Local monitors must return the event (or a modified version) to let it propagate
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { event in
            self.handler(event)
            return event  // Return the event unchanged to let it propagate normally
        }

        // Monitor events in other apps
        // Global monitors don't return anything - they're purely observational
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    /// Stops monitoring for events.
    ///
    public func stop() {
        print(#function, "called")
        // Clean up local monitor if it exists
        if localMonitor != nil {
            NSEvent.removeMonitor(localMonitor!)
            localMonitor = nil
        }

        // Clean up global monitor if it exists
        if globalMonitor != nil {
            NSEvent.removeMonitor(globalMonitor!)
            globalMonitor = nil
        }
    }
}

// MARK: - Active Event Monitor

/// Monitors events and can BLOCK them from reaching other applications.
///
/// Use this for global hotkeys where you want to "consume" the keypress
/// so it doesn't trigger actions in other apps.
///
/// IMPORTANT: Requires Accessibility permissions to work!
///
/// Example usage:
/// ```
/// let monitor = ActiveEventMonitor(
///     mask: .keyDown,
///     filterer: { event in
///         // Return true to BLOCK this event, false to let it through
///         return event.keyCode == 49  // Block spacebar
///     },
///     handler: { event in
///         print("Handling event: \(event)")
///     }
/// )
/// monitor.start()
/// ```
///
public class ActiveEventMonitor: EventMonitor {

    // MARK: - Properties

    /// The low-level event tap (a Mach port that receives system events).
    private var tap: CFMachPort?

    /// A dedicated thread for processing events (to avoid blocking the main thread).
    private var thread: RunLoopThread?

    /// Which event types to intercept.
    private let mask: NSEvent.EventTypeMask

    /// Decides whether to BLOCK an event. Return true to block, false to allow.
    public let filterer: (NSEvent) -> Bool

    /// Called for every matching event (whether blocked or not).
    public let handler: (NSEvent) -> Void

    /// Returns true if the event tap is active.
    var running: Bool {
        print(#function, "called")
        return tap != nil
    }

    // MARK: - Initialization

    /// Creates a new active event monitor.
    ///
    /// - Parameters:
    ///   - mask: The types of events to intercept.
    ///   - filterer: Returns true to BLOCK the event, false to let it through.
    ///   - handler: Called for every matching event (on the main thread).
    ///
    public init(
        mask: NSEvent.EventTypeMask,
        filterer: @escaping (NSEvent) -> Bool,
        handler: @escaping (NSEvent) -> Void
    ) {
        print(#function, "called")
        self.mask = mask
        self.filterer = filterer
        self.handler = handler
    }

    /// Automatically stops the tap when deallocated.
    deinit {
        print(#function, "called")
        stop()
    }

    // MARK: - Start/Stop

    /// Creates an event tap and starts intercepting events.
    ///
    public func start() {
        print(#function, "called")
        // Create a CGEvent tap - this is the low-level macOS API for intercepting events
        // Parameters explained:
        //   - tap: .cgSessionEventTap = intercept events for the current user session
        //   - place: .headInsertEventTap = process events BEFORE other taps
        //   - options: .defaultTap = we can both observe AND modify/block events
        //   - eventsOfInterest: which event types to intercept (from our mask)
        //   - callback: the C function that processes each event (defined below)
        //   - userInfo: we pass 'self' so the callback can access this object
        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask.rawValue,
            callback: tapCallback,
            userInfo: CUtil.bridge(obj: self)  // Convert self to a C-compatible pointer
        )

        // If tap creation succeeded, set up a run loop thread to process events
        if let tap = tap {
            // Create a dedicated thread with high priority for responsive event handling
            thread = RunLoopThread(mode: .default, qualityOfService: .userInteractive, start: true)

            // Add our tap to the thread's run loop so it receives events
            thread!.runLoop!.add(tap, forMode: .default)
        }
    }

    /// Stops the event tap and cleans up resources.
    ///
    public func stop() {
        print(#function, "called")
        if let tap = tap {
            // Remove tap from the run loop
            thread!.runLoop!.remove(tap, forMode: .default)

            // Stop and release the thread
            thread!.cancel()
            thread = nil

            // Disable the tap itself
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        tap = nil
    }
}

// MARK: - Event Tap Callback

/// The C-style callback function that processes each intercepted event.
///
/// This function is called by the system for every event that matches our tap's mask.
/// It must be a free function (not a method) because it's called from C code.
///
/// - Parameters:
///   - proxy: Opaque reference to the tap (unused here).
///   - type: The type of event (keyDown, mouseMoved, or special types like tapDisabled).
///   - event: The actual event data.
///   - refcon: Our "reference context" - a pointer to the ActiveEventMonitor instance.
///
/// - Returns: The event to pass on, or nil to block/consume the event.
///
fileprivate func tapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    print(#function, "called")

    // Track whether this event should be filtered (blocked)
    var shouldBlockEvent = false

    // Safely unwrap the reference pointer to get our monitor object
    if let pointerToMonitor = refcon {

        // Convert the C pointer back to our Swift object
        let eventMonitor: ActiveEventMonitor = CUtil.bridge(ptr: pointerToMonitor)

        // Check for special "tap disabled" events
        // The system can disable taps if they take too long or cause issues
        let tapWasDisabled = (type == .tapDisabledByTimeout || type == .tapDisabledByUserInput)

        if tapWasDisabled {
            // Re-enable the tap by stopping and starting again
            eventMonitor.stop()
            eventMonitor.start()
        } else {
            // Normal event - convert from CGEvent to NSEvent for easier handling
            if let nsEvent = NSEvent(cgEvent: event) {

                // Ask the filterer if this event should be blocked
                shouldBlockEvent = eventMonitor.filterer(nsEvent)

                // Call the handler on the main thread (UI updates must happen there)
                DispatchQueue.main.async {
                    eventMonitor.handler(nsEvent)
                }
            }
        }
    }

    // Return nil to BLOCK the event, or the event itself to let it through
    if shouldBlockEvent {
        return nil  // Event is consumed/blocked
    } else {
        return Unmanaged.passUnretained(event)  // Event passes through unchanged
    }
}
