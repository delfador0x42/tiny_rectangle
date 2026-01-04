//  AppDelegate+URLScheme.swift - URL scheme handling for automation

import Cocoa

// MARK: - URL Scheme Handling

/// Handles custom URL schemes for automation.
///
/// The app supports URLs like:
/// - `tiny-window-manager://execute-action?name=left-half` - Execute a window action
/// - `tiny-window-manager://execute-task?name=ignore-app&app-bundle-id=com.example.app` - Ignore an app
/// - `tiny-window-manager://execute-task?name=unignore-app&app-bundle-id=com.example.app` - Unignore an app
extension AppDelegate {

    /// Handles URLs opened via our custom URL scheme.
    func application(_ application: NSApplication, open urls: [URL]) {
        // If we're now the frontmost app, switch back to the previous app
        // (URL handling shouldn't steal focus)
        if NSWorkspace.shared.frontmostApplication == NSRunningApplication.current {
            prevActiveApp?.activate()
        }

        // Process URLs asynchronously
        DispatchQueue.main.async {
            self.processURLs(urls)
        }
    }

    /// Processes an array of URLs from the URL scheme handler.
    private func processURLs(_ urls: [URL]) {
        for url in urls {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                  components.path.isEmpty else {
                continue
            }

            let name = components.queryItems?.first { $0.name == "name" }?.value

            switch (components.host, name) {
            case ("execute-action", _):
                // Execute a window action by name
                // URL format: tiny-window-manager://execute-action?name=left-half
                if let action = findWindowAction(byURLName: name) {
                    action.postUrl()
                }

            case ("execute-task", "ignore-app"):
                // Ignore an app
                // URL format: tiny-window-manager://execute-task?name=ignore-app&app-bundle-id=com.example.app
                if let bundleId = extractBundleIdParameter(from: components),
                   isValidBundleId(bundleId) {
                    self.applicationToggle.disableApp(appBundleId: bundleId)
                }

            case ("execute-task", "unignore-app"):
                // Unignore an app
                // URL format: tiny-window-manager://execute-task?name=unignore-app&app-bundle-id=com.example.app
                if let bundleId = extractBundleIdParameter(from: components),
                   isValidBundleId(bundleId) {
                    self.applicationToggle.enableApp(appBundleId: bundleId)
                }

            default:
                continue
            }
        }
    }

    /// Converts a window action name to URL format (camelCase to kebab-case).
    private func actionNameToURLName(_ name: String) -> String {
        return name.map { $0.isUppercase ? "-" + $0.lowercased() : String($0) }.joined()
    }

    /// Finds a window action by its URL-formatted name.
    private func findWindowAction(byURLName urlName: String?) -> WindowAction? {
        return WindowAction.active.first { actionNameToURLName($0.name) == urlName }
    }

    /// Extracts the bundle ID parameter from URL components.
    private func extractBundleIdParameter(from components: URLComponents) -> String? {
        let queryValue = components.queryItems?.first { $0.name == "app-bundle-id" }?.value
        return queryValue ?? ApplicationToggle.frontAppId
    }

    /// Validates that a bundle ID is not empty.
    private func isValidBundleId(_ bundleId: String?) -> Bool {
        let isValid = bundleId?.isEmpty != true
        if !isValid {
            Logger.log("Received an empty app-bundle-id parameter. Either pass a valid app bundle id or remove the parameter.")
        }
        return isValid
    }
}
