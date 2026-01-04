//  ShortcutViewModel.swift - View model for shortcut configuration
//
//  Provides an abstraction for the shortcuts view to display and edit
//  keyboard shortcuts for window actions.

import SwiftUI
import WindowManagerCore

// MARK: - ShortcutItem

/// Represents a single shortcut item in the UI.
public struct ShortcutItem: Identifiable, Sendable {
    public let id: Int
    public let actionType: WindowActionType
    public let displayName: String

    public init(id: Int, actionType: WindowActionType, displayName: String) {
        self.id = id
        self.actionType = actionType
        self.displayName = displayName
    }
}

// MARK: - ShortcutViewModelProtocol

/// Protocol for shortcut view models.
///
/// Implement this to provide shortcut data to the ShortcutsView.
public protocol ShortcutViewModelProtocol: ObservableObject {
    /// All available shortcut items
    var allShortcuts: [ShortcutItem] { get }

    /// Main shortcuts shown by default
    var mainShortcuts: [ShortcutItem] { get }

    /// Additional shortcuts shown when expanded
    var additionalShortcuts: [ShortcutItem] { get }

    /// Get the shortcut recorder view for an action
    func shortcutRecorderView(for item: ShortcutItem) -> AnyView
}

// MARK: - Default Implementation

/// A default implementation for previews.
public class PreviewShortcutViewModel: ShortcutViewModelProtocol {
    @Published public var allShortcuts: [ShortcutItem] = []

    public var mainShortcuts: [ShortcutItem] {
        Array(allShortcuts.prefix(18))
    }

    public var additionalShortcuts: [ShortcutItem] {
        Array(allShortcuts.dropFirst(18))
    }

    public init() {
        let mainActions: [WindowActionType] = [
            .leftHalf, .rightHalf, .centerHalf, .topHalf, .bottomHalf,
            .topLeft, .topRight, .bottomLeft, .bottomRight,
            .maximize, .almostMaximize, .maximizeHeight,
            .larger, .smaller,
            .center, .restore,
            .nextDisplay, .previousDisplay
        ]

        let additionalActions: [WindowActionType] = [
            .firstThird, .centerThird, .lastThird,
            .firstTwoThirds, .centerTwoThirds, .lastTwoThirds,
            .moveLeft, .moveRight, .moveUp, .moveDown
        ]

        let all = mainActions + additionalActions
        self.allShortcuts = all.enumerated().map { index, action in
            ShortcutItem(
                id: action.rawValue,
                actionType: action,
                displayName: action.name
            )
        }
    }

    public func shortcutRecorderView(for item: ShortcutItem) -> AnyView {
        AnyView(
            Text("⌘⌥←")
                .font(.system(size: 11, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
        )
    }
}
