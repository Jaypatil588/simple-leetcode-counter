//
//  LeetcodeCounterApp.swift
//  LeetcodeCounter
//
//  Main app entry point
//

import SwiftUI
import AppKit

@main
struct LeetcodeCounterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// App delegate for lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    private var counterStore = CounterStore()
    private var themeManager = ThemeManager()
    private var accessibilityManager = AccessibilityManager()
    private var windowManager = DesktopOverlayWindow()
    private var launchAgentManager = LaunchAgentManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent multiple instances
        checkForExistingInstance()
        
        // Setup Launch Agent
        _ = launchAgentManager.setupLaunchAgent()
        
        // Setup windows after a short delay to ensure app is fully initialized
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupWindows()
        }
        
        // Monitor for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recreateWindows),
            name: NSNotification.Name("RecreateWindows"),
            object: nil
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        windowManager.closeAllWindows()
    }
    
    @objc private func recreateWindows() {
        setupWindows()
    }
    
    private func checkForExistingInstance() {
        let runningApps = NSWorkspace.shared.runningApplications
        let currentBundleId = Bundle.main.bundleIdentifier
        
        for app in runningApps {
            if app.bundleIdentifier == currentBundleId && app.processIdentifier != ProcessInfo.processInfo.processIdentifier {
                // Another instance is running, activate it and exit
                app.activate(options: .activateIgnoringOtherApps)
                NSApplication.shared.terminate(nil)
                return
            }
        }
    }
    
    private func setupWindows() {
        windowManager.createWindows(
            counterStore: counterStore,
            themeManager: themeManager,
            accessibilityManager: accessibilityManager
        )
    }
}

