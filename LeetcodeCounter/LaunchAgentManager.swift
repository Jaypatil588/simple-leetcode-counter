//
//  LaunchAgentManager.swift
//  LeetcodeCounter
//
//  Manages Launch Agent for auto-launch on boot
//

import Foundation
import AppKit

class LaunchAgentManager {
    private let agentName = "com.leetcode.counter"
    private let agentFileName = "com.leetcode.counter.plist"
    
    func setupLaunchAgent() -> Bool {
        guard let executableURL = Bundle.main.executableURL else {
            showSetupGuide()
            return false
        }
        
        let executablePath = executableURL.path
        
        let launchAgentsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents")
        
        // Create LaunchAgents directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: launchAgentsDir.path) {
            do {
                try FileManager.default.createDirectory(
                    at: launchAgentsDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                print("Failed to create LaunchAgents directory: \(error)")
                showSetupGuide()
                return false
            }
        }
        
        let plistPath = launchAgentsDir.appendingPathComponent(agentFileName)
        
        // Create plist content
        // KeepAlive is set to false - app should not auto-restart on crash/kill
        let plistContent: [String: Any] = [
            "Label": agentName,
            "ProgramArguments": [executablePath],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        
        // Write plist file
        do {
            let plistData = try PropertyListSerialization.data(
                fromPropertyList: plistContent,
                format: .xml,
                options: 0
            )
            try plistData.write(to: plistPath)
        } catch {
            print("Failed to write Launch Agent plist: \(error)")
            showSetupGuide()
            return false
        }
        
        // Try bootstrap first (modern macOS)
        // Use gui/$(id -u) format for bootstrap - get user ID
        let userID = getuid()
        let bootstrapProcess = Process()
        bootstrapProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        bootstrapProcess.arguments = ["bootstrap", "gui/\(userID)", plistPath.path]
        
        print("🚀 [LaunchAgent] Attempting bootstrap with userID: \(userID)")
        
        do {
            try bootstrapProcess.run()
            bootstrapProcess.waitUntilExit()
            
            if bootstrapProcess.terminationStatus == 0 {
                return true
            }
        } catch {
            // Fall through to try legacy load command
        }
        
        // Fallback to legacy load command for older macOS
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistPath.path]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                return true
            } else {
                showSetupGuide()
                return false
            }
        } catch {
            print("Failed to load Launch Agent: \(error)")
            showSetupGuide()
            return false
        }
    }
    
    private func showSetupGuide() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Launch Agent Setup Failed"
            alert.informativeText = """
            Automatic launch setup failed. To enable auto-launch on boot:
            
            1. Open Terminal
            2. Run the following commands:
            
            cat > ~/Library/LaunchAgents/\(self.agentFileName) << 'EOF'
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(self.agentName)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(Bundle.main.executableURL?.path ?? "")</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
                <key>KeepAlive</key>
                <false/>
            </dict>
            </plist>
            EOF
            
            launchctl load ~/Library/LaunchAgents/\(self.agentFileName)
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

