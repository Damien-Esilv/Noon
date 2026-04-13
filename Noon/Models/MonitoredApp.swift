//
//  MonitoredApp.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import AppKit

struct MonitoredApp: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var bundleIdentifier: String
    var path: String
    
    /// Check if the application still exists at its registered path
    var isValid: Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    /// Attempt to retrieve the app's icon from its bundle
    var icon: NSImage? {
        guard isValid else { return nil }
        return NSWorkspace.shared.icon(forFile: path)
    }
    
    /// Attempt to find the app even if the path changed (e.g. version update)
    var resolvedPath: String? {
        if isValid { return path }
        // Try to find via bundle identifier in /Applications
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return url.path
        }
        return nil
    }
    
    /// Check if this app is currently running
    var isRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleIdentifier }
    }
    
    init(name: String, bundleIdentifier: String, path: String? = nil) {
        self.id = UUID()
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        
        if let p = path {
            self.path = p
        } else if let resolved = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)?.path {
            self.path = resolved
        } else {
            self.path = "/Applications/\(name).app"
        }
    }
    
    // MARK: - Hashable
    
    static func == (lhs: MonitoredApp, rhs: MonitoredApp) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Codable (exclude computed properties)
    
    enum CodingKeys: String, CodingKey {
        case id, name, bundleIdentifier, path
    }
    
    // MARK: - Default Suggestions
    
    static let suggestions: [MonitoredApp] = [
        MonitoredApp(name: "Adobe Photoshop", bundleIdentifier: "com.adobe.Photoshop"),
        MonitoredApp(name: "Adobe Lightroom Classic", bundleIdentifier: "com.adobe.LightroomClassicCC7"),
        MonitoredApp(name: "Adobe Lightroom (Cloud)", bundleIdentifier: "com.adobe.lightroomCC"),
        MonitoredApp(name: "Lightroom", bundleIdentifier: "com.adobe.lrmac"),
        MonitoredApp(name: "DaVinci Resolve", bundleIdentifier: "com.blackmagic-design.DaVinciResolve"),
        MonitoredApp(name: "Capture One", bundleIdentifier: "com.captureone.captureone"),
        MonitoredApp(name: "Affinity Photo 2", bundleIdentifier: "com.seriflabs.affinityphoto2"),
        MonitoredApp(name: "Final Cut Pro", bundleIdentifier: "com.apple.FinalCut"),
        MonitoredApp(name: "Pixelmator Pro", bundleIdentifier: "com.pixelmatorteam.pixelmator.x"),
    ]
}
