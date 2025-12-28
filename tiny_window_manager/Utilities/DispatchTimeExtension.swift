//
//  DispatchTimeExtension.swift
//  tiny_window_manager
//
//  Copyright © 2022 Ryan Hanson. All rights reserved.
//

import Foundation

extension DispatchTime {
    var uptimeMilliseconds: UInt64 { uptimeNanoseconds / 1_000_000 }
}
