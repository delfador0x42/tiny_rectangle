//
//  StandardWindowMover.swift
//  tiny_window_manager, Ported from Spectacle
//
//

import Foundation

class StandardWindowMover: WindowMover {
    func moveWindowRect(_ windowRect: CGRect, frameOfScreen: CGRect, visibleFrameOfScreen: CGRect, frontmostWindowElement: AccessibilityElement?, action: WindowAction?) {
        let previousWindowRect: CGRect? = frontmostWindowElement?.frame
        if previousWindowRect?.isNull == true {
            return
        }
        frontmostWindowElement?.setFrame(windowRect)
    }
}
