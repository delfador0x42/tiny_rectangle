//
//  StringExtension.swift
//  tiny_window_manager
//
//  Adds localization support to String for easy translation of UI text.
//

import Foundation

// MARK: - String Localization Extension

extension String {

    /// Returns the localized version of this string from the "Main" strings table.
    ///
    /// This allows you to write localized strings in a clean, readable way:
    /// ```swift
    /// let greeting = "hello_message".localized
    /// // Returns "Hello!" if Main.strings contains: "hello_message" = "Hello!";
    /// ```
    ///
    /// The string value (e.g., "hello_message") acts as a key that looks up
    /// the translated text in the app's Main.strings localization file.
    /// If no translation is found, the original string is returned as a fallback.
    var localized: String {
        return NSLocalizedString(self, tableName: "Main", comment: "")
    }
}
