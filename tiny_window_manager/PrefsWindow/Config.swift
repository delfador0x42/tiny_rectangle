//
//  Config.swift
//  tiny_window_manager
//
//  This file handles exporting and importing user configuration (settings & shortcuts).
//  Users can save their preferences to a JSON file and restore them later.
//

import Foundation
import KeyboardShortcuts

// MARK: - Defaults Extension for Config Import/Export

extension Defaults {

    // MARK: Exporting Configuration

    /// Converts all current user settings and shortcuts into a JSON string.
    static func encoded() -> String? {
        print(#function, "called")
        guard let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return nil
        }

        let shortcuts = collectAllShortcuts()
        let codableDefaults = collectAllDefaults()

        let config = Config(
            bundleId: "com.wudan.tiny-window-manager",
            version: version,
            shortcuts: shortcuts,
            defaults: codableDefaults
        )

        return encodeConfigToJSON(config)
    }

    /// Gathers all keyboard shortcuts from window actions.
    private static func collectAllShortcuts() -> [String: Shortcut] {
        print(#function, "called")
        var shortcuts = [String: Shortcut]()

        for action in WindowAction.active {
            if let ksShortcut = KeyboardShortcuts.getShortcut(for: .init(action)) {
                shortcuts[action.name] = Shortcut(
                    UInt(ksShortcut.modifiers.rawValue),
                    Int(ksShortcut.key?.rawValue ?? 0)
                )
            }
        }

        return shortcuts
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
        encoder.outputFormatting = .prettyPrinted

        if #available(macOS 10.13, *) {
            encoder.outputFormatting.update(with: .sortedKeys)
        }

        guard let encodedJson = try? encoder.encode(config) else {
            return nil
        }

        return String(data: encodedJson, encoding: .utf8)
    }

    // MARK: Importing Configuration

    /// Parses a JSON string into a Config object.
    static func convert(jsonString: String) -> Config? {
        print(#function, "called")
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(Config.self, from: jsonData)
    }

    /// Loads configuration from a JSON file and applies it to the app.
    static func load(fileUrl: URL) {
        print(#function, "called")
        guard let jsonString = try? String(contentsOf: fileUrl, encoding: .utf8),
              let config = convert(jsonString: jsonString) else {
            return
        }

        restoreDefaults(from: config)
        restoreShortcuts(from: config)
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
    private static func restoreShortcuts(from config: Config) {
        print(#function, "called")
        for action in WindowAction.active {
            if let shortcut = config.shortcuts[action.name] {
                // KeyboardShortcuts.Key uses Int for rawValue (non-optional init)
                let key = KeyboardShortcuts.Key(rawValue: shortcut.keyCode)
                let modifiers = NSEvent.ModifierFlags(rawValue: shortcut.modifierFlags)
                // KeyboardShortcuts.Shortcut takes NSEvent.ModifierFlags directly
                KeyboardShortcuts.setShortcut(
                    .init(key, modifiers: modifiers),
                    for: .init(action)
                )
            }
        }
    }

    // MARK: Auto-Loading from Support Directory

    /// Checks for a config file in the Application Support directory and loads it.
    static func loadFromSupportDir() {
        print(#function, "called")
        guard let supportURL = getSupportDir() else { return }
        let appSupportURL = supportURL.appendingPathComponent("tiny_window_manager", isDirectory: true)
        let configURL = appSupportURL.appendingPathComponent("tiny_window_managerConfig.json")

        let fileExists = (try? configURL.checkResourceIsReachable()) == true
        guard fileExists else { return }

        load(fileUrl: configURL)
        archiveConfigFile(at: configURL, in: appSupportURL)
    }

    /// Renames or removes the config file after it's been loaded.
    private static func archiveConfigFile(at configURL: URL, in directory: URL) {
        print(#function, "called")
        let newFilename = "tiny_window_managerConfig\(timestamp()).json"
        let archivedURL = directory.appendingPathComponent(newFilename)

        do {
            try FileManager.default.moveItem(atPath: configURL.path, toPath: archivedURL.path)
        } catch {
            do {
                try FileManager.default.removeItem(at: configURL)
            } catch {
                AlertUtil.oneButtonAlert(
                    question: "Error after loading from Support Dir",
                    text: "Unable to rename/remove tiny_window_managerConfig.json from \(directory) after loading."
                )
            }
        }
    }

    // MARK: Helper Functions

    private static func getSupportDir() -> URL? {
        print(#function, "called")
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return paths.first
    }

    private static func timestamp() -> String {
        print(#function, "called")
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd_H-mm-ss-SSSS"
        return formatter.string(from: Date())
    }
}

// MARK: - Config Data Structure

struct Config: Codable {
    let bundleId: String
    let version: String
    let shortcuts: [String: Shortcut]
    let defaults: [String: CodableDefault]
}
