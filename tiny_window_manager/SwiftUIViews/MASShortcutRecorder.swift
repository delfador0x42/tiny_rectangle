//
//  MASShortcutRecorder.swift
//  tiny_window_manager
//
//  NSViewRepresentable wrapper for MASShortcutView.
//  Allows using the existing MASShortcut library in SwiftUI views.
//

import SwiftUI
import MASShortcut

// MARK: - MASShortcutRecorder

/// A SwiftUI wrapper for MASShortcutView that records keyboard shortcuts.
///
/// Usage:
/// ```swift
/// MASShortcutRecorder(action: .leftHalf)
/// ```
///
/// The shortcut is automatically persisted to UserDefaults using the action's name as the key.
struct MASShortcutRecorder: NSViewRepresentable {

    /// The window action this recorder is associated with.
    let action: WindowAction

    /// Optional: Use a custom UserDefaults key instead of action.name
    var customKey: String?

    /// The UserDefaults key used for storing this shortcut.
    private var defaultsKey: String {
        customKey ?? action.name
    }

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> MASShortcutView {
        let view = MASShortcutView()

        // Bind to UserDefaults using the action's name as the key
        view.setAssociatedUserDefaultsKey(defaultsKey, withTransformerName: MASDictionaryTransformerName)

        // Apply permissive validator if "Allow Any Shortcut" is enabled
        if Defaults.allowAnyShortcut.enabled {
            view.shortcutValidator = PassthroughShortcutValidator()
        }

        return view
    }

    func updateNSView(_ nsView: MASShortcutView, context: Context) {
        // Update validator if setting changes
        if Defaults.allowAnyShortcut.enabled {
            nsView.shortcutValidator = PassthroughShortcutValidator()
        } else {
            nsView.shortcutValidator = MASShortcutValidator()
        }
    }
}

// MARK: - Generic Key Recorder

/// A SwiftUI wrapper for MASShortcutView using a custom string key.
/// Useful for shortcuts not tied to WindowAction (e.g., TodoManager shortcuts).
///
/// Usage:
/// ```swift
/// MASShortcutKeyRecorder(key: "toggleTodo")
/// ```
struct MASShortcutKeyRecorder: NSViewRepresentable {

    /// The UserDefaults key for this shortcut.
    let key: String

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> MASShortcutView {
        let view = MASShortcutView()

        // Bind to UserDefaults
        view.setAssociatedUserDefaultsKey(key, withTransformerName: MASDictionaryTransformerName)

        // Apply permissive validator if "Allow Any Shortcut" is enabled
        if Defaults.allowAnyShortcut.enabled {
            view.shortcutValidator = PassthroughShortcutValidator()
        }

        return view
    }

    func updateNSView(_ nsView: MASShortcutView, context: Context) {
        // Update validator if setting changes
        if Defaults.allowAnyShortcut.enabled {
            nsView.shortcutValidator = PassthroughShortcutValidator()
        } else {
            nsView.shortcutValidator = MASShortcutValidator()
        }
    }
}

// MARK: - Preview

#Preview("Shortcut Recorder") {
    VStack(spacing: 20) {
        HStack {
            Text("Left Half:")
            MASShortcutRecorder(action: .leftHalf)
                .frame(width: 140, height: 25)
        }

        HStack {
            Text("Maximize:")
            MASShortcutRecorder(action: .maximize)
                .frame(width: 140, height: 25)
        }
    }
    .padding()
}
