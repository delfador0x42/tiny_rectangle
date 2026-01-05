//
//  LogViewer.swift
//  tiny_window_manager
//
//  This file provides a simple logging window for debugging purposes.
//  It shows timestamped log messages in a scrollable text view.
//
//  Usage:
//    Logger.showLogging(sender: nil)  // Open the log window
//    Logger.log("Something happened")  // Add a message to the log
//

import Cocoa

// MARK: - Logger Class

/// A simple static logger that displays messages in a floating window.
class Logger {

    /// Whether the log window is currently open and accepting messages.
    static var logging = false

    /// The window controller for the log viewer (created lazily when first opened)
    static private var logWindowController: LogWindowController?

    /// Opens the log viewer window and starts capturing log messages.
    static func showLogging(sender: Any?) {
        if logWindowController == nil {
            logWindowController = LogWindowController()
        }
        NSApp.activate(ignoringOtherApps: true)
        logWindowController?.showWindow(sender)
        logging = true
    }

    /// Adds a timestamped message to the log window.
    static func log(_ string: String) {
        if logging {
            logWindowController?.append(string)
        }
    }
}

// MARK: - LogWindowController Class

/// The window controller that manages the log viewer window.
class LogWindowController: NSWindowController, NSWindowDelegate {

    private let logViewController = LogViewController()

    convenience init() {
        // Create toolbar with clear button
        let clearButton = NSButton(title: "Clear", target: nil, action: #selector(clearClicked(_:)))
        clearButton.bezelStyle = .rounded

        let toolbar = NSStackView(views: [NSView(), clearButton])
        toolbar.orientation = .horizontal
        toolbar.distribution = .fill
        toolbar.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        // Create main container with toolbar and log view
        let container = NSStackView(views: [toolbar, NSView()])
        container.orientation = .vertical
        container.distribution = .fill
        container.spacing = 0

        // Create the window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "tiny_window_manager Log"
        window.minSize = NSSize(width: 300, height: 200)
        window.center()

        self.init(window: window)

        // Set up the view hierarchy
        window.contentViewController = logViewController
        window.delegate = self
        clearButton.target = self
    }

    @IBAction func clearClicked(_ sender: Any) {
        logViewController.clear()
    }

    func append(_ string: String) {
        let datestamp = ISO8601DateFormatter.string(
            from: Date(),
            timeZone: TimeZone.current,
            formatOptions: .withInternetDateTime
        )
        let formattedMessage = datestamp + ": " + string + "\n"
        logViewController.append(formattedMessage)
    }

    func windowWillClose(_ notification: Notification) {
        Logger.logging = false
        clearClicked(self)
    }
}

// MARK: - LogViewController Class

/// The view controller that contains the scrolling text view for log messages.
class LogViewController: NSViewController {

    private var textView: NSTextView!
    private let font = NSFont(name: "Monaco", size: 10) ?? NSFont.systemFont(ofSize: 10)

    private var textColorAttribute: [NSAttributedString.Key: Any] {
        [.foregroundColor: NSColor.textColor, .font: font]
    }

    override func loadView() {
        // Create text view
        textView = KeyDownTextView()
        textView.isEditable = false
        textView.isRichText = false
        textView.font = font
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.autoresizingMask = [.width, .height]

        // Wrap in scroll view
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        // Create toolbar with clear button
        let clearButton = NSButton(title: "Clear", target: nil, action: nil)
        clearButton.bezelStyle = .rounded
        clearButton.target = self
        clearButton.action = #selector(clearButtonClicked)

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let toolbar = NSStackView(views: [spacer, clearButton])
        toolbar.orientation = .horizontal
        toolbar.edgeInsets = NSEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        // Main container
        let container = NSStackView(views: [toolbar, scrollView])
        container.orientation = .vertical
        container.distribution = .fill
        container.spacing = 0

        // Configure scroll view to expand
        scrollView.setContentHuggingPriority(.defaultLow, for: .vertical)

        self.view = container
    }

    @objc private func clearButtonClicked() {
        clear()
    }

    func append(_ string: String) {
        let isScrolledToBottom = textView.visibleRect.maxY == textView.bounds.maxY
        let styledText = NSAttributedString(string: string, attributes: textColorAttribute)
        textView.textStorage?.append(styledText)
        if isScrolledToBottom {
            textView.scrollToEndOfDocument(self)
        }
    }

    func clear() {
        textView.string = ""
    }
}

// MARK: - KeyDownTextView Class

/// A custom NSTextView subclass that handles keyboard shortcuts.
class KeyDownTextView: NSTextView {

    override func keyDown(with event: NSEvent) {
        let isCommandPressed = event.modifierFlags.contains(.command)
        if isCommandPressed {
            switch event.charactersIgnoringModifiers {
            case "w": window?.close()
            case "h": window?.orderOut(self)
            default: super.keyDown(with: event)
            }
        } else {
            super.keyDown(with: event)
        }
    }
}
