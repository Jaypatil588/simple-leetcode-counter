# LeetCode Counter Wallpaper

A macOS desktop overlay application that displays a LeetCode problem counter (n/500) as a wallpaper overlay. The counter appears behind all windows and persists across reboots.

## Features

- **Desktop Overlay**: Counter appears behind all windows at desktop level
- **Multi-Monitor Support**: Displays on all connected monitors
- **Persistent Counter**: Saves counter value with backup system
- **Auto-Launch**: Automatically starts on system boot and wake from sleep
- **Accessibility Integration**: Buttons require Accessibility permissions
- **Celebration**: Confetti animation when reaching 500 problems
- **Theme Support**: Dark theme (modifiable for future customization)

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later
- Accessibility permissions (granted in System Settings)

## Building the Project

1. Open `LeetcodeCounter.xcodeproj` in Xcode
2. Select the "LeetcodeCounter" scheme
3. Build the project (⌘B) or Run (⌘R)

## Installation

1. Build the project in Xcode
2. The app will be created in `DerivedData` or you can Archive and export it
3. Move the app to `/Applications` or your preferred location
4. Grant Accessibility permissions:
   - Open System Settings → Privacy & Security → Accessibility
   - Enable "LeetcodeCounter"
5. Launch the app

## Usage

- **+ Button**: Increment the counter
- **- Button**: Decrement the counter
- The counter can go negative or above 500
- When you reach exactly 500, a celebration animation will appear

## Auto-Launch Setup

The app attempts to set up a Launch Agent automatically. If this fails, you'll see instructions for manual setup.

To manually set up auto-launch:

1. Create a Launch Agent plist file at `~/Library/LaunchAgents/com.leetcode.counter.plist`
2. Use the template provided in the setup guide dialog
3. Run `launchctl load ~/Library/LaunchAgents/com.leetcode.counter.plist`

## Troubleshooting

### Buttons Not Working
- Ensure Accessibility permissions are granted in System Settings
- Restart the app after granting permissions

### Window Not Visible
- The app will automatically retry with different window levels
- Check Console.app for any error messages

### Counter Resets
- The app has a backup system that should restore the value
- Check UserDefaults for `leetcodeCounter` and `leetcodeCounterBackup` keys

## Project Structure

```
LeetcodeCounter/
├── LeetcodeCounterApp.swift          # App entry point
├── CounterStore.swift                # Counter state & persistence
├── CounterView.swift                 # Main UI
├── DesktopOverlayWindow.swift        # Window management
├── LaunchAgentManager.swift          # Auto-launch setup
├── AccessibilityManager.swift        # Permission handling
├── ThemeManager.swift                # Theme system
├── CelebrationView.swift             # Celebration animation
├── Info.plist                        # App configuration
└── LeetcodeCounter.entitlements      # App entitlements
```

## Notes

- App Sandbox is **disabled** (required for desktop-level windows)
- The app runs as a background application (LSUIElement = true)
- Counter value is stored in UserDefaults
- The app prevents multiple instances from running simultaneously

