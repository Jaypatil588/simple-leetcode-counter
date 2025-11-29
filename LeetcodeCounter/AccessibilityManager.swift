//
//  AccessibilityManager.swift
//  LeetcodeCounter
//
//  Manages Accessibility permissions for button clicks
//

import AppKit
import Foundation
import ApplicationServices

class AccessibilityManager: ObservableObject {
    @Published var hasPermission: Bool = false
    @Published var shouldShowInstructions: Bool = false
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        // Check permission without prompting
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Update immediately (we're likely on main thread already)
        hasPermission = trusted
        if !trusted {
            shouldShowInstructions = true
        } else {
            shouldShowInstructions = false
        }
        
        print("🔐 [AccessibilityManager] Permission check: \(trusted)")
    }
    
    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        hasPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !hasPermission {
            shouldShowInstructions = true
        }
    }
    
    func showInstructionsDialog() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        To use the counter buttons, please grant Accessibility permissions:
        
        1. Open System Settings (System Preferences)
        2. Go to Privacy & Security
        3. Select Accessibility
        4. Click the lock to make changes
        5. Find "LeetcodeCounter" in the list
        6. Enable the checkbox
        
        The app will work after you grant permissions and restart it.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Accessibility
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

