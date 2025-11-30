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
    
    // Prevent concurrent window recreation
    private var isRecreating = false
    private let recreationQueue = DispatchQueue(label: "com.leetcode.counter.windowRecreation")
    
    // Debouncing for screen changes and wake events
    private var lastScreenChangeTime: Date?
    private var lastWakeTime: Date?
    private let screenChangeCooldown: TimeInterval = 1.0
    private let wakeCooldown: TimeInterval = 0.5
    
    // Track cancellable tasks
    private var pendingTasks: [DispatchWorkItem] = []
    private var visibilityCheckTasks: [NSScreen: DispatchWorkItem] = [:]
    private var retryTasks: [NSScreen: DispatchWorkItem] = [:]
    private var screenChangeTask: DispatchWorkItem?
    private var wakeTask: DispatchWorkItem?
    
    // Store shared instances to ensure all windows use the same objects
    private weak var sharedCounterStore: CounterStore?
    private weak var sharedThemeManager: ThemeManager?
    private weak var sharedAccessibilityManager: AccessibilityManager?
    
    func createWindows(counterStore: CounterStore, themeManager: ThemeManager, accessibilityManager: AccessibilityManager) {
        // Prevent concurrent recreation
        recreationQueue.sync {
            guard !isRecreating else {
                print("Window recreation already in progress, skipping")
                return
            }
            isRecreating = true
        }
        
        // Cancel all pending tasks
        cancelAllPendingTasks()
        
        // Remove existing observers before adding new ones to prevent accumulation
        removeObservers()
        
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
        
        // Mark recreation as complete
        recreationQueue.async { [weak self] in
            self?.isRecreating = false
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
        window.acceptsMouseMovedEvents = false // Disable to prevent updates on mouse movement
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
        // Enable layer-backed view for better performance
        hostingView.wantsLayer = true
        // Optimize rendering - draw asynchronously to reduce CPU usage
        if let layer = hostingView.layer {
            layer.drawsAsynchronously = true
        }
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        
        // Make window visible without stealing focus
        window.orderFront(nil)
        
        // Verify window is visible, retry if not
        let visibilityCheckTask = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !window.isVisible {
                self.retryWindowCreation(for: screen, counterStore: counterStore, themeManager: themeManager, accessibilityManager: accessibilityManager)
            }
        }
        visibilityCheckTasks[screen] = visibilityCheckTask
        pendingTasks.append(visibilityCheckTask)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: visibilityCheckTask)
        
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
        // Debounce screen change events to prevent notification loops
        let now = Date()
        
        // Check cooldown period
        if let lastChange = lastScreenChangeTime, now.timeIntervalSince(lastChange) < screenChangeCooldown {
            print("Screen change ignored - within cooldown period")
            return
        }
        
        lastScreenChangeTime = now
        
        // Cancel previous screen change task if it exists
        screenChangeTask?.cancel()
        
        // Create new debounced task
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // This will be called from the app to recreate windows
            NotificationCenter.default.post(name: NSNotification.Name("RecreateWindows"), object: nil)
        }
        screenChangeTask = task
        pendingTasks.append(task)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }
    
    private func wakeFromSleep() {
        // Debounce wake events to prevent multiple rapid wake notifications
        let now = Date()
        
        // Check cooldown period
        if let lastWake = lastWakeTime, now.timeIntervalSince(lastWake) < wakeCooldown {
            print("Wake event ignored - within cooldown period")
            return
        }
        
        lastWakeTime = now
        
        // Cancel previous wake task if it exists
        wakeTask?.cancel()
        
        // Create new debounced task
        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            // Restore window visibility after wake without stealing focus
            for window in self.windows {
                window.orderFront(nil)
            }
        }
        wakeTask = task
        pendingTasks.append(task)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }
    
    func closeAllWindows() {
        // Cancel all pending tasks before closing windows
        cancelAllPendingTasks()
        
        for window in windows {
            window.close()
        }
        windows.removeAll()
        retryAttempts.removeAll()
    }
    
    private func cancelAllPendingTasks() {
        // Cancel all visibility check tasks
        for (_, task) in visibilityCheckTasks {
            task.cancel()
        }
        visibilityCheckTasks.removeAll()
        
        // Cancel all retry tasks
        for (_, task) in retryTasks {
            task.cancel()
        }
        retryTasks.removeAll()
        
        // Cancel screen change and wake tasks
        screenChangeTask?.cancel()
        screenChangeTask = nil
        wakeTask?.cancel()
        wakeTask = nil
        
        // Cancel all other pending tasks
        for task in pendingTasks {
            task.cancel()
        }
        pendingTasks.removeAll()
    }
    
    private func removeObservers() {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
            screenObserver = nil
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            wakeObserver = nil
        }
    }
    
    deinit {
        cancelAllPendingTasks()
        removeObservers()
        closeAllWindows()
    }
}

