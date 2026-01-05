//
//  PreferencesView.swift
//  tiny_window_manager
//
//  SwiftUI-based preferences window replacing the storyboard UI.
//

import SwiftUI

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
    /// Main shortcuts shown by default
    private let mainActions: [WindowAction] = [
        .leftHalf, .rightHalf, .centerHalf, .topHalf, .bottomHalf,
        .topLeft, .topRight, .bottomLeft, .bottomRight,
        .maximize, .almostMaximize, .maximizeHeight,
        .larger, .smaller,
        .center, .restore,
        .nextDisplay, .previousDisplay
    ]

    /// Additional shortcuts shown when expanded
    private let additionalActions: [WindowAction] = [
        .firstThird, .centerThird, .lastThird,
        .firstTwoThirds, .centerTwoThirds, .lastTwoThirds,
        .moveLeft, .moveRight, .moveUp, .moveDown,
        .firstFourth, .secondFourth, .thirdFourth, .lastFourth,
        .firstThreeFourths, .centerThreeFourths, .lastThreeFourths,
        .topLeftSixth, .topCenterSixth, .topRightSixth,
        .bottomLeftSixth, .bottomCenterSixth, .bottomRightSixth
    ]

    @State private var showMore = false

    private var displayedActions: [WindowAction] {
        showMore ? mainActions + additionalActions : mainActions
    }

    private var leftColumnActions: [WindowAction] {
        let half = (displayedActions.count + 1) / 2
        return Array(displayedActions.prefix(half))
    }

    private var rightColumnActions: [WindowAction] {
        let half = (displayedActions.count + 1) / 2
        return Array(displayedActions.suffix(displayedActions.count - half))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 40) {
                    // Left Column
                    VStack(spacing: 10) {
                        ForEach(leftColumnActions, id: \.self) { action in
                            ShortcutRow(action: action)
                        }
                    }

                    // Right Column
                    VStack(spacing: 10) {
                        ForEach(rightColumnActions, id: \.self) { action in
                            ShortcutRow(action: action, alignRight: true)
                        }
                    }
                }

                // Show More / Show Less button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showMore.toggle()
                    }
                }) {
                    HStack {
                        Text(showMore ? "Show Less" : "Show More")
                        Image(systemName: showMore ? "chevron.up" : "chevron.down")
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(30)
        }
    }
}

// MARK: - Shortcut Row

struct ShortcutRow: View {
    let action: WindowAction
    var alignRight: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if alignRight {
                Spacer()
            }

            Text(action.displayName ?? action.name.camelCaseToWords)
                .frame(width: 120, alignment: .trailing)
                .font(.system(size: 12))

            TilePreview(action: action)
                .frame(width: 28, height: 22)

            MASShortcutRecorder(action: action)
                .frame(width: 120, height: 19)

            if !alignRight {
                Spacer()
            }
        }
    }
}

// MARK: - Tile Preview

struct TilePreview: View {
    let action: WindowAction

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
        switch action {
        // Halves
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

        // Corners
        case .topLeft:
            rect = CGRect(x: 0, y: 0, width: w/2, height: h/2)
        case .topRight:
            rect = CGRect(x: w/2, y: 0, width: w/2, height: h/2)
        case .bottomLeft:
            rect = CGRect(x: 0, y: h/2, width: w/2, height: h/2)
        case .bottomRight:
            rect = CGRect(x: w/2, y: h/2, width: w/2, height: h/2)

        // Maximize variants
        case .maximize:
            rect = CGRect(x: 0, y: 0, width: w, height: h)
        case .almostMaximize:
            rect = CGRect(x: w*0.05, y: h*0.05, width: w*0.9, height: h*0.9)
        case .maximizeHeight:
            rect = CGRect(x: w/4, y: 0, width: w/2, height: h)

        // Size changes
        case .larger:
            rect = CGRect(x: w*0.1, y: h*0.1, width: w*0.8, height: h*0.8)
        case .smaller:
            rect = CGRect(x: w*0.25, y: h*0.25, width: w*0.5, height: h*0.5)

        // Center and restore
        case .center, .centerProminently:
            rect = CGRect(x: w*0.2, y: h*0.2, width: w*0.6, height: h*0.6)
        case .restore:
            rect = CGRect(x: w*0.15, y: h*0.15, width: w*0.7, height: h*0.7)

        // Display navigation
        case .nextDisplay:
            rect = CGRect(x: w*0.6, y: 0, width: w*0.4, height: h)
        case .previousDisplay:
            rect = CGRect(x: 0, y: 0, width: w*0.4, height: h)

        // Thirds
        case .firstThird:
            rect = CGRect(x: 0, y: 0, width: w/3, height: h)
        case .centerThird:
            rect = CGRect(x: w/3, y: 0, width: w/3, height: h)
        case .lastThird:
            rect = CGRect(x: w*2/3, y: 0, width: w/3, height: h)
        case .firstTwoThirds:
            rect = CGRect(x: 0, y: 0, width: w*2/3, height: h)
        case .centerTwoThirds:
            rect = CGRect(x: w/6, y: 0, width: w*2/3, height: h)
        case .lastTwoThirds:
            rect = CGRect(x: w/3, y: 0, width: w*2/3, height: h)

        // Movement
        case .moveLeft:
            rect = CGRect(x: 0, y: h*0.2, width: w*0.4, height: h*0.6)
        case .moveRight:
            rect = CGRect(x: w*0.6, y: h*0.2, width: w*0.4, height: h*0.6)
        case .moveUp:
            rect = CGRect(x: w*0.2, y: 0, width: w*0.6, height: h*0.4)
        case .moveDown:
            rect = CGRect(x: w*0.2, y: h*0.6, width: w*0.6, height: h*0.4)

        // Fourths
        case .firstFourth:
            rect = CGRect(x: 0, y: 0, width: w/4, height: h)
        case .secondFourth:
            rect = CGRect(x: w/4, y: 0, width: w/4, height: h)
        case .thirdFourth:
            rect = CGRect(x: w/2, y: 0, width: w/4, height: h)
        case .lastFourth:
            rect = CGRect(x: w*3/4, y: 0, width: w/4, height: h)
        case .firstThreeFourths:
            rect = CGRect(x: 0, y: 0, width: w*3/4, height: h)
        case .centerThreeFourths:
            rect = CGRect(x: w/8, y: 0, width: w*3/4, height: h)
        case .lastThreeFourths:
            rect = CGRect(x: w/4, y: 0, width: w*3/4, height: h)

        // Sixths
        case .topLeftSixth:
            rect = CGRect(x: 0, y: 0, width: w/3, height: h/2)
        case .topCenterSixth:
            rect = CGRect(x: w/3, y: 0, width: w/3, height: h/2)
        case .topRightSixth:
            rect = CGRect(x: w*2/3, y: 0, width: w/3, height: h/2)
        case .bottomLeftSixth:
            rect = CGRect(x: 0, y: h/2, width: w/3, height: h/2)
        case .bottomCenterSixth:
            rect = CGRect(x: w/3, y: h/2, width: w/3, height: h/2)
        case .bottomRightSixth:
            rect = CGRect(x: w*2/3, y: h/2, width: w/3, height: h/2)

        // Default fallback for any other action
        default:
            rect = CGRect(x: w*0.2, y: h*0.2, width: w*0.6, height: h*0.6)
        }

        return Path(rect)
    }
}

// MARK: - Snap Areas View

struct SnapAreasView: View {
    @State private var windowSnapping: Bool = !(Defaults.windowSnapping.userDisabled)
    @State private var unsnapRestore: Bool = !(Defaults.unsnapRestore.userDisabled)
    @State private var animateFootprint: Bool = Defaults.footprintAnimationDurationMultiplier.value > 0
    @State private var hapticFeedback: Bool = Defaults.hapticFeedbackOnSnap.userEnabled
    @State private var missionControlDraggingDisabled: Bool = Defaults.missionControlDragging.userDisabled
    @State private var showPortrait: Bool = NSScreen.portraitDisplayConnected

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // General Settings Section
                snapSettingsSection

                Divider()

                // Landscape Snap Areas
                landscapeSection

                // Portrait Snap Areas (conditional)
                if showPortrait {
                    Divider()
                    portraitSection
                }
            }
            .padding(30)
        }
        .onAppear {
            refreshSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            showPortrait = NSScreen.portraitDisplayConnected
        }
        .onReceive(NotificationCenter.default.publisher(for: .configImported)) { _ in
            refreshSettings()
        }
    }

    private func refreshSettings() {
        windowSnapping = !(Defaults.windowSnapping.userDisabled)
        unsnapRestore = !(Defaults.unsnapRestore.userDisabled)
        animateFootprint = Defaults.footprintAnimationDurationMultiplier.value > 0
        hapticFeedback = Defaults.hapticFeedbackOnSnap.userEnabled
        missionControlDraggingDisabled = Defaults.missionControlDragging.userDisabled
        showPortrait = NSScreen.portraitDisplayConnected
    }

    // MARK: - Settings Section

    private var snapSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Snap Settings")
                .font(.headline)

            Toggle("Enable window snapping", isOn: $windowSnapping)
                .onChange(of: windowSnapping) { _, newValue in
                    Defaults.windowSnapping.enabled = newValue
                    Notification.Name.windowSnapping.post(object: newValue)
                    if newValue {
                        MacTilingDefaults.checkForBuiltInTiling(skipIfAlreadyNotified: false)
                    }
                }

            Toggle("Restore window size when unsnapped", isOn: $unsnapRestore)
                .onChange(of: unsnapRestore) { _, newValue in
                    Defaults.unsnapRestore.enabled = newValue
                }

            Toggle("Animate snap preview", isOn: $animateFootprint)
                .onChange(of: animateFootprint) { _, newValue in
                    Defaults.footprintAnimationDurationMultiplier.value = newValue ? 0.75 : 0
                }

            Toggle("Haptic feedback on snap", isOn: $hapticFeedback)
                .onChange(of: hapticFeedback) { _, newValue in
                    Defaults.hapticFeedbackOnSnap.enabled = newValue
                }

            if missionControlDraggingDisabled {
                Toggle("Disable Mission Control dragging", isOn: $missionControlDraggingDisabled)
                    .onChange(of: missionControlDraggingDisabled) { _, newValue in
                        Defaults.missionControlDragging.enabled = !newValue
                        Notification.Name.missionControlDragging.post(object: !newValue)
                    }
            }
        }
    }

    // MARK: - Landscape Section

    private var landscapeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Landscape Snap Areas")
                .font(.headline)

            SnapAreaGrid(orientation: .landscape)
        }
    }

    // MARK: - Portrait Section

    private var portraitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Portrait Snap Areas")
                .font(.headline)

            SnapAreaGrid(orientation: .portrait)
        }
    }
}

// MARK: - Snap Area Grid

struct SnapAreaGrid: View {
    let orientation: DisplayOrientation

    var body: some View {
        VStack(spacing: 8) {
            // Top row: TL, T, TR
            HStack(spacing: 8) {
                SnapAreaDropdown(directional: .tl, orientation: orientation)
                SnapAreaDropdown(directional: .t, orientation: orientation)
                SnapAreaDropdown(directional: .tr, orientation: orientation)
            }

            // Middle row: L, (screen preview), R
            HStack(spacing: 8) {
                SnapAreaDropdown(directional: .l, orientation: orientation)

                // Screen preview
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 60)
                    .overlay(
                        Text(orientation == .landscape ? "⬜" : "▯")
                            .font(.title)
                            .foregroundColor(.secondary)
                    )

                SnapAreaDropdown(directional: .r, orientation: orientation)
            }

            // Bottom row: BL, B, BR
            HStack(spacing: 8) {
                SnapAreaDropdown(directional: .bl, orientation: orientation)
                SnapAreaDropdown(directional: .b, orientation: orientation)
                SnapAreaDropdown(directional: .br, orientation: orientation)
            }
        }
    }
}

// MARK: - Snap Area Dropdown

struct SnapAreaDropdown: View {
    let directional: Directional
    let orientation: DisplayOrientation

    @State private var selectedTag: Int = -1

    private var currentConfig: SnapAreaConfig? {
        switch orientation {
        case .landscape:
            return SnapAreaModel.instance.landscape[directional]
        case .portrait:
            return SnapAreaModel.instance.portrait[directional]
        }
    }

    var body: some View {
        Menu {
            // No action option
            Button("-") {
                selectedTag = -1
                saveSelection(tag: -1)
            }

            Divider()

            // Compound snap areas
            ForEach(compatibleCompoundAreas, id: \.rawValue) { compound in
                Button(compound.displayName) {
                    selectedTag = compound.rawValue
                    saveSelection(tag: compound.rawValue)
                }
            }

            if !compatibleCompoundAreas.isEmpty {
                Divider()
            }

            // Window actions
            ForEach(dragSnappableActions, id: \.rawValue) { action in
                Button {
                    selectedTag = action.rawValue
                    saveSelection(tag: action.rawValue)
                } label: {
                    if let displayName = action.displayName {
                        Label(displayName, image: "")
                    }
                }
            }
        } label: {
            Text(currentSelectionTitle)
                .font(.system(size: 11))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
        .frame(minWidth: 140)
        .onAppear {
            loadCurrentSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .configImported)) { _ in
            loadCurrentSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .defaultSnapAreas)) { _ in
            loadCurrentSelection()
        }
    }

    private var currentSelectionTitle: String {
        if selectedTag < -1, let compound = CompoundSnapArea(rawValue: selectedTag) {
            return compound.displayName
        } else if selectedTag > -1, let action = WindowAction(rawValue: selectedTag) {
            return action.displayName ?? action.name.camelCaseToWords
        }
        return "-"
    }

    private var compatibleCompoundAreas: [CompoundSnapArea] {
        CompoundSnapArea.all.filter { compound in
            compound.compatibleOrientation.contains(orientation) &&
            compound.compatibleDirectionals.contains(directional)
        }
    }

    private var dragSnappableActions: [WindowAction] {
        WindowAction.active.filter { $0.isDragSnappable && $0.displayName != nil }
    }

    private func loadCurrentSelection() {
        selectedTag = currentConfig?.action?.rawValue ?? currentConfig?.compound?.rawValue ?? -1
    }

    private func saveSelection(tag: Int) {
        let config: SnapAreaConfig?
        if tag < -1, let compound = CompoundSnapArea(rawValue: tag) {
            config = SnapAreaConfig(compound: compound)
        } else if tag > -1, let action = WindowAction(rawValue: tag) {
            config = SnapAreaConfig(action: action)
        } else {
            config = nil
        }

        SnapAreaModel.instance.setConfig(
            type: orientation,
            directional: directional,
            snapAreaConfig: config
        )
    }
}

// MARK: - Preview

#Preview {
    PreferencesView()
}
