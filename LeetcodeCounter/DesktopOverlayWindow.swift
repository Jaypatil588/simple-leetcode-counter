//
//  DesktopOverlayWindow.swift
//  LeetcodeCounter
//
//  Window manager for desktop-level overlay
//

import AppKit
import SwiftUI
import CoreGraphics

// Custom window class that never steals focus
class NonFocusWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    override func makeKey() {
        // Do nothing - prevent becoming key window
    }
    
    override func makeMain() {
        // Do nothing - prevent becoming main window
    }
}

class DesktopOverlayWindow {
    private var windows: [NSWindow] = []
    private var retryAttempts: [NSScreen: Int] = [:]
    private let maxRetryAttempts = 3
    private var screenObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    
    // Store shared instances to ensure all windows use the same objects
    private weak var sharedCounterStore: CounterStore?
    private weak var sharedThemeManager: ThemeManager?
    private weak var sharedAccessibilityManager: AccessibilityManager?
    
    func createWindows(counterStore: CounterStore, themeManager: ThemeManager, accessibilityManager: AccessibilityManager) {
        // Store shared instances
        sharedCounterStore = counterStore
        sharedThemeManager = themeManager
        sharedAccessibilityManager = accessibilityManager
        
        // Remove existing windows
        closeAllWindows()
        
        // Get all screens
        let screens = NSScreen.screens
        print("Creating windows for \(screens.count) screen(s)")
        
        for (index, screen) in screens.enumerated() {
            let window = createWindow(for: screen, counterStore: counterStore, themeManager: themeManager, accessibilityManager: accessibilityManager)
            windows.append(window)
            print("Created window \(index + 1) for screen: frame=\(screen.frame), visibleFrame=\(screen.visibleFrame)")
        }
        
        // Monitor for screen changes
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.screensChanged()
        }
        
        // Monitor for wake from sleep
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.wakeFromSleep()
        }
    }
    
    private func createWindow(for screen: NSScreen, counterStore: CounterStore, themeManager: ThemeManager, accessibilityManager: AccessibilityManager) -> NSWindow {
        // Use visibleFrame to get the correct frame excluding menu bar and dock
        let screenFrame = screen.visibleFrame
        
        // Create custom window that never steals focus
        let window = NonFocusWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Set window properties - use desktop icon level which allows mouse events but stays behind normal windows
        // Desktop window level (-2) doesn't receive mouse events, so we use desktop icon level (-1)
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        
        // Position window correctly for this screen
        window.setFrame(screenFrame, display: true)
        
        // Create SwiftUI view wrapped in a container that forces updates
        // Use a wrapper that recreates when counter changes
        let contentView = CounterViewWrapper(
            counterStore: counterStore,
            themeManager: themeManager,
            accessibilityManager: accessibilityManager
        )
        
        // Create hosting view with proper frame in window coordinates (0,0 origin)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(origin: .zero, size: screenFrame.size)
        // Enable layer-backed view for better performance and updates
        hostingView.wantsLayer = true
        // Ensure the view updates when the observable object changes
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        
        // Make window visible without stealing focus
        window.orderFront(nil)
        
        // Verify window is visible, retry if not
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !window.isVisible {
                self.retryWindowCreation(for: screen, counterStore: counterStore, themeManager: themeManager, accessibilityManager: accessibilityManager)
            }
        }
        
        return window
    }
    
    private func retryWindowCreation(for screen: NSScreen, counterStore: CounterStore, themeManager: ThemeManager, accessibilityManager: AccessibilityManager) {
        let currentAttempts = retryAttempts[screen] ?? 0
        
        guard currentAttempts < maxRetryAttempts else {
            // Log error after max retries
            print("Failed to create visible window after \(maxRetryAttempts) attempts for screen: \(screen)")
            return
        }
        
        retryAttempts[screen] = currentAttempts + 1
        
        // Try alternative window levels
        // Desktop icon level (-1) allows mouse events, desktop level (-2) doesn't
        let levelValues: [Int] = [
            Int(CGWindowLevelForKey(.desktopIconWindow)),       // -1 (desktop icon - allows mouse events)
            Int(CGWindowLevelForKey(.desktopWindow))             // -2 (desktop - no mouse events, fallback)
        ]
        
        if currentAttempts < levelValues.count {
            let levelValue = levelValues[currentAttempts]
            let level = NSWindow.Level(rawValue: levelValue)
            
            // Find window for this screen and update level
            if let window = windows.first(where: { $0.screen == screen }) {
                window.level = level
                window.orderFront(nil)
            }
        }
    }
    
    private func screensChanged() {
        // Re-detect monitors and recreate windows
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // This will be called from the app to recreate windows
            NotificationCenter.default.post(name: NSNotification.Name("RecreateWindows"), object: nil)
        }
    }
    
    private func wakeFromSleep() {
        // Restore window visibility after wake without stealing focus
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for window in self.windows {
                window.orderFront(nil)
            }
        }
    }
    
    func closeAllWindows() {
        for window in windows {
            window.close()
        }
        windows.removeAll()
    }
    
    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        closeAllWindows()
    }
}

