//
//  CounterView.swift
//  LeetcodeCounter
//
//  Main UI with counter display and buttons
//

import SwiftUI
import UserNotifications

// Wrapper view for counter display
struct CounterViewWrapper: View {
    @ObservedObject var counterStore: CounterStore
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var accessibilityManager: AccessibilityManager
    
    var body: some View {
        CounterView(
            counterStore: counterStore,
            themeManager: themeManager,
            accessibilityManager: accessibilityManager
        )
        // Removed .id() modifier - let SwiftUI handle updates efficiently
        // This prevents unnecessary view recreation and reduces CPU usage
    }
}

struct CounterView: View {
    @ObservedObject var counterStore: CounterStore
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var accessibilityManager: AccessibilityManager
    @State private var showCelebration = false
    @State private var plusButtonPressed = false
    @State private var minusButtonPressed = false
    @State private var isCommandKeyPressed = false
    
    var body: some View {
        ZStack {
            // Background
            themeManager.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Counter Display
                Text("\(counterStore.count) / 500 | \(counterStore.revisionCount)")
                    .font(.system(size: 96, weight: .bold, design: .default))
                    .foregroundColor(isCommandKeyPressed ? themeManager.textColor.opacity(0.7) : themeManager.textColor)
                    .monospacedDigit()
                
                // Buttons
                HStack(spacing: 60) {
                    // Minus Button
                    Button(action: {
                        handleDecrement()
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.textColor)
                            .scaleEffect(minusButtonPressed ? 0.9 : 1.0)
                            .opacity(minusButtonPressed ? 0.7 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(themeManager.buttonColor)
                            .scaleEffect(minusButtonPressed ? 0.95 : 1.0)
                    )
                    .pressEvents(onPress: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            minusButtonPressed = true
                        }
                    }, onRelease: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            minusButtonPressed = false
                        }
                    })
                    
                    // Plus Button
                    Button(action: {
                        handleIncrement()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.textColor)
                            .scaleEffect(plusButtonPressed ? 0.9 : 1.0)
                            .opacity(plusButtonPressed ? 0.7 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(themeManager.buttonColor)
                            .scaleEffect(plusButtonPressed ? 0.95 : 1.0)
                    )
                    .pressEvents(onPress: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            plusButtonPressed = true
                        }
                    }, onRelease: {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            plusButtonPressed = false
                        }
                    })
                }
            }
            
            // Celebration overlay
            if showCelebration {
                CelebrationView()
                    .transition(.opacity)
            }
        }
        .onChange(of: counterStore.count) { newValue in
            if newValue == 500 {
                triggerCelebration()
            }
        }
        .onAppear {
            // Request notification permissions
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                // Handle authorization result if needed
            }
            
            // Monitor Command key state
            NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                isCommandKeyPressed = event.modifierFlags.contains(.command)
                return event
            }
            
            // Accessibility permission check removed - desktop-level windows don't need it for button clicks
        }
    }
    
    private func handleIncrement() {
        // Removed debug prints and notifications to reduce CPU usage
        if isCommandKeyPressed {
            counterStore.incrementRevision()
        } else {
            counterStore.increment()
        }
    }
    
    private func handleDecrement() {
        // Removed debug prints and notifications to reduce CPU usage
        if isCommandKeyPressed {
            counterStore.decrementRevision()
        } else {
            counterStore.decrement()
        }
    }
    
    // Removed showDebugNotification - was causing unnecessary CPU usage on every click
    
    private func triggerCelebration() {
        showCelebration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                showCelebration = false
            }
        }
    }
    
    private func showAccessibilityNotification() {
        // Use UserNotifications framework for modern notifications
        let content = UNMutableNotificationContent()
        content.title = "Accessibility Permission Required"
        content.body = "Please grant Accessibility permissions in System Settings to use the counter buttons."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "accessibility-required", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// Helper view modifier for press events
struct PressEvents: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        onPress()
                    }
                    .onEnded { _ in
                        onRelease()
                    }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEvents(onPress: onPress, onRelease: onRelease))
    }
}

