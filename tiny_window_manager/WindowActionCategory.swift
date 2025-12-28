//
//  WindowActionCategory.swift
//  tiny_window_manager
//
//  This file defines categories for grouping window actions in the UI.
//  Categories are used to organize actions into submenus and settings sections.
//

import Foundation

// MARK: - WindowActionCategory Enum

/// Categories for grouping related window actions together.
///
/// Used in two main places:
/// 1. **Submenus**: Some categories (fourths, sixths, move) appear as submenus
///    in the menu bar dropdown to reduce clutter.
/// 2. **Settings**: Categories help organize the keyboard shortcuts settings panel.
///
/// See `WindowAction.category` and `WindowAction.classification` for how
/// actions are assigned to categories.
enum WindowActionCategory {

    // MARK: Screen Division Categories
    /// Split screen into 2 equal parts (left/right or top/bottom)
    case halves

    /// Split screen into 3 equal parts
    case thirds

    /// Split screen into 4 equal parts (quarters)
    case fourths

    /// Split screen into 6 parts (2×3 or 3×2 grid)
    case sixths

    /// Corner positions (top-left, top-right, bottom-left, bottom-right)
    case corners

    // MARK: Size & Position Categories
    /// Maximize and almost-maximize actions
    case max

    /// Resize actions (larger, smaller, etc.)
    case size

    /// Move window to screen edge without resizing
    case move

    /// Move window between displays/monitors
    case display

    /// Actions that don't fit other categories
    case other

    // MARK: - Properties

    /// The localized name shown in the UI (menus, settings).
    /// Uses NSLocalizedString to support multiple languages.
    var displayName: String {
        switch self {
        case .halves:
            return NSLocalizedString("Halves", tableName: "Main", value: "", comment: "")
        case .corners:
            return NSLocalizedString("Corners", tableName: "Main", value: "", comment: "")
        case .thirds:
            return NSLocalizedString("Thirds", tableName: "Main", value: "", comment: "")
        case .max:
            return NSLocalizedString("Maximize", tableName: "Main", value: "", comment: "")
        case .size:
            return NSLocalizedString("Size", tableName: "Main", value: "", comment: "")
        case .display:
            return NSLocalizedString("Display", tableName: "Main", value: "", comment: "")
        case .other:
            return NSLocalizedString("Other", tableName: "Main", value: "", comment: "")
        case .move:
            return NSLocalizedString("Move to Edge", tableName: "Main", value: "", comment: "")
        case .fourths:
            return NSLocalizedString("Fourths", tableName: "Main", value: "", comment: "")
        case .sixths:
            return NSLocalizedString("Sixths", tableName: "Main", value: "", comment: "")
        }
    }
}
