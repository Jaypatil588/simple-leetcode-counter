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
    @Published var revisionCount: Int = 0
    private let counterKey = "leetcodeCounter"
    private let backupKey = "leetcodeCounterBackup"
    private let revisionKey = "leetcodeRevisionCounter"
    private let revisionBackupKey = "leetcodeRevisionCounterBackup"
    
    init() {
        loadCounter()
    }
    
    func loadCounter() {
        // Try to load main counter from primary storage
        if let primaryValue = UserDefaults.standard.object(forKey: counterKey) as? Int {
            // Validate the value
            if isValidCounterValue(primaryValue) {
                count = primaryValue
            }
        } else if let backupValue = UserDefaults.standard.object(forKey: backupKey) as? Int {
            // Primary is corrupted or missing, try backup
            if isValidCounterValue(backupValue) {
                count = backupValue
                // Restore backup to primary
                UserDefaults.standard.set(backupValue, forKey: counterKey)
            }
        } else {
            // Both corrupted or missing, reset to 0
            count = 0
            saveCounter()
        }
        
        // Try to load revision counter from primary storage
        if let primaryValue = UserDefaults.standard.object(forKey: revisionKey) as? Int {
            if isValidCounterValue(primaryValue) {
                revisionCount = primaryValue
            }
        } else if let backupValue = UserDefaults.standard.object(forKey: revisionBackupKey) as? Int {
            // Primary is corrupted or missing, try backup
            if isValidCounterValue(backupValue) {
                revisionCount = backupValue
                // Restore backup to primary
                UserDefaults.standard.set(backupValue, forKey: revisionKey)
            }
        } else {
            // Both corrupted or missing, reset to 0
            revisionCount = 0
            saveRevisionCounter()
        }
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
    
    func incrementRevision() {
        // Save current value to backup before updating
        UserDefaults.standard.set(revisionCount, forKey: revisionBackupKey)
        
        revisionCount += 1
        saveRevisionCounter()
    }
    
    func decrementRevision() {
        // Save current value to backup before updating
        UserDefaults.standard.set(revisionCount, forKey: revisionBackupKey)
        
        revisionCount -= 1
        saveRevisionCounter()
    }
    
    private func saveCounter() {
        UserDefaults.standard.set(count, forKey: counterKey)
        UserDefaults.standard.synchronize()
    }
    
    private func saveRevisionCounter() {
        UserDefaults.standard.set(revisionCount, forKey: revisionKey)
        UserDefaults.standard.synchronize()
    }
}

