//  WindowManagerCore.swift - Main module export
//
//  This file re-exports all public types from the WindowManagerCore package.
//  Import WindowManagerCore to access all window calculation and geometry types.

import CoreGraphics
import Foundation

// MARK: - Module Overview
//
// WindowManagerCore provides pure Swift types for window management:
//
// **Protocols:**
// - WindowProtocol: Abstraction for window elements
// - ScreenProtocol: Abstraction for screen information
// - SettingsProtocol: Abstraction for user settings
//
// **Models:**
// - WindowActionType: All possible window actions
// - ActionRecord: Records of applied actions
// - SubActionType: Sub-action variants
// - Edge, Dimension, Directional: Geometry primitives
//
// **Calculators:**
// - RectCalculator: Pure window position calculations
// - GapCalculator: Gap/padding calculations
// - CycleCalculator: Action cycling logic
// - SnapAreaCalculator: Snap zone detection
//
// **Geometry:**
// - CGRect, CGPoint, CGSize extensions

// All types are automatically exported through their individual files.
// This file exists to provide module-level documentation.
