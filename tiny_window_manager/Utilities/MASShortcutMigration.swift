//
//  MASShortcutMigration.swift
//  tiny_window_manager
//
//  Migrates keyboard shortcuts from the old storage format to the new format.
//
//  BACKGROUND:
//  This app uses MASShortcut library for handling keyboard shortcuts.
//  In older versions, shortcuts were stored using NSKeyedArchiver (binary Data format).
//  Newer versions store shortcuts as dictionaries (easier to read/debug in UserDefaults).
//
//  This migration converts old-format shortcuts to the new format so users don't
//  lose their custom keyboard shortcuts when updating the app.
//
//  WHEN THIS RUNS:
//  This should be called once at app startup. It safely handles cases where:
//  - Shortcuts are already in the new format (no-op)
//  - No shortcuts exist yet (no-op)
//  - Shortcuts are in old format (migrates them)
//

import Foundation
import MASShortcut

// MARK: - MASShortcut Migration

/// Handles migration of keyboard shortcut data from old to new storage formats.
///
class MASShortcutMigration {

    /// Migrates all keyboard shortcuts from NSKeyedArchiver format to dictionary format.
    ///
    /// This is a one-time migration that converts shortcuts stored as binary Data
    /// to the newer dictionary-based format used by MASShortcut.
    ///
    /// Safe to call multiple times - it only migrates shortcuts that are still
    /// in the old format.
    ///
    static func migrate() {

        // STEP 1: Set up the transformers we'll need for format conversion
        //
        // ValueTransformers are objects that convert between different data representations.
        // We need two of them:

        // Transformer to convert binary Data → MASShortcut object
        // This is Apple's built-in secure unarchiver for NSKeyedArchiver data
        guard let dataToShortcutTransformer = ValueTransformer(
            forName: .secureUnarchiveFromDataTransformerName
        ) else {
            // If we can't get this transformer, we can't migrate - just return silently
            return
        }

        // Transformer to convert MASShortcut object → Dictionary
        // This is provided by the MASShortcut library
        guard let shortcutToDictTransformer = ValueTransformer(
            forName: NSValueTransformerName(rawValue: MASDictionaryTransformerName)
        ) else {
            // If we can't get this transformer, we can't migrate - just return silently
            return
        }

        // STEP 2: Iterate through all window actions and migrate their shortcuts
        //
        // Each window action (e.g., "maximize", "left-half") can have a keyboard shortcut.
        // The shortcut is stored in UserDefaults using the action's name as the key.

        for action in WindowAction.active {

            // Try to read the stored value as binary Data (old format)
            // If it's already a dictionary (new format), this will return nil
            let oldFormatData = UserDefaults.standard.data(forKey: action.name)

            // Only proceed if we found old-format data
            if let oldFormatData = oldFormatData {

                // Convert: binary Data → MASShortcut object
                let shortcutObject = dataToShortcutTransformer.transformedValue(oldFormatData)

                if let shortcutObject = shortcutObject {

                    // Convert: MASShortcut object → Dictionary (new format)
                    // Note: We use reverseTransformedValue because the transformer
                    // is designed to go Dict→Shortcut, so reverse goes Shortcut→Dict
                    let newFormatDict = shortcutToDictTransformer.reverseTransformedValue(shortcutObject)

                    // Save the shortcut in the new dictionary format
                    // This overwrites the old binary data with the new dictionary
                    UserDefaults.standard.setValue(newFormatDict, forKey: action.name)
                }
            }
        }
    }
}
