//  WelcomeView.swift - Welcome screen for first-time users
//
//  SwiftUI view displayed on first launch to let users choose
//  their preferred shortcut configuration.

import SwiftUI

// MARK: - WelcomeView

/// Welcome screen for first-time users.
///
/// Allows users to choose between recommended shortcuts or
/// custom configuration.
public struct WelcomeView: View {
    /// Callback when user makes a choice
    public var onChoice: (Bool) -> Void

    public init(onChoice: @escaping (Bool) -> Void) {
        self.onChoice = onChoice
    }

    public var body: some View {
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
                // Recommended option
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

                // Custom option
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

// MARK: - Preview

#Preview {
    WelcomeView(onChoice: { recommended in
        print("User chose: \(recommended ? "Recommended" : "Custom")")
    })
}
