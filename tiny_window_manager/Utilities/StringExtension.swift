//
//  StringExtension.swift
//  tiny_window_manager
//
//

import Foundation

extension String {
    
    var localized: String {
        NSLocalizedString(self, tableName: "Main", comment: "")
    }
    
}
