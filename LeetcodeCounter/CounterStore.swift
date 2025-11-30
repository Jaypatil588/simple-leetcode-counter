//
//  CounterStore.swift
//  LeetcodeCounter
//
//  Created for LeetCode Counter Wallpaper
//

import Foundation
import SwiftUI

class CounterStore: ObservableObject {
    @Published var count: Int = 0
    private let counterKey = "leetcodeCounter"
    private let backupKey = "leetcodeCounterBackup"
    
    init() {
        loadCounter()
    }
    
    func loadCounter() {
        // Try to load from primary storage
        if let primaryValue = UserDefaults.standard.object(forKey: counterKey) as? Int {
            // Validate the value
            if isValidCounterValue(primaryValue) {
                count = primaryValue
                return
            }
        }
        
        // Primary is corrupted or missing, try backup
        if let backupValue = UserDefaults.standard.object(forKey: backupKey) as? Int {
            if isValidCounterValue(backupValue) {
                count = backupValue
                // Restore backup to primary
                UserDefaults.standard.set(backupValue, forKey: counterKey)
                return
            }
        }
        
        // Both corrupted or missing, reset to 0
        count = 0
        saveCounter()
    }
    
    private func isValidCounterValue(_ value: Int) -> Bool {
        // Allow any integer value (can be negative or above 500)
        return true
    }
    
    func increment() {
        // Save current value to backup before updating
        UserDefaults.standard.set(count, forKey: backupKey)
        
        // Update synchronously (we're already on main thread from button action)
        // @Published property wrapper automatically sends objectWillChange when count changes
        count += 1
        saveCounter()
    }
    
    func decrement() {
        // Save current value to backup before updating
        UserDefaults.standard.set(count, forKey: backupKey)
        
        // Update synchronously (we're already on main thread from button action)
        // @Published property wrapper automatically sends objectWillChange when count changes
        count -= 1
        saveCounter()
    }
    
    private func saveCounter() {
        UserDefaults.standard.set(count, forKey: counterKey)
        UserDefaults.standard.synchronize()
    }
}

