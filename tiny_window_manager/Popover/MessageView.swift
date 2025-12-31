//
//  MessageView.swift
//  Multitouch
//
//

import Cocoa

// MARK: - MessagePopover

/// A helper class that manages showing a popover with a text message.
/// Use this to display brief informational messages anchored to a view.
class MessagePopover {

    /// The view controller that displays the message content
    var messageView: MessageView

    /// The popover container that presents the message view
    var popover: NSPopover

    init() {
        print(#function, "called")
        // Create the popover container
        popover = NSPopover()

        // Create the view that will show our message
        messageView = MessageView()

        // "transient" means the popover closes when clicking outside it
        popover.behavior = .transient

        // Connect the message view to the popover
        popover.contentViewController = messageView
    }

    /// Shows the popover with a message, anchored to a specific view.
    ///
    /// - Parameters:
    ///   - message: The text to display in the popover
    ///   - sender: The view that the popover should be anchored to
    public func show(message: String, sender: NSView) {
        print(#function, "called")
        // Store the message so the view can display it
        messageView.message = message

        // Show the popover:
        // - relativeTo: NSZeroRect means anchor to the entire sender view
        // - of: the view to anchor the popover to
        // - preferredEdge: .maxX means show on the right side of the sender
        popover.show(relativeTo: NSZeroRect, of: sender, preferredEdge: .maxX)
    }
}

// MARK: - MessageView

/// A simple view controller that displays a single text message.
/// This is used as the content inside a popover.
class MessageView: NSViewController {

    /// The text field that displays the message (connected from Interface Builder)
    @IBOutlet weak var messageField: NSTextField!

    /// The message text to display. Set this before showing the view.
    var message: String?

    /// Called just before the view appears on screen.
    /// We use this to update the text field with our message.
    override func viewWillAppear() {
        print(#function, "called")
        super.viewWillAppear()

        // Update the text field if we have a message
        if let messageText = message {
            messageField?.stringValue = messageText
        }
    }
}
