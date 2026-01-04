//  ShortcutsView.swift - Shortcut configuration view
//
//  SwiftUI view for displaying and configuring keyboard shortcuts
//  for window actions.

import SwiftUI
import WindowManagerCore

// MARK: - ShortcutsView

/// Displays and allows configuration of keyboard shortcuts.
public struct ShortcutsView<ViewModel: ShortcutViewModelProtocol>: View {
    @ObservedObject var viewModel: ViewModel
    @State private var showMore = false

    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    private var displayedShortcuts: [ShortcutItem] {
        showMore ? viewModel.allShortcuts : viewModel.mainShortcuts
    }

    private var leftColumnShortcuts: [ShortcutItem] {
        let half = (displayedShortcuts.count + 1) / 2
        return Array(displayedShortcuts.prefix(half))
    }

    private var rightColumnShortcuts: [ShortcutItem] {
        let half = (displayedShortcuts.count + 1) / 2
        return Array(displayedShortcuts.suffix(displayedShortcuts.count - half))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 40) {
                    // Left Column
                    VStack(spacing: 10) {
                        ForEach(leftColumnShortcuts) { item in
                            ShortcutRow(item: item, viewModel: viewModel)
                        }
                    }

                    // Right Column
                    VStack(spacing: 10) {
                        ForEach(rightColumnShortcuts) { item in
                            ShortcutRow(item: item, viewModel: viewModel, alignRight: true)
                        }
                    }
                }

                // Show More / Show Less button
                if !viewModel.additionalShortcuts.isEmpty {
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
            }
            .padding(30)
        }
    }
}

// MARK: - ShortcutRow

struct ShortcutRow<ViewModel: ShortcutViewModelProtocol>: View {
    let item: ShortcutItem
    let viewModel: ViewModel
    var alignRight: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if alignRight {
                Spacer()
            }

            Text(item.displayName.camelCaseToWords)
                .frame(width: 120, alignment: .trailing)
                .font(.system(size: 12))

            TilePreview(action: item.actionType)
                .frame(width: 28, height: 22)

            viewModel.shortcutRecorderView(for: item)
                .frame(width: 120, height: 19)

            if !alignRight {
                Spacer()
            }
        }
    }
}

// MARK: - String Extension

extension String {
    /// Converts camelCase to "Title Case Words"
    var camelCaseToWords: String {
        let pattern = "([a-z])([A-Z])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return self
        }
        let range = NSRange(startIndex..., in: self)
        let result = regex.stringByReplacingMatches(in: self, range: range, withTemplate: "$1 $2")
        return result.prefix(1).uppercased() + result.dropFirst()
    }
}

// MARK: - Preview

#Preview {
    ShortcutsView(viewModel: PreviewShortcutViewModel())
        .frame(width: 700, height: 500)
}
