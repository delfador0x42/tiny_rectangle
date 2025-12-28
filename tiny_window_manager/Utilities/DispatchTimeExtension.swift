//
//  DispatchTimeExtension.swift
//  tiny_window_manager
//
//

import Foundation

extension DispatchTime {
    var uptimeMilliseconds: UInt64 { uptimeNanoseconds / 1_000_000 }
}
