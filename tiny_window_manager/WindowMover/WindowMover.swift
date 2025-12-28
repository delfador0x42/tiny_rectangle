//
//  WindowMover.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Foundation

protocol WindowMover {
    func moveWindowRect(_ windowRect: CGRect, frameOfScreen: CGRect, visibleFrameOfScreen: CGRect, frontmostWindowElement: AccessibilityElement?, action: WindowAction?)
}
