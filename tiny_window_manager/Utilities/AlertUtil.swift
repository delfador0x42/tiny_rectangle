//
//  AlertUtil.swift
//  tiny_window_manager
//
//

import Cocoa

/// A utility class for displaying alert dialogs to the user.
/// All methods are static, so you can call them directly without creating an instance.
/// Example: AlertUtil.oneButtonAlert(question: "Hello", text: "World")
class AlertUtil {

    // MARK: - Public Methods

    /// Shows a simple alert with one button (typically "OK").
    /// Use this when you just need to inform the user about something.
    /// - Parameters:
    ///   - question: The main title of the alert (shown in bold)
    ///   - text: Additional details shown below the title
    ///   - confirmText: The text for the button (defaults to "OK")
    static func oneButtonAlert(question: String, text: String, confirmText: String = "OK") {
        print(#function, "called")
        let alert = createBaseAlert(question: question, text: text)
        alert.addButton(withTitle: confirmText)
        alert.runModal()
    }

    /// Shows an alert with two buttons (typically "OK" and "Cancel").
    /// Use this when you need the user to confirm or cancel an action.
    /// - Parameters:
    ///   - question: The main title of the alert (shown in bold)
    ///   - text: Additional details shown below the title
    ///   - confirmText: The text for the confirm button (defaults to "OK")
    ///   - cancelText: The text for the cancel button (defaults to "Cancel")
    /// - Returns: The user's response. Compare with .alertFirstButtonReturn for confirm.
    static func twoButtonAlert(question: String, text: String, confirmText: String = "OK", cancelText: String = "Cancel") -> NSApplication.ModalResponse {
        print(#function, "called")
        let alert = createBaseAlert(question: question, text: text)
        alert.addButton(withTitle: confirmText)
        alert.addButton(withTitle: cancelText)
        return alert.runModal()
    }

    /// Shows an alert with three buttons for more complex choices.
    /// - Parameters:
    ///   - question: The main title of the alert (shown in bold)
    ///   - text: Additional details shown below the title
    ///   - buttonOneText: Text for the first button (rightmost, primary action)
    ///   - buttonTwoText: Text for the second button
    ///   - buttonThreeText: Text for the third button (leftmost)
    /// - Returns: The user's response. Use .alertFirstButtonReturn, .alertSecondButtonReturn, etc.
    static func threeButtonAlert(question: String, text: String, buttonOneText: String, buttonTwoText: String, buttonThreeText: String) -> NSApplication.ModalResponse {
        print(#function, "called")
        let alert = createBaseAlert(question: question, text: text)
        alert.addButton(withTitle: buttonOneText)
        alert.addButton(withTitle: buttonTwoText)
        alert.addButton(withTitle: buttonThreeText)
        return alert.runModal()
    }

    // MARK: - Private Helpers

    /// Creates a basic NSAlert with common settings applied.
    /// This avoids repeating the same setup code in every public method.
    /// - Parameters:
    ///   - question: The main title of the alert
    ///   - text: The informative text below the title
    /// - Returns: A configured NSAlert ready to have buttons added
    private static func createBaseAlert(question: String, text: String) -> NSAlert {
        print(#function, "called")
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        return alert
    }
}
