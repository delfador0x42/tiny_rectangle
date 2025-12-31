//
//  PreferencesView.swift
//  tiny_window_manager
//
//  SwiftUI-based preferences window replacing the storyboard UI.
//

import SwiftUI

// MARK: - Data Models

enum TilePosition: String, CaseIterable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case centerHalf = "Center Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
    case maximize = "Maximize"
    case almostMaximize = "Almost Maximize"
    case maximizeHeight = "Maximize Height"
    case makeSmaller = "Make Smaller"
    case makeLarger = "Make Larger"
    case center = "Center"
    case restore = "Restore"
    case nextDisplay = "Next Display"
    case previousDisplay = "Previous Display"
}

struct ShortcutItem: Identifiable {
    let id = UUID()
    let position: TilePosition
    var shortcut: String?

    var displayName: String {
        position.rawValue
    }
}

// MARK: - Main Preferences View

struct PreferencesView: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            PreferencesTabBarView(selectedTab: $selectedTab)
                .padding(.top, 8)

            Divider()
                .padding(.top, 8)

            // Tab Content
            TabView(selection: $selectedTab) {
                ShortcutsView()
                    .tag(0)

                SnapAreasView()
                    .tag(1)

                GeneralSettingsView()
                    .tag(2)
            }
            .tabViewStyle(.automatic)
        }
        .frame(minWidth: 750, minHeight: 550)
    }
}

// MARK: - Tab Bar

struct PreferencesTabBarView: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 24) {
            PreferencesTabButton(
                icon: "command.square",
                title: "Shortcuts",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            PreferencesTabButton(
                icon: "cursorarrow.click.2",
                title: "Snap Areas",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }

            PreferencesTabButton(
                icon: "gearshape",
                title: "General",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
    }
}

struct PreferencesTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 11))
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shortcuts View

struct ShortcutsView: View {
    @State private var shortcuts: [ShortcutItem] = [
        ShortcutItem(position: .leftHalf, shortcut: "^/"),
        ShortcutItem(position: .rightHalf, shortcut: "^\\"),
        ShortcutItem(position: .centerHalf, shortcut: nil),
        ShortcutItem(position: .topHalf, shortcut: "^⌥↑"),
        ShortcutItem(position: .bottomHalf, shortcut: "^⌥↓"),
        ShortcutItem(position: .topLeft, shortcut: "^⌥U"),
        ShortcutItem(position: .topRight, shortcut: "^⌥I"),
        ShortcutItem(position: .bottomLeft, shortcut: "^⌥J"),
        ShortcutItem(position: .bottomRight, shortcut: "^⌥K"),
        ShortcutItem(position: .maximize, shortcut: "^G"),
        ShortcutItem(position: .almostMaximize, shortcut: nil),
        ShortcutItem(position: .maximizeHeight, shortcut: "^⌥⇧↑"),
        ShortcutItem(position: .makeSmaller, shortcut: "^⌥-"),
        ShortcutItem(position: .makeLarger, shortcut: "^⌥="),
        ShortcutItem(position: .center, shortcut: "^⌥C"),
        ShortcutItem(position: .restore, shortcut: "^⌥⌫"),
        ShortcutItem(position: .nextDisplay, shortcut: "^⌥⌘→"),
        ShortcutItem(position: .previousDisplay, shortcut: "^⌥⌘←"),
    ]

    var leftColumnItems: [ShortcutItem] {
        Array(shortcuts.prefix(9))
    }

    var rightColumnItems: [ShortcutItem] {
        Array(shortcuts.suffix(9))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            // Left Column
            VStack(spacing: 12) {
                ForEach(leftColumnItems) { item in
                    ShortcutRow(item: item) { newShortcut in
                        updateShortcut(for: item.id, shortcut: newShortcut)
                    }
                }
            }

            // Right Column
            VStack(spacing: 12) {
                ForEach(rightColumnItems) { item in
                    ShortcutRow(item: item, alignRight: true) { newShortcut in
                        updateShortcut(for: item.id, shortcut: newShortcut)
                    }
                }
            }
        }
        .padding(30)
    }

    private func updateShortcut(for id: UUID, shortcut: String?) {
        if let index = shortcuts.firstIndex(where: { $0.id == id }) {
            shortcuts[index].shortcut = shortcut
        }
    }
}

// MARK: - Shortcut Row

struct ShortcutRow: View {
    let item: ShortcutItem
    var alignRight: Bool = false
    let onShortcutChange: (String?) -> Void

    var body: some View {
        HStack(spacing: 8) {
            if alignRight {
                Spacer()
            }

            Text(item.displayName)
                .frame(width: 110, alignment: alignRight ? .trailing : .trailing)
                .font(.system(size: 13))

            TilePreview(position: item.position)
                .frame(width: 28, height: 22)

            ShortcutButton(shortcut: item.shortcut)
                .frame(width: 140)

            Button(action: {
                onShortcutChange(nil)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(item.shortcut != nil ? 1 : 0.3)

            if !alignRight {
                Spacer()
            }
        }
    }
}

// MARK: - Tile Preview

struct TilePreview: View {
    let position: TilePosition

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (inactive area)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))

                // Active area
                activeArea(in: geometry.size)
                    .fill(Color.gray.opacity(0.7))
            }
        }
    }

    private func activeArea(in size: CGSize) -> Path {
        let w = size.width
        let h = size.height

        let rect: CGRect
        switch position {
        case .leftHalf:
            rect = CGRect(x: 0, y: 0, width: w/2, height: h)
        case .rightHalf:
            rect = CGRect(x: w/2, y: 0, width: w/2, height: h)
        case .centerHalf:
            rect = CGRect(x: w/4, y: 0, width: w/2, height: h)
        case .topHalf:
            rect = CGRect(x: 0, y: 0, width: w, height: h/2)
        case .bottomHalf:
            rect = CGRect(x: 0, y: h/2, width: w, height: h/2)
        case .topLeft:
            rect = CGRect(x: 0, y: 0, width: w/2, height: h/2)
        case .topRight:
            rect = CGRect(x: w/2, y: 0, width: w/2, height: h/2)
        case .bottomLeft:
            rect = CGRect(x: 0, y: h/2, width: w/2, height: h/2)
        case .bottomRight:
            rect = CGRect(x: w/2, y: h/2, width: w/2, height: h/2)
        case .maximize:
            rect = CGRect(x: 0, y: 0, width: w, height: h)
        case .almostMaximize:
            rect = CGRect(x: w*0.05, y: h*0.05, width: w*0.9, height: h*0.9)
        case .maximizeHeight:
            rect = CGRect(x: w/4, y: 0, width: w/2, height: h)
        case .makeSmaller:
            rect = CGRect(x: w*0.25, y: h*0.25, width: w*0.5, height: h*0.5)
        case .makeLarger:
            rect = CGRect(x: w*0.1, y: h*0.1, width: w*0.8, height: h*0.8)
        case .center:
            rect = CGRect(x: w*0.2, y: h*0.2, width: w*0.6, height: h*0.6)
        case .restore:
            rect = CGRect(x: w*0.15, y: h*0.15, width: w*0.7, height: h*0.7)
        case .nextDisplay:
            rect = CGRect(x: w*0.6, y: 0, width: w*0.4, height: h)
        case .previousDisplay:
            rect = CGRect(x: 0, y: 0, width: w*0.4, height: h)
        }

        return Path(rect)
    }
}

// MARK: - Shortcut Button

struct ShortcutButton: View {
    let shortcut: String?
    @State private var isRecording = false

    var body: some View {
        Button(action: {
            isRecording.toggle()
        }) {
            Text(isRecording ? "Recording..." : (shortcut ?? "Record Shortcut"))
                .font(.system(size: 12))
                .foregroundColor(shortcut != nil ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Snap Areas View

struct SnapAreasView: View {
    var body: some View {
        VStack {
            Text("Snap Areas")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Configure snap areas for window management")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    var body: some View {
        VStack {
            Text("General Settings")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Configure general application settings")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    PreferencesView()
}
