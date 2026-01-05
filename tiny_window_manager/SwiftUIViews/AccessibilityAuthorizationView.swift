//
//  AccessibilityAuthorizationView.swift
//  tiny_window_manager
//
//  SwiftUI view for requesting accessibility permissions.
//

import SwiftUI

/// SwiftUI view that prompts the user to grant accessibility permissions.
struct AccessibilityAuthorizationView: View {
    /// URL to open System Settings to the Accessibility section.
    private let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!

    var body: some View {
        VStack(spacing: 22) {
            Text("Authorize tiny_window_manager")
                .font(.title)

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 60, height: 60)

            Text("tiny_window_manager needs your permission to control your window positions.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Go to System Settings → Privacy & Security → Accessibility")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Open System Settings") {
                NSWorkspace.shared.open(accessibilitySettingsURL)
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)

            Text("Enable tiny_window_manager.app")
                .font(.body)
        }
        .padding(20)
        .frame(width: 350)
    }
}

/// Window controller that hosts the accessibility authorization SwiftUI view.
@MainActor
final class AccessibilityAuthorizationWindowController: NSWindowController {

    convenience init() {
        let hostingController = NSHostingController(rootView: AccessibilityAuthorizationView())

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Authorize tiny_window_manager"
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.center()

        self.init(window: window)

        // Override close button to quit the app (can't function without accessibility)
        if let closeButton = window.standardWindowButton(.closeButton) {
            closeButton.target = self
            closeButton.action = #selector(quitApp)
        }
    }

    @objc private func quitApp() {
        exit(1)
    }
}

#Preview {
    AccessibilityAuthorizationView()
}
