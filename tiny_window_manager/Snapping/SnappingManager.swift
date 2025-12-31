//
//  SnappingManager.swift
//  tiny_window_manager
//
//  The core engine for window snapping functionality. This class:
//
//  1. LISTENS for mouse events (mouse down, drag, mouse up)
//  2. DETECTS when a window is being dragged toward a screen edge/corner
//  3. SHOWS a preview "footprint" of where the window will snap
//  4. EXECUTES the snap action when the user releases the mouse
//  5. RESTORES the original window size when unsnapping
//
//  The snapping flow:
//  ┌─────────────────┐
//  │  Mouse Down     │ → Remember which window is under the cursor
//  └────────┬────────┘
//           ▼
//  ┌─────────────────┐
//  │  Mouse Dragged  │ → Check if cursor is in a snap area
//  │                 │ → Show/update footprint preview
//  └────────┬────────┘
//           ▼
//  ┌─────────────────┐
//  │  Mouse Up       │ → Execute snap action (resize window)
//  │                 │ → Hide footprint
//  └─────────────────┘
//

import Cocoa

// MARK: - Snap Area

/// Represents a detected snap area where a window can be snapped.
/// Combines the screen, position on that screen, and the action to perform.
struct SnapArea: Equatable {
    let screen: NSScreen        // Which screen the snap area is on
    let directional: Directional // Which edge/corner (e.g., .tl, .l, .b)
    let action: WindowAction     // What action to perform (e.g., .leftHalf, .maximize)
}

// MARK: - Snapping Manager

class SnappingManager {

    // MARK: - App Ignore List

    /// Bundle IDs of apps that should be fully ignored for snapping.
    /// Some apps have their own window management or don't work well with snapping.
    private let fullIgnoreIds: [String] = Defaults.fullIgnoreBundleIds.typedValue ?? [
        "com.install4j",
        "com.mathworks.matlab",
        "com.live2d.cubism.CECubismEditorApp",
        "com.aquafold.datastudio.DataStudio",
        "com.adobe.illustrator",
        "com.adobe.AfterEffects"
    ]

    // MARK: - Event Monitoring State

    /// The event monitor that listens for mouse events
    var eventMonitor: EventMonitor?

    /// The window element currently being dragged (if any)
    var windowElement: AccessibilityElement?

    /// The CGWindowID of the window being dragged
    var windowId: CGWindowID?

    /// How many times we've tried to get the window ID (gives up after 20 attempts)
    var windowIdAttempt: Int = 0

    /// Timestamp of the last window ID attempt (throttles retries to every 0.1s)
    var lastWindowIdAttempt: TimeInterval?

    /// Whether the user is currently moving a window
    var windowMoving: Bool = false

    /// Whether the frontmost app is in fullscreen mode (disables snapping)
    var isFullScreen: Bool = false

    /// Whether snapping is currently allowed (can be disabled by app ignore rules)
    var allowListening: Bool = true

    /// The window's frame when dragging started (used for unsnap restore)
    var initialWindowRect: CGRect?

    /// The currently active snap area (if cursor is in one)
    var currentSnapArea: SnapArea?

    // MARK: - Mission Control Drag Restriction

    /// Previous Y position during drag (used to detect upward drags toward Mission Control)
    var dragPrevY: Double?

    /// Timestamp when the drag restriction expires
    var dragRestrictionExpirationTimestamp: UInt64 = 0

    /// Whether the Mission Control drag restriction has expired
    var dragRestrictionExpired: Bool {
        return DispatchTime.now().uptimeMilliseconds > dragRestrictionExpirationTimestamp
    }

    // MARK: - Footprint Preview

    /// The footprint window that shows where the window will snap
    var box: FootprintWindow?

    // MARK: - Screen Detection

    let screenDetection = ScreenDetection()

    // MARK: - Edge Margins

    /// These margins define how close to each edge the cursor must be to trigger snapping.
    /// They also account for the menu bar (top) and dock (bottom/sides).
    private let marginTop = Defaults.snapEdgeMarginTop.cgFloat
    private let marginBottom = Defaults.snapEdgeMarginBottom.cgFloat
    private let marginLeft = Defaults.snapEdgeMarginLeft.cgFloat
    private let marginRight = Defaults.snapEdgeMarginRight.cgFloat

    // MARK: - Initialization

    init() {
        print(#function, "called")
        // Enable snapping if not explicitly disabled
        if Defaults.windowSnapping.enabled != false {
            enableSnapping()
        }

        registerWorkspaceChangeNote()
        registerForNotifications()
    }

    /// Registers for app-level notifications
    private func registerForNotifications() {
        print(#function, "called")
        // Listen for snapping toggle changes
        Notification.Name.windowSnapping.onPost { notification in
            if let enabled = notification.object as? Bool {
                self.allowListening = enabled
            }
            self.toggleListening()
        }

        // Listen for Mission Control dragging setting changes
        Notification.Name.missionControlDragging.onPost { notification in
            self.stopEventMonitor()
            self.startEventMonitor()
        }

        // Listen for front app changes (to handle app ignore rules)
        Notification.Name.frontAppChanged.onPost(using: frontAppChanged)
    }

    // MARK: - Front App Change Handling

    /// Called when the frontmost application changes.
    /// Checks if snapping should be disabled for this app.
    func frontAppChanged(notification: Notification) {
        print(#function, "called")
        if ApplicationToggle.shortcutsDisabled {
            DispatchQueue.main.async {
                if !Defaults.ignoreDragSnapToo.userDisabled {
                    // Snapping disabled along with shortcuts for this app
                    self.allowListening = false
                    self.toggleListening()
                } else {
                    // Check if this specific app is in the full ignore list
                    for id in self.fullIgnoreIds {
                        if ApplicationToggle.frontAppId?.starts(with: id) == true {
                            self.allowListening = false
                            self.toggleListening()
                            break
                        }
                    }
                }
            }
        } else {
            // App is not ignored - enable snapping
            allowListening = true
            checkFullScreen()
        }
    }

    // MARK: - Snapping Toggle

    /// Enables or disables snapping based on current state.
    /// Snapping is disabled if: not allowed, in fullscreen, or user disabled it.
    func toggleListening() {
        print(#function, "called")
        let shouldEnable = allowListening && !isFullScreen && !Defaults.windowSnapping.userDisabled

        if shouldEnable {
            enableSnapping()
        } else {
            disableSnapping()
        }
    }

    // MARK: - Fullscreen Detection

    /// Registers for workspace change notifications (space changes, fullscreen changes)
    private func registerWorkspaceChangeNote() {
        print(#function, "called")
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(receiveWorkspaceNote(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        checkFullScreen()
    }

    /// Checks if the current front window is in fullscreen mode
    func checkFullScreen() {
        print(#function, "called")
        isFullScreen = AccessibilityElement.getFrontWindowElement()?.isFullScreen == true
        toggleListening()
    }

    /// Called when the active space changes (e.g., switching desktops)
    @objc func receiveWorkspaceNote(_ notification: Notification) {
        print(#function, "called")
        checkFullScreen()
    }

    // MARK: - Public API

    /// Reloads snapping configuration from user defaults.
    /// Called when settings change in the preferences window.
    public func reloadFromDefaults() {
        print(#function, "called")
        if Defaults.windowSnapping.userDisabled {
            // User disabled snapping - stop if running
            if eventMonitor?.running == true {
                disableSnapping()
            }
        } else {
            if eventMonitor?.running == true {
                // Check if we need to switch event monitor type (active vs passive)
                let needsActiveMonitor = Defaults.missionControlDragging.userDisabled
                let hasActiveMonitor = eventMonitor is ActiveEventMonitor
                if needsActiveMonitor != hasActiveMonitor {
                    stopEventMonitor()
                    startEventMonitor()
                }
            } else {
                enableSnapping()
            }
        }
    }

    // MARK: - Enable/Disable Snapping

    /// Enables window snapping by creating the footprint window and starting the event monitor
    private func enableSnapping() {
        print(#function, "called")
        if box == nil {
            box = FootprintWindow()
        }
        if eventMonitor == nil {
            startEventMonitor()
        }
    }

    /// Disables window snapping by removing the footprint and stopping the event monitor
    private func disableSnapping() {
        print(#function, "called")
        box = nil
        stopEventMonitor()
    }

    // MARK: - Event Monitor Management

    /// Starts the event monitor for mouse events.
    /// Uses ActiveEventMonitor (can modify events) if Mission Control dragging is disabled,
    /// otherwise uses PassiveEventMonitor (read-only).
    private func startEventMonitor() {
        print(#function, "called")
        let mask: NSEvent.EventTypeMask = [.leftMouseDown, .leftMouseUp, .leftMouseDragged]

        if Defaults.missionControlDragging.userDisabled {
            // Active monitor can filter/modify events (needed to block Mission Control triggering)
            eventMonitor = ActiveEventMonitor(mask: mask, filterer: filter, handler: handle)
        } else {
            // Passive monitor just observes events
            eventMonitor = PassiveEventMonitor(mask: mask, handler: handle)
        }

        eventMonitor?.start()
    }

    /// Stops the event monitor
    private func stopEventMonitor() {
        print(#function, "called")
        eventMonitor?.stop()
        eventMonitor = nil
    }

    // MARK: - Event Filtering (Mission Control Drag Prevention)

    /// Filters mouse events to prevent accidental Mission Control triggering.
    /// Only used when Mission Control dragging prevention is enabled.
    ///
    /// When dragging a window quickly toward the top of the screen, macOS can
    /// trigger Mission Control. This filter modifies the event to keep the
    /// cursor slightly away from the very top edge.
    func filter(event: NSEvent) -> Bool {
        print(#function, "called")
        switch event.type {
        case .leftMouseUp:
            dragPrevY = nil

        case .leftMouseDragged:
            if let cgEvent = event.cgEvent, let screen = NSScreen.main {
                let minY = screen.frame.screenFlipped.minY

                // Check if cursor is at the very top of the screen (two frames in a row)
                let cursorAtTopEdge = cgEvent.location.y == minY && dragPrevY == minY

                if cursorAtTopEdge {
                    let allowedDistance = Defaults.missionControlDraggingAllowedOffscreenDistance.cgFloat

                    // If dragging upward too fast, restrict the cursor
                    if event.deltaY < -allowedDistance {
                        cgEvent.location.y = minY + 1
                        let restrictionDuration = UInt64(Defaults.missionControlDraggingDisallowedDuration.value)
                        dragRestrictionExpirationTimestamp = DispatchTime.now().uptimeMilliseconds + restrictionDuration
                    } else if !dragRestrictionExpired {
                        // Keep restricting until the timer expires
                        cgEvent.location.y = minY + 1
                    }
                }

                dragPrevY = cgEvent.location.y
            }

        default:
            break
        }

        // Return false = don't consume the event (let it pass through)
        return false
    }

    // MARK: - Snap Eligibility Check

    /// Checks if snapping is allowed for the current event.
    /// Returns false if modifier keys don't match or if window is in Stage Manager strip.
    func canSnap(_ event: NSEvent) -> Bool {
        print(#function, "called")
        // Check if required modifier keys are held (if configured)
        if Defaults.snapModifiers.value > 0 {
            let currentModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue
            if currentModifiers != Defaults.snapModifiers.value {
                return false
            }
        }

        // Don't snap windows in Stage Manager's strip
        if let windowId = windowId {
            let isStageManagerWindow = StageUtil.stageCapable
                && StageUtil.stageEnabled
                && StageUtil.getStageStripWindowGroup(windowId) != nil
            if isStageManagerWindow {
                return false
            }
        }

        return true
    }

    // MARK: - Main Event Handler

    /// The main event handler for mouse events.
    /// Coordinates the entire snapping flow: detection, preview, and execution.
    func handle(event: NSEvent) {
        print(#function, "called")
        switch event.type {
        case .leftMouseDown:
            handleMouseDown(event)

        case .leftMouseUp:
            handleMouseUp(event)

        case .leftMouseDragged:
            handleMouseDragged(event)

        default:
            return
        }
    }

    /// Handles mouse down - remembers which window is under the cursor
    private func handleMouseDown(_ event: NSEvent) {
        print(#function, "called")
        guard !Defaults.obtainWindowOnClick.userDisabled else { return }

        windowElement = AccessibilityElement.getWindowElementUnderCursor()
        windowId = windowElement?.getWindowId()
        initialWindowRect = windowElement?.frame
    }

    /// Handles mouse up - executes the snap action if cursor is in a snap area
    private func handleMouseUp(_ event: NSEvent) {
        print(#function, "called")
        defer {
            // Always reset state on mouse up
            windowElement = nil
            windowId = nil
            windowMoving = false
            initialWindowRect = nil
            windowIdAttempt = 0
            lastWindowIdAttempt = nil
        }

        if let currentSnapArea = self.currentSnapArea {
            // User released in a snap area - execute the snap
            box?.orderOut(nil)
            currentSnapArea.action.postSnap(
                windowElement: windowElement,
                windowId: windowId,
                screen: currentSnapArea.screen
            )
            self.currentSnapArea = nil
        } else {
            // Handle edge case: window moved but drag events didn't update position
            // (happens when dragging windows very quickly)
            handleQuickDragSnapOnMouseUp(event)
        }
    }

    /// Handles the edge case where a window was dragged quickly and footprint didn't show,
    /// but we still want to snap if the window ended up in a snap area.
    private func handleQuickDragSnapOnMouseUp(_ event: NSEvent) {
        print(#function, "called")
        guard let currentRect = windowElement?.frame,
              let windowId = windowId,
              currentRect.size == initialWindowRect?.size,
              currentRect.origin != initialWindowRect?.origin
        else { return }

        unsnapRestore(windowId: windowId, currentRect: currentRect, cursorLoc: event.cgEvent?.location)

        if let snapArea = snapAreaContainingCursor(priorSnapArea: currentSnapArea) {
            box?.orderOut(nil)
            if canSnap(event) {
                snapArea.action.postSnap(
                    windowElement: windowElement,
                    windowId: windowId,
                    screen: snapArea.screen
                )
            }
            self.currentSnapArea = nil
        }
    }

    /// Handles mouse dragged - detects snap areas and shows the footprint preview
    private func handleMouseDragged(_ event: NSEvent) {
        print(#function, "called")
        // Try to get the window ID if we don't have it yet
        tryToGetWindowId(event)

        guard let currentRect = windowElement?.frame,
              let windowId = windowId
        else { return }

        // Detect when the user starts moving the window
        detectWindowMovementStart(currentRect: currentRect, windowId: windowId, event: event)

        // If window is being moved, check for snap areas
        if windowMoving {
            updateSnapAreaAndFootprint(event: event, currentRect: currentRect, windowId: windowId)
        }
    }

    /// Tries to get the window ID, with throttling and retry limits
    private func tryToGetWindowId(_ event: NSEvent) {
        print(#function, "called")
        guard windowId == nil, windowIdAttempt < 20 else { return }

        // Throttle attempts to every 0.1 seconds
        if let lastAttempt = lastWindowIdAttempt {
            if event.timestamp - lastAttempt < 0.1 {
                return
            }
        }

        if windowElement == nil {
            windowElement = AccessibilityElement.getWindowElementUnderCursor()
        }
        windowId = windowElement?.getWindowId()
        initialWindowRect = windowElement?.frame
        windowIdAttempt += 1
        lastWindowIdAttempt = event.timestamp
    }

    /// Detects when the user starts actually moving the window (not just clicking)
    private func detectWindowMovementStart(currentRect: CGRect, windowId: CGWindowID, event: NSEvent) {
        print(#function, "called")
        guard !windowMoving else { return }

        if let initialWindowRect = initialWindowRect {
            // Window is moving if: same size (or few shared edges) but different position
            let sameSize = currentRect.size == initialWindowRect.size
            let fewSharedEdges = currentRect.numSharedEdges(withRect: initialWindowRect) < 2
            let positionChanged = currentRect.origin != initialWindowRect.origin

            if (sameSize || fewSharedEdges) && positionChanged {
                windowMoving = true
                unsnapRestore(windowId: windowId, currentRect: currentRect, cursorLoc: event.cgEvent?.location)
            }
        } else {
            // No initial rect means this might be a resize, not a move
            AppDelegate.windowHistory.lasttiny_window_managerActions.removeValue(forKey: windowId)
        }
    }

    /// Updates the current snap area and footprint preview during dragging
    private func updateSnapAreaAndFootprint(event: NSEvent, currentRect: CGRect, windowId: CGWindowID) {
        print(#function, "called")
        // Check if snapping is allowed with current modifiers
        if !canSnap(event) {
            if currentSnapArea != nil {
                box?.orderOut(nil)
                currentSnapArea = nil
            }
            return
        }

        // Check if cursor is in a snap area
        if let snapArea = snapAreaContainingCursor(priorSnapArea: currentSnapArea) {
            // Same snap area as before - no update needed
            if snapArea == currentSnapArea {
                return
            }

            // New snap area - provide haptic feedback
            if Defaults.hapticFeedbackOnSnap.userEnabled {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }

            // Calculate and show the footprint
            let currentWindow = Window(id: windowId, rect: currentRect)
            showFootprint(for: snapArea, currentWindow: currentWindow)
            currentSnapArea = snapArea
        } else {
            // Cursor left all snap areas - hide footprint
            if currentSnapArea != nil {
                box?.orderOut(nil)
                currentSnapArea = nil
            }
        }
    }

    /// Shows the footprint preview for a snap area
    private func showFootprint(for snapArea: SnapArea, currentWindow: Window) {
        print(#function, "called")
        guard let newBoxRect = getBoxRect(hotSpot: snapArea, currentWindow: currentWindow) else {
            return
        }

        // Create footprint window if needed
        if box == nil {
            box = FootprintWindow()
        }

        let animationEnabled = Defaults.footprintAnimationDurationMultiplier.value > 0

        if animationEnabled {
            // Set initial position for animation (starts from the snap edge)
            if !box!.realIsVisible, let origin = getFootprintAnimationOrigin(snapArea, newBoxRect) {
                let frame = CGRect(origin: origin, size: .zero)
                box!.setFrame(frame, display: false)
            }
        } else {
            // No animation - just set the frame directly
            box!.setFrame(newBoxRect, display: true)
        }

        box!.orderFront(nil)

        // Animate to final size if enabled
        if animationEnabled {
            NSAnimationContext.runAnimationGroup { changes in
                changes.duration = getFootprintAnimationDuration(box!, newBoxRect)
                box!.animator().setFrame(newBoxRect, display: true)
            }
        }
    }

    // MARK: - Unsnap Restore

    /// Restores a window to its original size when it's "unsnapped" (dragged away from a snap position).
    /// This gives users a way to get back to the window's original dimensions.
    func unsnapRestore(windowId: CGWindowID, currentRect: CGRect, cursorLoc: CGPoint?) {
        print(#function, "called")
        guard Defaults.unsnapRestore.enabled != false else { return }

        let windowHistory = AppDelegate.windowHistory

        // Check if this window was snapped by tiny_window_manager
        guard let lastAction = windowHistory.lasttiny_window_managerActions[windowId],
              lastAction.rect == initialWindowRect,
              let restoreRect = windowHistory.restoreRects[windowId]
        else {
            // Not a tiny_window_manager-snapped window - save current size for future restore
            windowHistory.restoreRects[windowId] = initialWindowRect
            return
        }

        // Restore the window to its original size
        guard let windowElement = windowElement else { return }

        if #available(macOS 12, *) {
            // macOS 12+ can reposition while resizing without stuttering
            var newRect = currentRect
            newRect.size = restoreRect.size

            // Try to keep the cursor inside the restored window
            if let cursorLoc = cursorLoc {
                if !newRect.contains(cursorLoc) {
                    // Try keeping the same maxX
                    newRect.origin = CGPoint(x: currentRect.maxX - newRect.width, y: newRect.minY)

                    if !newRect.contains(cursorLoc) {
                        // Center on cursor as fallback
                        newRect.origin = CGPoint(x: cursorLoc.x - (newRect.width / 2), y: newRect.minY)
                    }
                }
            }

            windowElement.setFrame(newRect, adjustSizeFirst: false)
        } else {
            // Older macOS versions stutter if we reposition, so just resize
            windowElement.size = restoreRect.size
        }

        windowHistory.lasttiny_window_managerActions.removeValue(forKey: windowId)
    }

    // MARK: - Footprint Animation Helpers

    /// Calculates the animation duration for the footprint based on distance and user preference
    func getFootprintAnimationDuration(_ box: FootprintWindow, _ boxRect: CGRect) -> Double {
        print(#function, "called")
        let baseDuration = box.animationResizeTime(boxRect)
        let multiplier = Double(Defaults.footprintAnimationDurationMultiplier.value)
        return baseDuration * multiplier
    }

    /// Returns the origin point for the footprint animation.
    /// The footprint "grows" from the edge/corner where the snap area is located.
    func getFootprintAnimationOrigin(_ snapArea: SnapArea, _ boxRect: CGRect) -> CGPoint? {
        print(#function, "called")
        switch snapArea.directional {
        case .tl:
            return CGPoint(x: boxRect.minX, y: boxRect.maxY)  // Top-left corner
        case .t:
            return CGPoint(x: boxRect.midX, y: boxRect.maxY)  // Top edge center
        case .tr:
            return CGPoint(x: boxRect.maxX, y: boxRect.maxY)  // Top-right corner
        case .l:
            return CGPoint(x: boxRect.minX, y: boxRect.midY)  // Left edge center
        case .r:
            return CGPoint(x: boxRect.maxX, y: boxRect.midY)  // Right edge center
        case .bl:
            return CGPoint(x: boxRect.minX, y: boxRect.minY)  // Bottom-left corner
        case .b:
            return CGPoint(x: boxRect.midX, y: boxRect.minY)  // Bottom edge center
        case .br:
            return CGPoint(x: boxRect.maxX, y: boxRect.minY)  // Bottom-right corner
        default:
            return nil
        }
    }

    // MARK: - Footprint Rectangle Calculation

    /// Calculates the rectangle for the footprint preview.
    /// Uses the same calculation as the actual snap action, including gaps.
    func getBoxRect(hotSpot: SnapArea, currentWindow: Window) -> CGRect? {
        print(#function, "called")
        guard let calculation = WindowCalculationFactory.calculationsByAction[hotSpot.action] else {
            return nil
        }

        // Check if this is a Todo window (affects visible frame calculation)
        let ignoreTodo = TodoManager.isTodoWindow(currentWindow.id)

        // Calculate the window rectangle
        let rectCalcParams = RectCalculationParameters(
            window: currentWindow,
            visibleFrameOfScreen: hotSpot.screen.adjustedVisibleFrame(ignoreTodo),
            action: hotSpot.action,
            lastAction: nil
        )
        let rectResult = calculation.calculateRect(rectCalcParams)

        // Apply gaps if configured
        let gapsApplicable = hotSpot.action.gapsApplicable
        if Defaults.gapSize.value > 0, gapsApplicable != .none {
            let gapSharedEdges = rectResult.subAction?.gapSharedEdge ?? hotSpot.action.gapSharedEdge
            return GapCalculation.applyGaps(
                rectResult.rect,
                dimension: gapsApplicable,
                sharedEdges: gapSharedEdges,
                gapSize: Defaults.gapSize.value
            )
        }

        return rectResult.rect
    }

    // MARK: - Snap Area Detection

    /// Finds the snap area containing the cursor, if any.
    /// Checks all screens and returns the appropriate snap area configuration.
    func snapAreaContainingCursor(priorSnapArea: SnapArea?) -> SnapArea? {
        print(#function, "called")
        let cursorLocation = NSEvent.mouseLocation

        for screen in NSScreen.screens {
            guard let directional = directionalLocationOfCursor(loc: cursorLocation, screen: screen) else {
                continue
            }

            // Special handling for Todo windows
            if let snapArea = checkForTodoSnapArea(directional: directional, screen: screen) {
                return snapArea
            }

            // Get the snap area configuration for this screen position
            let config = screen.frame.isLandscape
                ? SnapAreaModel.instance.landscape[directional]
                : SnapAreaModel.instance.portrait[directional]

            // Return a simple action snap area
            if let action = config?.action {
                return SnapArea(screen: screen, directional: directional, action: action)
            }

            // Return a compound snap area (calculates action based on cursor position)
            if let compound = config?.compound {
                return compound.calculation.snapArea(
                    cursorLocation: cursorLocation,
                    screen: screen,
                    directional: directional,
                    priorSnapArea: priorSnapArea
                )
            }
        }

        return nil
    }

    /// Checks if the current window is a Todo window and should snap to a Todo sidebar position
    private func checkForTodoSnapArea(directional: Directional, screen: NSScreen) -> SnapArea? {
        print(#function, "called")
        guard let windowId = windowId,
              Defaults.todo.userEnabled,
              Defaults.todoMode.enabled,
              TodoManager.isTodoWindow(windowId)
        else {
            return nil
        }

        // Todo windows snap to their configured sidebar side
        if Defaults.todoSidebarSide.value == .left && directional == .l {
            return SnapArea(screen: screen, directional: directional, action: .leftTodo)
        }
        if Defaults.todoSidebarSide.value == .right && directional == .r {
            return SnapArea(screen: screen, directional: directional, action: .rightTodo)
        }

        return nil
    }

    // MARK: - Cursor Position Detection

    /// Determines which screen edge/corner the cursor is in (if any).
    /// Returns nil if the cursor is not near any edge.
    ///
    /// Detection regions:
    /// ```
    /// ┌────┬─────────────────┬────┐
    /// │ TL │        T        │ TR │  ← Corner + edge detection zones
    /// ├────┤                 ├────┤
    /// │    │                 │    │
    /// │ L  │    (center)     │ R  │  ← Edge detection zones
    /// │    │                 │    │
    /// ├────┤                 ├────┤
    /// │ BL │        B        │ BR │
    /// └────┴─────────────────┴────┘
    /// ```
    func directionalLocationOfCursor(loc: NSPoint, screen: NSScreen) -> Directional? {
        print(#function, "called")
        let frame = screen.frame
        let cornerSize = Defaults.cornerSnapAreaSize.cgFloat

        // Check if cursor is on this screen (CGRect.contains doesn't include max edges)
        guard loc.x >= frame.minX,
              loc.x <= frame.maxX,
              loc.y >= frame.minY,
              loc.y <= frame.maxY
        else {
            return nil
        }

        // Check LEFT side (corners first, then edge)
        if loc.x < frame.minX + marginLeft + cornerSize {
            if loc.y >= frame.maxY - marginTop - cornerSize {
                return .tl  // Top-left corner
            }
            if loc.y <= frame.minY + marginBottom + cornerSize {
                return .bl  // Bottom-left corner
            }
            if loc.x < frame.minX + marginLeft {
                return .l   // Left edge
            }
        }

        // Check RIGHT side (corners first, then edge)
        if loc.x > frame.maxX - marginRight - cornerSize {
            if loc.y >= frame.maxY - marginTop - cornerSize {
                return .tr  // Top-right corner
            }
            if loc.y <= frame.minY + marginBottom + cornerSize {
                return .br  // Bottom-right corner
            }
            if loc.x > frame.maxX - marginRight {
                return .r   // Right edge
            }
        }

        // Check TOP and BOTTOM edges (not in corners)
        if loc.y > frame.maxY - marginTop {
            return .t  // Top edge
        }
        if loc.y < frame.minY + marginBottom {
            return .b  // Bottom edge
        }

        // Cursor is not in any snap zone
        return nil
    }
}
