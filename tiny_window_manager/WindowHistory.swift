//
//  WindowHistory.swift
//  tiny_window_manager
//
//  Created by Ryan Hanson on 9/6/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class WindowHistory {
    
    var restoreRects = [CGWindowID: CGRect]() // the last window frame that the user positioned
    
    var lasttiny_window_managerActions = [CGWindowID: tiny_window_managerAction]() // the last window frame that this app positioned
    
}
