//
//  Defaults.swift
//  tiny_window_manager
//
//  Type-safe wrappers for UserDefaults with auto-save and import/export support.
//

import Cocoa
import SwiftUI
import WindowManagerCore

// MARK: - Defaults

/// Central registry of all user preferences. Access via `Defaults.settingName`.
class Defaults {

    // MARK: - General App Settings

    /// Whether to launch the app automatically when the user logs in.
    static let launchOnLogin = BoolDefault(key: "launchOnLogin")

    /// Whether to hide the menu bar icon (makes app run in background only).
    static let hideMenuBarIcon = BoolDefault(key: "hideMenubarIcon")

    /// Whether to open the settings menu when app is relaunched while already running.
    static let relaunchOpensMenu = BoolDefault(key: "relaunchOpensMenu")

    /// Whether to allow any keyboard shortcut (including system shortcuts).
    static let allowAnyShortcut = BoolDefault(key: "allowAnyShortcut")

    /// Use alternate default shortcuts (Magnet-style instead of Spectacle-style).
    static let alternateDefaultShortcuts = BoolDefault(key: "alternateDefaultShortcuts")

    /// Whether automatic update checks are enabled (Sparkle framework setting).
    static let SUEnableAutomaticChecks = BoolDefault(key: "SUEnableAutomaticChecks")

    /// Direct access to Sparkle's "has launched before" flag.
    static var SUHasLaunchedBefore: Bool {
        UserDefaults.standard.bool(forKey: "SUHasLaunchedBefore")
    }

    // MARK: - Version Tracking

    /// The last version of the app that was run (for migration/update detection).
    static let lastVersion = StringDefault(key: "lastVersion")

    /// The version of the app when it was first installed.
    static let installVersion = StringDefault(key: "installVersion")

    /// Whether user has been notified about internal macOS tiling conflicts.
    static let internalTilingNotified = BoolDefault(key: "internalTilingNotified")

    /// Whether user has been notified about problematic applications.
    static let notifiedOfProblemApps = BoolDefault(key: "notifiedOfProblemApps")

    // MARK: - App Filtering (Which Apps to Manage)

    /// Comma-separated list of app bundle IDs where window management is disabled.
    static let disabledApps = StringDefault(key: "disabledApps")

    /// Bundle IDs of apps to completely ignore (no shortcuts, no snapping, nothing).
    static let fullIgnoreBundleIds = JSONDefault<[String]>(key: "fullIgnoreBundleIds")

    // MARK: - Window Snapping (Drag-to-Edge)

    /// Whether window snapping is enabled (nil = not explicitly set by user).
    static let windowSnapping = OptionalBoolDefault(key: "windowSnapping")

    /// Whether to restore window to original size/position when dragging away from snap.
    static let unsnapRestore = OptionalBoolDefault(key: "unsnapRestore")

    /// Keyboard modifier keys required for snapping (e.g., hold Ctrl while dragging).
    static let snapModifiers = IntDefault(key: "snapModifiers")

    /// Whether to also ignore drag snapping for disabled apps.
    static let ignoreDragSnapToo = OptionalBoolDefault(key: "ignoreDragSnapToo")

    /// Whether to provide haptic feedback when snapping.
    static let hapticFeedbackOnSnap = OptionalBoolDefault(key: "hapticFeedbackOnSnap")

    // MARK: - Snap Area Geometry (Where Snap Zones Are)

    /// How far from screen edge (in pixels) the snap zones extend - Top edge.
    static let snapEdgeMarginTop = FloatDefault(key: "snapEdgeMarginTop", defaultValue: 5)

    /// How far from screen edge (in pixels) the snap zones extend - Bottom edge.
    static let snapEdgeMarginBottom = FloatDefault(key: "snapEdgeMarginBottom", defaultValue: 5)

    /// How far from screen edge (in pixels) the snap zones extend - Left edge.
    static let snapEdgeMarginLeft = FloatDefault(key: "snapEdgeMarginLeft", defaultValue: 5)

    /// How far from screen edge (in pixels) the snap zones extend - Right edge.
    static let snapEdgeMarginRight = FloatDefault(key: "snapEdgeMarginRight", defaultValue: 5)

    /// Size of corner snap areas (for quarter-screen snapping).
    static let cornerSnapAreaSize = FloatDefault(key: "cornerSnapAreaSize", defaultValue: 20)

    /// Size of the short edge snap areas.
    static let shortEdgeSnapAreaSize = FloatDefault(key: "shortEdgeSnapAreaSize", defaultValue: 145)

    /// Bitmask of snap areas to ignore/disable.
    static let ignoredSnapAreas = IntDefault(key: "ignoredSnapAreas")

    /// Whether to enable sixths snap areas (divide screen into 6 regions).
    static let sixthsSnapArea = OptionalBoolDefault(key: "sixthsSnapArea")

    /// Custom snap area configuration for landscape-oriented screens.
    static let landscapeSnapAreas = JSONDefault<[Directional:SnapAreaConfig]>(key: "landscapeSnapAreas")

    /// Custom snap area configuration for portrait-oriented screens.
    static let portraitSnapAreas = JSONDefault<[Directional:SnapAreaConfig]>(key: "portraitSnapAreas")

    // MARK: - Snap Footprint (Visual Preview)

    /// Opacity of the snap preview overlay (0.0 = invisible, 1.0 = opaque).
    static let footprintAlpha = FloatDefault(key: "footprintAlpha", defaultValue: 0.3)

    /// Border width of the snap preview overlay in pixels.
    static let footprintBorderWidth = FloatDefault(key: "footprintBorderWidth", defaultValue: 2)

    /// Whether the snap preview should fade in/out.
    static let footprintFade = OptionalBoolDefault(key: "footprintFade")

    /// Custom color for the snap preview overlay.
    static let footprintColor = JSONDefault<CodableColor>(key: "footprintColor")

    /// Multiplier for snap preview animation duration (0 = instant).
    static let footprintAnimationDurationMultiplier = FloatDefault(key: "footprintAnimationDurationMultiplier", defaultValue: 0)

    // MARK: - Window Gaps and Margins

    /// Gap size between windows when snapping (in pixels).
    static let gapSize = FloatDefault(key: "gapSize")

    /// Gap from top edge of screen to window.
    static let screenEdgeGapTop = FloatDefault(key: "screenEdgeGapTop", defaultValue: 0)

    /// Gap from bottom edge of screen to window.
    static let screenEdgeGapBottom = FloatDefault(key: "screenEdgeGapBottom", defaultValue: 0)

    /// Gap from left edge of screen to window.
    static let screenEdgeGapLeft = FloatDefault(key: "screenEdgeGapLeft", defaultValue: 0)

    /// Gap from right edge of screen to window.
    static let screenEdgeGapRight = FloatDefault(key: "screenEdgeGapRight", defaultValue: 0)

    /// Only apply screen edge gaps on the main display.
    static let screenEdgeGapsOnMainScreenOnly = BoolDefault(key: "screenEdgeGapsOnMainScreenOnly")

    /// Extra gap at top for MacBooks with notch displays.
    static let screenEdgeGapTopNotch = FloatDefault(key: "screenEdgeGapTopNotch", defaultValue: 0)

    // MARK: - Window Sizing

    /// "Almost maximize" target height as a fraction (0.0-1.0).
    static let almostMaximizeHeight = FloatDefault(key: "almostMaximizeHeight")

    /// "Almost maximize" target width as a fraction (0.0-1.0).
    static let almostMaximizeWidth = FloatDefault(key: "almostMaximizeWidth")

    /// Minimum window width (prevents windows from getting too small).
    static let minimumWindowWidth = FloatDefault(key: "minimumWindowWidth")

    /// Minimum window height (prevents windows from getting too small).
    static let minimumWindowHeight = FloatDefault(key: "minimumWindowHeight")

    /// How much to change size when using "larger"/"smaller" actions.
    static let sizeOffset = FloatDefault(key: "sizeOffset")

    /// Step size for width adjustments.
    static let widthStepSize = FloatDefault(key: "widthStepSize", defaultValue: 30)

    /// Target height for "specified size" action.
    static let specifiedHeight = FloatDefault(key: "specifiedHeight", defaultValue: 1050)

    /// Target width for "specified size" action.
    static let specifiedWidth = FloatDefault(key: "specifiedWidth", defaultValue: 1680)

    /// Whether to apply gaps when maximizing windows.
    static let applyGapsToMaximize = OptionalBoolDefault(key: "applyGapsToMaximize")

    /// Whether to apply gaps when maximizing window height only.
    static let applyGapsToMaximizeHeight = OptionalBoolDefault(key: "applyGapsToMaximizeHeight")

    /// Whether to auto-maximize windows that are dragged to nearly full size.
    static let autoMaximize = OptionalBoolDefault(key: "autoMaximize")

    // MARK: - Keyboard Shortcut Behavior

    /// What happens when you press the same shortcut multiple times.
    static let subsequentExecutionMode = SubsequentExecutionDefault()

    /// Which cycle sizes are selected for cycling actions.
    static let selectedCycleSizes = CycleSizesDefault()

    /// Whether cycle sizes have been customized from defaults.
    static let cycleSizesIsChanged = BoolDefault(key: "cycleSizesIsChanged")

    /// Whether to use alternate third-cycling behavior.
    static let altThirdCycle = OptionalBoolDefault(key: "altThirdCycle")

    /// Whether center position is included in half-window cycling.
    static let centerHalfCycles = OptionalBoolDefault(key: "centerHalfCycles")

    /// Whether directional move keeps window centered.
    static let centeredDirectionalMove = OptionalBoolDefault(key: "centeredDirectionalMove")

    /// Whether directional move also resizes the window.
    static let resizeOnDirectionalMove = BoolDefault(key: "resizeOnDirectionalMove")

    /// Whether "curtain" action changes window size.
    static let curtainChangeSize = OptionalBoolDefault(key: "curtainChangeSize")

    // MARK: - Multi-Display Settings

    /// Whether to traverse displays when on a single screen.
    static let traverseSingleScreen = OptionalBoolDefault(key: "traverseSingleScreen")

    /// Whether to use cursor position to detect which screen to use.
    static let useCursorScreenDetection = BoolDefault(key: "useCursorScreenDetection")

    /// Whether to try matching window position when moving between displays.
    static let attemptMatchOnNextPrevDisplay = OptionalBoolDefault(key: "attemptMatchOnNextPrevDisplay")

    /// Whether to move cursor when moving windows across displays.
    static let moveCursorAcrossDisplays = OptionalBoolDefault(key: "moveCursorAcrossDisplays")

    /// Whether to move cursor with window for any movement.
    static let moveCursor = OptionalBoolDefault(key: "moveCursor")

    /// Whether to order screens by X coordinate (left-to-right).
    static let screensOrderedByX = OptionalBoolDefault(key: "screensOrderedByX")

    // MARK: - Stage Manager (macOS Ventura+)

    /// Width of the Stage Manager strip area.
    static let stageSize = FloatDefault(key: "stageSize", defaultValue: 190)

    /// Whether to allow dragging windows from Stage Manager strip.
    static let dragFromStage = OptionalBoolDefault(key: "dragFromStage")

    /// Whether to always account for Stage Manager strip when positioning.
    static let alwaysAccountForStage = OptionalBoolDefault(key: "alwaysAccountForStage")

    // MARK: - Mission Control Dragging

    /// Whether to enable window dragging in Mission Control.
    static let missionControlDragging = OptionalBoolDefault(key: "missionControlDragging")

    /// How far offscreen a window can go during Mission Control dragging.
    static let missionControlDraggingAllowedOffscreenDistance = FloatDefault(key: "missionControlDraggingAllowedOffscreenDistance", defaultValue: 25)

    /// How long to disallow Mission Control dragging after certain events.
    static let missionControlDraggingDisallowedDuration = IntDefault(key: "missionControlDraggingDisallowedDuration", defaultValue: 250)

    // MARK: - Title Bar Double-Click

    /// What action to perform on title bar double-click (0 = none).
    static let doubleClickTitleBar = IntDefault(key: "doubleClickTitleBar")

    /// Whether double-click should restore from maximized state.
    static let doubleClickTitleBarRestore = OptionalBoolDefault(key: "doubleClickTitleBarRestore")

    /// Apps where title bar double-click is disabled.
    static let doubleClickTitleBarIgnoredApps = JSONDefault<[String]>(key: "doubleClickTitleBarIgnoredApps")

    /// Apps where toolbar double-click is ignored (Java apps, etc.).
    static let doubleClickToolBarIgnoredApps = JSONDefault<Set<String>>(key: "doubleClickTitleBarIgnoredApps", defaultValue: ["epp.package.java"])

    // MARK: - Accessibility Behavior

    /// How to handle "Enhanced User Interface" mode (see EnhancedUI enum).
    static let enhancedUI = IntEnumDefault<EnhancedUI>(key: "enhancedUI", defaultValue: .disableEnable)

    /// Whether to use system-wide mouse down detection (vs app-specific).
    static let systemWideMouseDown = OptionalBoolDefault(key: "systemWideMouseDown")

    /// Apps that should use system-wide mouse down detection.
    static let systemWideMouseDownApps = JSONDefault<Set<String>>(key:"systemWideMouseDownApps", defaultValue: Set<String>(["org.languagetool.desktop", "com.microsoft.teams2"]))

    /// Whether to obtain window element on click.
    static let obtainWindowOnClick = OptionalBoolDefault(key: "obtainWindowOnClick")

    // MARK: - Todo Mode (Sidebar Feature)

    /// Whether Todo mode is available.
    static let todo = OptionalBoolDefault(key: "todo")

    /// Whether Todo mode is currently active.
    static let todoMode = BoolDefault(key: "todoMode")

    /// Bundle ID of the todo application.
    static let todoApplication = StringDefault(key: "todoApplication")

    /// Width of the todo sidebar.
    static let todoSidebarWidth = FloatDefault(key: "todoSidebarWidth", defaultValue: 400)

    /// Unit for sidebar width (pixels or percentage).
    static let todoSidebarWidthUnit = IntEnumDefault<TodoSidebarWidthUnit>(key: "todoSidebarWidthUnit", defaultValue: .pixels)

    /// Which side the todo sidebar appears on.
    static let todoSidebarSide = IntEnumDefault<TodoSidebarSide>(key: "todoSidebarSide", defaultValue: .right)

    // MARK: - Menu Settings

    /// Whether to show all actions in the menu (vs just common ones).
    static let showAllActionsInMenu = OptionalBoolDefault(key: "showAllActionsInMenu")

    // MARK: - Multi-Window Actions

    /// Offset between windows when cascading.
    static let cascadeAllDeltaSize = FloatDefault(key: "cascadeAllDeltaSize", defaultValue: 30)

    // MARK: - Array of All Defaults (for Import/Export)

    /// Array containing all default settings for iteration during import/export.
    /// Note: Some settings are intentionally excluded (like version info).
    static var array: [Default] = [
        launchOnLogin,
        disabledApps,
        hideMenuBarIcon,
        alternateDefaultShortcuts,
        subsequentExecutionMode,
        selectedCycleSizes,
        cycleSizesIsChanged,
        allowAnyShortcut,
        windowSnapping,
        almostMaximizeHeight,
        almostMaximizeWidth,
        gapSize,
        snapEdgeMarginTop,
        snapEdgeMarginBottom,
        snapEdgeMarginLeft,
        snapEdgeMarginRight,
        centeredDirectionalMove,
        resizeOnDirectionalMove,
        ignoredSnapAreas,
        traverseSingleScreen,
        minimumWindowWidth,
        minimumWindowHeight,
        sizeOffset,
        widthStepSize,
        unsnapRestore,
        curtainChangeSize,
        relaunchOpensMenu,
        obtainWindowOnClick,
        screenEdgeGapTop,
        screenEdgeGapBottom,
        screenEdgeGapLeft,
        screenEdgeGapRight,
        screenEdgeGapsOnMainScreenOnly,
        screenEdgeGapTopNotch,
        showAllActionsInMenu,
        footprintAlpha,
        footprintBorderWidth,
        footprintFade,
        footprintColor,
        SUEnableAutomaticChecks,
        todo,
        todoMode,
        todoApplication,
        todoSidebarWidth,
        todoSidebarSide,
        snapModifiers,
        attemptMatchOnNextPrevDisplay,
        altThirdCycle,
        centerHalfCycles,
        fullIgnoreBundleIds,
        notifiedOfProblemApps,
        specifiedHeight,
        specifiedWidth,
        moveCursorAcrossDisplays,
        moveCursor,
        autoMaximize,
        applyGapsToMaximize,
        applyGapsToMaximizeHeight,
        cornerSnapAreaSize,
        shortEdgeSnapAreaSize,
        cascadeAllDeltaSize,
        sixthsSnapArea,
        stageSize,
        dragFromStage,
        alwaysAccountForStage,
        landscapeSnapAreas,
        portraitSnapAreas,
        missionControlDragging,
        enhancedUI,
        footprintAnimationDurationMultiplier,
        hapticFeedbackOnSnap,
        missionControlDraggingAllowedOffscreenDistance,
        missionControlDraggingDisallowedDuration,
        doubleClickTitleBar,
        doubleClickTitleBarRestore,
        doubleClickTitleBarIgnoredApps,
        ignoreDragSnapToo,
        systemWideMouseDown,
        systemWideMouseDownApps,
        screensOrderedByX
    ]
}

// MARK: - Import/Export Support

/// Container for serializing default values to JSON.
struct CodableDefault: Codable {
    let bool: Bool?
    let int: Int?
    let float: Float?
    let string: String?

    init(bool: Bool? = nil, int: Int? = nil, float: Float? = nil, string: String? = nil) {
        self.bool = bool
        self.int = int
        self.float = float
        self.string = string
    }
}

/// Protocol for settings import/export.
protocol Default {
    var key: String { get }
    func load(from codable: CodableDefault)
    func toCodable() -> CodableDefault
}

// MARK: - Wrapper Classes

/// Boolean setting wrapper.
class BoolDefault: Default {
    public private(set) var key: String
    private var initialized = false

    var enabled: Bool {
        didSet { if initialized { UserDefaults.standard.set(enabled, forKey: key) } }
    }

    init(key: String) {
        self.key = key
        enabled = UserDefaults.standard.bool(forKey: key)
        initialized = true
    }

    func load(from codable: CodableDefault) { if let v = codable.bool { enabled = v } }
    func toCodable() -> CodableDefault { CodableDefault(bool: enabled) }
}

/// Optional boolean (tri-state: true/false/nil) wrapper. Stored as Int: 0=nil, 1=true, 2=false.
class OptionalBoolDefault: Default {
    public private(set) var key: String
    private var initialized = false

    var enabled: Bool? {
        didSet {
            guard initialized else { return }
            UserDefaults.standard.set(enabled == true ? 1 : (enabled == false ? 2 : 0), forKey: key)
        }
    }

    var userDisabled: Bool { enabled == false }
    var userEnabled: Bool { enabled == true }
    var notSet: Bool { enabled == nil }

    init(key: String) {
        self.key = key
        let v = UserDefaults.standard.integer(forKey: key)
        enabled = v == 1 ? true : (v == 2 ? false : nil)
        initialized = true
    }

    func load(from codable: CodableDefault) {
        if let v = codable.int { enabled = v == 1 ? true : (v == 2 ? false : nil) }
    }
    func toCodable() -> CodableDefault { CodableDefault(int: enabled == true ? 1 : (enabled == false ? 2 : 0)) }
}

/// String setting wrapper.
class StringDefault: Default {
    public private(set) var key: String
    private var initialized = false

    var value: String? {
        didSet { if initialized { UserDefaults.standard.set(value, forKey: key) } }
    }

    init(key: String) {
        self.key = key
        value = UserDefaults.standard.string(forKey: key)
        initialized = true
    }

    func load(from codable: CodableDefault) { value = codable.string }
    func toCodable() -> CodableDefault { CodableDefault(string: value) }
}

/// Float setting wrapper.
class FloatDefault: Default {
    public private(set) var key: String
    private var initialized = false

    var value: Float {
        didSet { if initialized { UserDefaults.standard.set(value, forKey: key) } }
    }

    var cgFloat: CGFloat { CGFloat(value) }

    init(key: String, defaultValue: Float = 0) {
        self.key = key
        value = UserDefaults.standard.float(forKey: key)
        if defaultValue != 0 && value == 0 { value = defaultValue }
        initialized = true
    }

    func load(from codable: CodableDefault) { if let v = codable.float { value = v } }
    func toCodable() -> CodableDefault { CodableDefault(float: value) }
}

/// Integer setting wrapper.
class IntDefault: Default {
    public private(set) var key: String
    private var initialized = false

    var value: Int {
        didSet { if initialized { UserDefaults.standard.set(value, forKey: key) } }
    }

    init(key: String, defaultValue: Int = 0) {
        self.key = key
        value = UserDefaults.standard.integer(forKey: key)
        if defaultValue != 0 && value == 0 { value = defaultValue }
        initialized = true
    }

    func load(from codable: CodableDefault) { if let v = codable.int { value = v } }
    func toCodable() -> CodableDefault { CodableDefault(int: value) }
}

/// JSON-encoded complex object wrapper.
class JSONDefault<T: Codable>: StringDefault {
    private var typeInitialized = false
    var typedValue: T? {
        didSet { if typeInitialized { saveToJSON(typedValue) } }
    }

    override init(key: String) {
        super.init(key: key)
        loadFromJSON()
        typeInitialized = true
    }

    init(key: String, defaultValue: T) {
        if typedValue == nil { typedValue = defaultValue }
        super.init(key: key)
    }

    override func load(from codable: CodableDefault) {
        if value != codable.string {
            value = codable.string
            typeInitialized = false
            loadFromJSON()
            typeInitialized = true
        }
    }

    private func loadFromJSON() {
        guard let json = value, let data = json.data(using: .utf8) else { return }
        typedValue = try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveToJSON(_ obj: T?) {
        if let data = try? JSONEncoder().encode(obj), let json = String(data: data, encoding: .utf8), json != value {
            value = json
        }
    }
}

/// CycleSize set wrapper (stored as bitmask).
class CycleSizesDefault: Default {
    public private(set) var key: String = "selectedCycleSizes"
    private var initialized = false

    var value: Set<CycleSize> {
        didSet { if initialized { UserDefaults.standard.set(value.toBits(), forKey: key) } }
    }

    init() {
        value = CycleSize.fromBits(bits: UserDefaults.standard.integer(forKey: key))
        initialized = true
    }

    func load(from codable: CodableDefault) { if let bits = codable.int { value = CycleSize.fromBits(bits: bits) } }
    func toCodable() -> CodableDefault { CodableDefault(int: value.toBits()) }
}

/// SubsequentExecutionMode wrapper.
class SubsequentExecutionDefault: Default {
    public private(set) var key: String = "subsequentExecutionMode"
    private var initialized = false

    var value: SubsequentExecutionMode {
        didSet { if initialized { UserDefaults.standard.set(value.rawValue, forKey: key) } }
    }

    init() {
        value = SubsequentExecutionMode(rawValue: UserDefaults.standard.integer(forKey: key)) ?? .resize
        initialized = true
    }

    var resizes: Bool { value == .resize || value == .acrossAndResize }
    var traversesDisplays: Bool { value == .acrossMonitor || value == .acrossAndResize }

    func load(from codable: CodableDefault) {
        if let v = codable.int, let mode = SubsequentExecutionMode(rawValue: v) { value = mode }
    }
    func toCodable() -> CodableDefault { CodableDefault(int: value.rawValue) }
}

// MARK: - Enum Setting (Integer-Based)

/// Wrapper for enum settings where the enum has Int raw values.
///
/// Example:
/// ```swift
/// enum Theme: Int {
///     case light = 0
///     case dark = 1
/// }
/// static let theme = IntEnumDefault<Theme>(key: "theme", defaultValue: .light)
///
/// // Reading
/// switch Defaults.theme.value {
/// case .light: // ...
/// case .dark: // ...
/// }
///
/// // Writing
/// Defaults.theme.value = .dark
/// ```
class IntEnumDefault<E: RawRepresentable>: Default where E.RawValue == Int {

    public private(set) var key: String
    private let defaultValue: E

    /// Internal storage for the value.
    var _value: E

    /// The current enum value.
    var value: E {
        set {
            if newValue != _value {
                _value = newValue
                UserDefaults.standard.set(_value.rawValue, forKey: key)
            }
        }
        get { _value }
    }

    init(key: String, defaultValue: E) {
        self.key = key
        self.defaultValue = defaultValue

        // Load from UserDefaults, falling back to default if invalid
        let intValue = UserDefaults.standard.integer(forKey: key)
        _value = E(rawValue: intValue) ?? defaultValue
    }

    func load(from codable: CodableDefault) {
        if let intValue = codable.int, _value.rawValue != intValue {
            _value = E(rawValue: intValue) ?? defaultValue
            UserDefaults.standard.set(_value.rawValue, forKey: key)
        }
    }

    func toCodable() -> CodableDefault {
        return CodableDefault(int: value.rawValue)
    }
}

// MARK: - Color Storage

/// A Codable wrapper for NSColor, allowing colors to be stored in UserDefaults.
///
/// NSColor itself isn't Codable, so we store the RGBA components separately.
struct CodableColor: Codable {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat? = 1.0

    /// Convert back to NSColor for use in AppKit.
    var nsColor: NSColor {
        return NSColor(red: red, green: green, blue: blue, alpha: alpha ?? 1.0)
    }

    /// Convert to SwiftUI Color.
    var color: Color {
        return Color(red: red, green: green, blue: blue, opacity: alpha ?? 1.0)
    }

    /// Create from an NSColor.
    init(nsColor: NSColor) {
        self.red = nsColor.redComponent
        self.green = nsColor.greenComponent
        self.blue = nsColor.blueComponent
        self.alpha = nsColor.alphaComponent
    }
}

// MARK: - SettingsProtocol Conformance

/// Adapter that bridges Defaults to WindowManagerCore's SettingsProtocol.
///
/// This allows the package's calculators to use the app's settings without
/// depending on the Defaults class directly.
struct DefaultsAdapter: SettingsProtocol {
    // MARK: Gap Settings
    var gapSize: CGFloat { CGFloat(Defaults.gapSize.value) }
    var screenEdgeGapTop: CGFloat { CGFloat(Defaults.screenEdgeGapTop.value) }
    var screenEdgeGapBottom: CGFloat { CGFloat(Defaults.screenEdgeGapBottom.value) }
    var screenEdgeGapLeft: CGFloat { CGFloat(Defaults.screenEdgeGapLeft.value) }
    var screenEdgeGapRight: CGFloat { CGFloat(Defaults.screenEdgeGapRight.value) }

    // MARK: Sizing Settings
    var almostMaximizeHeight: CGFloat { CGFloat(Defaults.almostMaximizeHeight.value) }
    var almostMaximizeWidth: CGFloat { CGFloat(Defaults.almostMaximizeWidth.value) }
    var minimumWindowWidth: CGFloat { CGFloat(Defaults.minimumWindowWidth.value) }
    var minimumWindowHeight: CGFloat { CGFloat(Defaults.minimumWindowHeight.value) }
    var sizeOffset: CGFloat { CGFloat(Defaults.sizeOffset.value) }
    var widthStepSize: CGFloat { 30 }  // Default value
    var specifiedHeight: CGFloat { CGFloat(Defaults.specifiedHeight.value) }
    var specifiedWidth: CGFloat { CGFloat(Defaults.specifiedWidth.value) }
    var todoSidebarWidth: CGFloat { CGFloat(Defaults.todoSidebarWidth.value) }

    // MARK: Behavior Settings
    var applyGapsToMaximize: Bool { Defaults.applyGapsToMaximize.enabled ?? true }
    var applyGapsToMaximizeHeight: Bool { Defaults.applyGapsToMaximizeHeight.enabled ?? true }
    var resizeOnDirectionalMove: Bool { Defaults.resizeOnDirectionalMove.enabled }
    var centerHalfCycles: Bool { Defaults.centerHalfCycles.enabled ?? false }
    var altThirdCycle: Bool { Defaults.altThirdCycle.enabled ?? false }
    var centeredDirectionalMove: Bool { Defaults.centeredDirectionalMove.enabled ?? false }
}

extension Defaults {
    /// Shared settings adapter for use with WindowManagerCore calculators.
    static let settings: SettingsProtocol = DefaultsAdapter()
}

// MARK: - Observable Settings for SwiftUI

/// Observable settings wrapper for SwiftUI views.
@Observable @MainActor
final class ObservableSettings {
    static let shared = ObservableSettings()

    private init() {
        NotificationCenter.default.addObserver(forName: .configImported, object: nil, queue: .main) { [weak self] _ in
            self?.refreshAll()
        }
    }

    var launchOnLogin: Bool {
        get { Defaults.launchOnLogin.enabled }
        set { Defaults.launchOnLogin.enabled = newValue }
    }
    var hideMenuBarIcon: Bool {
        get { Defaults.hideMenuBarIcon.enabled }
        set { Defaults.hideMenuBarIcon.enabled = newValue }
    }
    var allowAnyShortcut: Bool {
        get { Defaults.allowAnyShortcut.enabled }
        set { Defaults.allowAnyShortcut.enabled = newValue }
    }
    var gapSize: Float {
        get { Defaults.gapSize.value }
        set { Defaults.gapSize.value = newValue }
    }
    var windowSnappingEnabled: Bool {
        get { Defaults.windowSnapping.enabled ?? true }
        set { Defaults.windowSnapping.enabled = newValue }
    }
    var applyGapsToMaximize: Bool {
        get { Defaults.applyGapsToMaximize.enabled ?? true }
        set { Defaults.applyGapsToMaximize.enabled = newValue }
    }
    var todoEnabled: Bool {
        get { Defaults.todo.userEnabled }
        set { Defaults.todo.enabled = newValue }
    }
    var todoModeActive: Bool {
        get { Defaults.todoMode.enabled }
        set { Defaults.todoMode.enabled = newValue }
    }
    var todoSidebarWidth: Float {
        get { Defaults.todoSidebarWidth.value }
        set { Defaults.todoSidebarWidth.value = newValue }
    }

    func refreshAll() {}
}
