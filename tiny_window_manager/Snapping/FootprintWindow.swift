//
//  FootprintWindow.swift
//  tiny_window_manager
//
//  The "footprint" is the translucent preview rectangle that appears when you
//  drag a window toward a screen edge. It shows where the window will snap to
//  if you release the mouse.
//
//  This is a custom NSWindow subclass that:
//  - Appears as a semi-transparent overlay (not a normal window)
//  - Has no title bar, close button, or other window chrome
//  - Optionally fades in/out smoothly instead of appearing instantly
//  - Works around macOS Stage Manager quirks
//

import Cocoa

class FootprintWindow: NSWindow {

    // MARK: - Properties

    /// Used to cancel a pending fade-out animation if the window needs to reappear quickly.
    /// This prevents flickering when the user rapidly moves between snap zones.
    private var orderOutCanceled = false

    // MARK: - Initialization

    init() {
        print(#function, "called")
        // Start with a zero-size rect (will be resized when shown)
        let initialRect = NSRect(x: 0, y: 0, width: 0, height: 0)
        super.init(contentRect: initialRect, styleMask: .titled, backing: .buffered, defer: false)

        configureWindowAppearance()
        configureWindowBehavior()
        hideWindowControls()
        createFootprintView()
    }

    /// Configures the window to appear as a transparent overlay
    private func configureWindowAppearance() {
        print(#function, "called")
        title = "tiny_window_manager"
        isOpaque = false
        hasShadow = false

        // Start fully transparent if fade is enabled, otherwise use the user's alpha setting
        let fadeEnabled = !Defaults.footprintFade.userDisabled
        alphaValue = fadeEnabled ? 0 : CGFloat(Defaults.footprintAlpha.value)

        // Make the content view extend under the title bar area
        styleMask.insert(.fullSizeContentView)
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
    }

    /// Configures how the window behaves in the window hierarchy
    private func configureWindowBehavior() {
        print(#function, "called")
        // Appear above most other windows (like a modal dialog)
        level = .modalPanel

        // Don't deallocate when closed (we reuse this window)
        isReleasedWhenClosed = false

        // Don't show in Mission Control, Exposé, or the Dock
        collectionBehavior.insert(.transient)
    }

    /// Hides all standard window buttons (close, minimize, zoom, toolbar)
    private func hideWindowControls() {
        print(#function, "called")
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        standardWindowButton(.toolbarButton)?.isHidden = true
    }

    /// Creates the rounded rectangle view that shows the snap preview
    private func createFootprintView() {
        print(#function, "called")
        let boxView = NSBox()
        boxView.boxType = .custom
        boxView.borderColor = .lightGray
        boxView.borderWidth = CGFloat(Defaults.footprintBorderWidth.value)
        boxView.cornerRadius = cornerRadiusForCurrentOS()
        boxView.wantsLayer = true
        boxView.fillColor = Defaults.footprintColor.typedValue?.nsColor ?? NSColor.black

        contentView = boxView
    }

    /// Returns the appropriate corner radius based on macOS version.
    /// Newer macOS versions use more rounded corners in their UI.
    private func cornerRadiusForCurrentOS() -> CGFloat {
        print(#function, "called")
        if #available(macOS 26.0, *) {
            return 16  // Future macOS - most rounded
        } else if #available(macOS 11.0, *) {
            return 10  // Big Sur and later - moderately rounded
        } else {
            return 5   // Catalina and earlier - slightly rounded
        }
    }

    // MARK: - Visibility (with Stage Manager Workaround)

    /// Whether the footprint is currently visible on screen.
    ///
    /// Note: This includes a workaround for macOS Stage Manager. When Stage Manager
    /// is active with the strip visible, we always report as visible to prevent
    /// the footprint from being incorrectly pushed off-screen.
    override var isVisible: Bool {
        let isStageManagerActive = StageUtil.stageCapable
            && StageUtil.stageEnabled
            && StageUtil.stageStripShow

        if isStageManagerActive {
            return true
        }

        return realIsVisible
    }

    /// The actual visibility state, ignoring Stage Manager workarounds.
    /// When fade is enabled, visibility is determined by alpha value rather than window state.
    var realIsVisible: Bool {
        let fadeEnabled = !Defaults.footprintFade.userDisabled

        if fadeEnabled {
            // With fade enabled, we consider it "visible" when fully opaque
            return alphaValue == Defaults.footprintAlpha.cgFloat
        } else {
            // Without fade, use the standard visibility check
            return super.isVisible
        }
    }

    // MARK: - Show/Hide with Optional Fade Animation

    /// Shows the footprint window, optionally with a fade-in animation.
    override func orderFront(_ sender: Any?) {
        print(#function, "called")
        let fadeEnabled = !Defaults.footprintFade.userDisabled

        if fadeEnabled {
            // Cancel any pending fade-out animation
            orderOutCanceled = true

            // Show the window (still transparent) then animate to full opacity
            super.orderFront(sender)
            animator().alphaValue = Defaults.footprintAlpha.cgFloat
        } else {
            // No fade - just show immediately
            super.orderFront(sender)
        }
    }

    /// Hides the footprint window, optionally with a fade-out animation.
    override func orderOut(_ sender: Any?) {
        print(#function, "called")
        let fadeEnabled = !Defaults.footprintFade.userDisabled

        if fadeEnabled {
            // Mark that we're starting a fade-out (can be canceled if orderFront is called)
            orderOutCanceled = false

            // Animate to transparent, then actually hide the window
            NSAnimationContext.runAnimationGroup { _ in
                animator().alphaValue = 0.0
            } completionHandler: {
                // Only hide if the fade-out wasn't canceled by a new orderFront call
                if !self.orderOutCanceled {
                    super.orderOut(nil)
                }
            }
        } else {
            // No fade - just hide immediately
            super.orderOut(nil)
        }
    }
}
