//
//  ThemeManager.swift
//  LeetcodeCounter
//
//  Theme system for future customization, defaults to dark
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true
    
    init() {
        // Default to dark theme for now
        // Future: Can be made configurable
        isDarkMode = true
    }
    
    var textColor: Color {
        isDarkMode ? .white : .black
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color.black.opacity(0.3) : Color.white.opacity(0.3)
    }
    
    var buttonColor: Color {
        isDarkMode ? Color.white.opacity(0.2) : Color.black.opacity(0.2)
    }
    
    var buttonHoverColor: Color {
        isDarkMode ? Color.white.opacity(0.4) : Color.black.opacity(0.4)
    }
}

