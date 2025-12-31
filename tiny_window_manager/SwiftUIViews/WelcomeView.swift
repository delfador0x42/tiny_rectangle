//
//  WelcomeView.swift
//  tiny_window_manager
//
//  SwiftUI welcome window for first-time users.
//

import SwiftUI

struct WelcomeView: View {
    /// Callback when user makes a choice
    var onChoice: (Bool) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to tiny_window_manager")
                .font(.title)
                .fontWeight(.semibold)

            Text("Choose how you'd like to set up your window management shortcuts:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                Button(action: {
                    onChoice(true)
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Recommended")
                                .fontWeight(.medium)
                        }
                        Text("Use the recommended shortcuts optimized for productivity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    onChoice(false)
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Custom")
                                .fontWeight(.medium)
                        }
                        Text("Configure your own shortcuts in preferences")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .padding(32)
        .frame(width: 400, height: 320)
    }
}

// MARK: - Window Controller Helper

/// Helper class to present the welcome view as a modal window
class SwiftUIWelcomeWindowController {
    private var window: NSWindow?
    private var hostingController: NSHostingController<WelcomeView>?

    /// Shows the welcome window modally and returns whether user chose recommended settings
    func showModal() -> Bool {
        var useRecommended = true

        let welcomeView = WelcomeView { recommended in
            useRecommended = recommended
            NSApp.stopModal(withCode: recommended ? .alertFirstButtonReturn : .alertSecondButtonReturn)
        }

        hostingController = NSHostingController(rootView: welcomeView)

        window = NSWindow(contentViewController: hostingController!)
        window?.title = "Welcome"
        window?.styleMask = [.titled, .closable]
        window?.center()

        NSApp.activate(ignoringOtherApps: true)
        NSApp.runModal(for: window!)

        window?.close()
        return useRecommended
    }
}

#Preview {
    WelcomeView(onChoice: { _ in })
}
