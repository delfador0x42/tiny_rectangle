//
//  ShortcutRecorder.swift
//  tiny_window_manager
//
//  SwiftUI wrapper for KeyboardShortcuts recorder.
//

import SwiftUI
import KeyboardShortcuts

// MARK: - ShortcutRecorder

/// A SwiftUI view that records keyboard shortcuts for a WindowAction.
struct ShortcutRecorder: View {
    let action: WindowAction

    var body: some View {
        KeyboardShortcuts.Recorder(for: .init(action))
    }
}

// MARK: - Backwards Compatibility Aliases

/// Alias for backwards compatibility with existing code.
typealias MASShortcutRecorder = ShortcutRecorder

/// A SwiftUI view that records keyboard shortcuts using a custom string key.
struct ShortcutKeyRecorder: View {
    let key: String

    var body: some View {
        KeyboardShortcuts.Recorder(for: KeyboardShortcuts.Name(key))
    }
}

/// Alias for backwards compatibility with existing code.
typealias MASShortcutKeyRecorder = ShortcutKeyRecorder

// MARK: - Preview

#Preview("Shortcut Recorder") {
    VStack(spacing: 20) {
        HStack {
            Text("Left Half:")
            ShortcutRecorder(action: .leftHalf)
                .frame(width: 140, height: 25)
        }

        HStack {
            Text("Maximize:")
            ShortcutRecorder(action: .maximize)
                .frame(width: 140, height: 25)
        }
    }
    .padding()
}
