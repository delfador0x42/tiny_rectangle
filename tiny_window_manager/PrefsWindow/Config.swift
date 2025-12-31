//
//  Config.swift
//  tiny_window_manager
//
//  This file handles exporting and importing user configuration (settings & shortcuts).
//  Users can save their preferences to a JSON file and restore them later.
//

import Foundation
import MASShortcut

// MARK: - Defaults Extension for Config Import/Export

extension Defaults {

    // MARK: Exporting Configuration

    /// Converts all current user settings and shortcuts into a JSON string.
    /// This allows users to backup or share their configuration.
    ///
    /// - Returns: A JSON string containing all settings, or nil if encoding fails
    static func encoded() -> String? {
        print(#function, "called")
        // Get the app version to include in the config file
        guard let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return nil
        }

        // Collect all keyboard shortcuts into a dictionary
        let shortcuts = collectAllShortcuts()

        // Collect all user preferences/defaults into a dictionary
        let codableDefaults = collectAllDefaults()

        // Bundle everything into a Config object
        let config = Config(
            bundleId: "com.knollsoft.tiny_window_manager",
            version: version,
            shortcuts: shortcuts,
            defaults: codableDefaults
        )

        // Convert the Config to a nicely formatted JSON string
        return encodeConfigToJSON(config)
    }

    /// Gathers all keyboard shortcuts from both window actions and todo manager.
    private static func collectAllShortcuts() -> [String: Shortcut] {
        print(#function, "called")
        var shortcuts = [String: Shortcut]()

        // Collect shortcuts for window actions (resize, move, etc.)
        for action in WindowAction.active {
            if let masShortcut = MASShortcutBinder.shared()?.value(forKey: action.name) as? MASShortcut {
                shortcuts[action.name] = Shortcut(masShortcut: masShortcut)
            }
        }

        // Collect shortcuts for todo manager actions
        for defaultsKey in TodoManager.defaultsKeys {
            if let shortcut = loadShortcutFromUserDefaults(key: defaultsKey) {
                shortcuts[defaultsKey] = Shortcut(masShortcut: shortcut)
            }
        }

        return shortcuts
    }

    /// Loads a keyboard shortcut from UserDefaults using the MASShortcut transformer.
    private static func loadShortcutFromUserDefaults(key: String) -> MASShortcut? {
        print(#function, "called")
        // Shortcuts are stored as dictionaries in UserDefaults
        guard let shortcutDict = UserDefaults.standard.dictionary(forKey: key) else {
            return nil
        }

        // We need a transformer to convert the dictionary back to a MASShortcut object
        guard let dictTransformer = ValueTransformer(forName: NSValueTransformerName(rawValue: MASDictionaryTransformerName)) else {
            return nil
        }

        return dictTransformer.transformedValue(shortcutDict) as? MASShortcut
    }

    /// Gathers all user preferences into a codable format.
    private static func collectAllDefaults() -> [String: CodableDefault] {
        print(#function, "called")
        var codableDefaults = [String: CodableDefault]()

        for exportableDefault in Defaults.array {
            codableDefaults[exportableDefault.key] = exportableDefault.toCodable()
        }

        return codableDefaults
    }

    /// Converts a Config object to a formatted JSON string.
    private static func encodeConfigToJSON(_ config: Config) -> String? {
        print(#function, "called")
        let encoder = JSONEncoder()

        // Make the JSON human-readable with indentation
        encoder.outputFormatting = .prettyPrinted

        // Sort keys alphabetically for consistent output (macOS 10.13+)
        if #available(macOS 10.13, *) {
            encoder.outputFormatting.update(with: .sortedKeys)
        }

        // Try to encode and convert to string
        guard let encodedJson = try? encoder.encode(config) else {
            return nil
        }

        return String(data: encodedJson, encoding: .utf8)
    }

    // MARK: Importing Configuration

    /// Parses a JSON string into a Config object.
    ///
    /// - Parameter jsonString: The JSON string to parse
    /// - Returns: A Config object if parsing succeeds, nil otherwise
    static func convert(jsonString: String) -> Config? {
        print(#function, "called")
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(Config.self, from: jsonData)
    }

    /// Loads configuration from a JSON file and applies it to the app.
    /// This restores all user settings and keyboard shortcuts.
    ///
    /// - Parameter fileUrl: The URL of the JSON configuration file
    static func load(fileUrl: URL) {
        print(#function, "called")
        // We need the transformer to save shortcuts back to UserDefaults
        guard let dictTransformer = ValueTransformer(forName: NSValueTransformerName(rawValue: MASDictionaryTransformerName)) else {
            return
        }

        // Read and parse the JSON file
        guard let jsonString = try? String(contentsOf: fileUrl, encoding: .utf8),
              let config = convert(jsonString: jsonString) else {
            return
        }

        // Restore all user preferences
        restoreDefaults(from: config)

        // Restore all keyboard shortcuts
        restoreShortcuts(from: config, using: dictTransformer)

        // Notify the rest of the app that config was imported
        Notification.Name.configImported.post()
    }

    /// Restores user preferences from a config object.
    private static func restoreDefaults(from config: Config) {
        print(#function, "called")
        for availableDefault in Defaults.array {
            if let codedDefault = config.defaults[availableDefault.key] {
                availableDefault.load(from: codedDefault)
            }
        }
    }

    /// Restores keyboard shortcuts from a config object.
    private static func restoreShortcuts(from config: Config, using transformer: ValueTransformer) {
        print(#function, "called")
        // Restore window action shortcuts
        for action in WindowAction.active {
            if let shortcut = config.shortcuts[action.name]?.toMASSHortcut() {
                let dictValue = transformer.reverseTransformedValue(shortcut)
                UserDefaults.standard.setValue(dictValue, forKey: action.name)
            }
        }

        // Restore todo manager shortcuts
        for defaultsKey in TodoManager.defaultsKeys {
            if let shortcut = config.shortcuts[defaultsKey]?.toMASSHortcut() {
                let dictValue = transformer.reverseTransformedValue(shortcut)
                UserDefaults.standard.setValue(dictValue, forKey: defaultsKey)
            }
        }
    }

    // MARK: Auto-Loading from Support Directory

    /// Checks for a config file in the Application Support directory and loads it.
    /// After loading, the file is renamed with a timestamp (or deleted if rename fails).
    /// This allows external tools to drop a config file for automatic import.
    static func loadFromSupportDir() {
        print(#function, "called")
        // Build the path to the config file
        guard let supportURL = getSupportDir() else { return }
        let appSupportURL = supportURL.appendingPathComponent("tiny_window_manager", isDirectory: true)
        let configURL = appSupportURL.appendingPathComponent("tiny_window_managerConfig.json")

        // Check if the config file exists
        let fileExists = (try? configURL.checkResourceIsReachable()) == true
        guard fileExists else { return }

        // Load the configuration
        load(fileUrl: configURL)

        // After loading, archive the file so it doesn't get loaded again
        archiveConfigFile(at: configURL, in: appSupportURL)
    }

    /// Renames or removes the config file after it's been loaded.
    private static func archiveConfigFile(at configURL: URL, in directory: URL) {
        print(#function, "called")
        // Try to rename the file with a timestamp
        let newFilename = "tiny_window_managerConfig\(timestamp()).json"
        let archivedURL = directory.appendingPathComponent(newFilename)

        do {
            try FileManager.default.moveItem(atPath: configURL.path, toPath: archivedURL.path)
        } catch {
            // If rename fails, try to delete the file instead
            do {
                try FileManager.default.removeItem(at: configURL)
            } catch {
                // If both fail, alert the user
                AlertUtil.oneButtonAlert(
                    question: "Error after loading from Support Dir",
                    text: "Unable to rename/remove tiny_window_managerConfig.json from \(directory) after loading."
                )
            }
        }
    }

    // MARK: Helper Functions

    /// Returns the Application Support directory for the current user.
    private static func getSupportDir() -> URL? {
        print(#function, "called")
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths.first
    }

    /// Generates a timestamp string for creating unique filenames.
    /// Format: "2024-01-15_14-30-45-1234"
    private static func timestamp() -> String {
        print(#function, "called")
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd_H-mm-ss-SSSS"
        return formatter.string(from: Date())
    }
}

// MARK: - Config Data Structure

/// Represents the full configuration that can be exported/imported.
/// This is what gets saved to and loaded from JSON files.
struct Config: Codable {
    /// The app's bundle identifier (for validation when importing)
    let bundleId: String

    /// The app version that created this config
    let version: String

    /// All keyboard shortcuts, keyed by action name
    let shortcuts: [String: Shortcut]

    /// All user preferences, keyed by setting name
    let defaults: [String: CodableDefault]
}
