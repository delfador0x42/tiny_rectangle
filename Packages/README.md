# Swift Packages for tiny_window_manager

This directory contains modular Swift packages that provide core functionality and UI components for the window manager.

## Packages

### WindowManagerCore

Pure Swift package containing window calculation logic and geometry utilities. **No AppKit/Cocoa dependencies** - only CoreGraphics.

**Contents:**
- **Protocols:** `WindowProtocol`, `ScreenProtocol`, `SettingsProtocol`
- **Models:** `WindowActionType`, `ActionRecord`, `SubActionType`, `Edge`, `Dimension`, `Directional`
- **Calculators:**
  - `RectCalculator` - Pure window position calculations
  - `GapCalculator` - Gap/padding calculations
  - `CycleCalculator` - Action cycling logic
  - `SnapAreaCalculator` - Snap zone detection
- **Geometry:** CGRect, CGPoint, CGSize extensions

### WindowManagerUI

SwiftUI views for the preferences and welcome screens.

**Contents:**
- **Views:**
  - `ShortcutsView` - Configure keyboard shortcuts
  - `GeneralSettingsView` - Configure app settings
  - `WelcomeView` - First-time user setup
- **Components:**
  - `TilePreview` - Visual preview of window positions
- **View Models:**
  - `ShortcutViewModelProtocol` - Protocol for shortcut data
  - `SettingsViewModelProtocol` - Protocol for settings data

## Integration (Completed)

The following adapter files have been created to bridge the app to the packages:

### Adapters/CoreSettingsAdapter.swift
Implements `SettingsProtocol` wrapping the app's `Defaults`:
```swift
import WindowManagerCore

struct CoreSettingsAdapter: SettingsProtocol {
    var gapSize: CGFloat { CGFloat(Defaults.gapSize.value) }
    var sizeOffset: CGFloat { ... }
    // All settings from Defaults are wrapped
}
```

### Adapters/ShortcutViewModelAdapter.swift
Implements `ShortcutViewModelProtocol` wrapping `WindowAction`:
```swift
import WindowManagerUI

class ShortcutViewModelAdapter: ShortcutViewModelProtocol {
    var allShortcuts: [ShortcutItem] { ... }
    func shortcutRecorderView(for item: ShortcutItem) -> AnyView { ... }
}
```

### Adapters/SettingsViewModelAdapter.swift
Implements `SettingsViewModelProtocol` for the GeneralSettingsView:
```swift
import WindowManagerUI

class SettingsViewModelAdapter: SettingsViewModelProtocol {
    @Published var launchOnLogin: Bool
    @Published var gapSize: Float
    // All settings with two-way binding to Defaults
}
```

## Key Changes to App Code

### WindowCalculation.swift
Now delegates to the package's `RectCalculator`:
```swift
import WindowManagerCore

extension WindowAction {
    func calculateRect(in screen: CGRect, window: CGRect? = nil) -> CGRect? {
        guard let actionType = WindowActionType(rawValue: self.rawValue) else {
            return nil
        }
        return RectCalculator.calculateRect(
            for: actionType,
            in: screen,
            window: window,
            settings: CoreSettingsAdapter.shared
        )
    }
}
```

### GapCalculation
Now delegates to `GapCalculator`:
```swift
class GapCalculation {
    static func applyGaps(_ rect: CGRect, ...) -> CGRect {
        return GapCalculator.applyGaps(to: rect, ...)
    }
}
```

## Benefits

1. **Testability**: Core calculation logic can be tested without AppKit
2. **Modularity**: UI components are reusable and independent
3. **Protocol-based**: Easy to mock for testing
4. **Type safety**: All window actions are type-safe enums

## Running Tests

```bash
cd Packages/WindowManagerCore
swift test
```

All 13 RectCalculator tests pass, verifying the calculation logic.
