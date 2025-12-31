//
//  AppDelegate.swift
//  tiny_window_managerLauncher
//
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print(#function, "called")
        if #available(macOS 13, *) {
            terminate()
            return
        }
        let mainAppIdentifier = "com.wudan.tiny-window-manager"
        let running = NSWorkspace.shared.runningApplications
        let isRunning = !running.filter({$0.bundleIdentifier == mainAppIdentifier}).isEmpty
        
        if isRunning {
            self.terminate()
        } else {
            let killNotification = Notification.Name("killLauncher")
            DistributedNotificationCenter.default().addObserver(self,
                                                                selector: #selector(self.terminate),
                                                                name: killNotification,
                                                                object: mainAppIdentifier)
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("tiny_window_manager")
            let newPath = NSString.path(withComponents: components)
            if let url = URL(string: "file://\(newPath)") {
                let configuration = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
                    if let error = error {
                        NSLog("Failed to launch main app: \(error.localizedDescription)")
                    }
                }
            } else {
                NSLog("Failed to construct URL for path: \(newPath)")
            }
        }
    }
    
    @objc func terminate() {
        print(#function, "called")
        NSApp.terminate(nil)
    }

}

