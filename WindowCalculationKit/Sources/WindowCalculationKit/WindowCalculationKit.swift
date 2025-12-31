//
//  WindowCalculationKit.swift
//  WindowCalculationKit
//
//  A Swift package for calculating window positions and sizes.
//
//  This package provides the core calculation logic for window management,
//  including positioning windows in halves, thirds, quarters, and grids.
//
//  ## Overview
//
//  The package is organized into:
//  - **Types**: Pure data types like `ActionIdentifier`, `CycleSize`, `GridType`
//  - **Core**: Core data structures like `RectResult`, `CalculationParams`
//  - **Protocols**: `Calculation`, `OrientationAware`, `RepeatedExecution`
//  - **Calculations**: Concrete calculation implementations (to be added)
//
//  ## Usage
//
//  ```swift
//  import WindowCalculationKit
//
//  // Create parameters
//  let params = CalculationParams(
//      window: WindowInfo(id: 1, rect: currentRect),
//      visibleFrame: screenFrame,
//      action: .leftHalf
//  )
//
//  // Perform calculation
//  let result = LeftHalfCalculation().calculateRect(params)
//  // Apply result.rect to the window
//  ```
//

// Re-export all public types

// Types
@_exported import struct Foundation.CGRect
@_exported import struct Foundation.CGPoint
@_exported import struct Foundation.CGSize

// This file serves as the main entry point and documentation for the package.
// All public types are automatically available when importing WindowCalculationKit.
