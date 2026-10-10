//
//  ColorSyncController.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import CoreGraphics
import ColorSync

// MARK: - ColorSync Protocol

public protocol ColorSyncControllerProtocol: Sendable {
    func getCurrentProfileName(for displayID: CGDirectDisplayID) async -> String?
    func setProfile(named profileName: String, for displayID: CGDirectDisplayID) async throws
    func restoreOriginalProfile(for displayID: CGDirectDisplayID) async throws
    func availableStandardProfiles() async -> [String]
}

// MARK: - ColorSync Controller

public actor ColorSyncController: ColorSyncControllerProtocol {
    public static let shared = ColorSyncController()

    /// Standard & User custom ICC profile search paths (including external probes & calibration tools)
    private var profileSearchDirs: [String] {
        let home = NSHomeDirectory()
        return [
            "\(home)/Library/ColorSync/Profiles",
            "\(home)/Library/ColorSync/Profiles/Displays",
            "/Library/ColorSync/Profiles",
            "/Library/ColorSync/Profiles/Displays",
            "/System/Library/ColorSync/Profiles",
            "/System/Library/ColorSync/Profiles/Displays"
        ]
    }

    /// Mapping of Display ID to original profile URL before creative mode switch
    private var originalProfiles: [CGDirectDisplayID: CFURL] = [:]

    public init() {}

    // MARK: - Standard Profiles

    public func availableStandardProfiles() -> [String] {
        var profileNames: [String] = ["sRGB", "Display P3", "Adobe RGB (1998)", "Rec. 709", "Rec. 2020"]
        let fileManager = FileManager.default

        for dir in profileSearchDirs {
            guard let contents = try? fileManager.contentsOfDirectory(atPath: dir) else { continue }
            for file in contents where file.hasSuffix(".icc") || file.hasSuffix(".icm") {
                let name = (file as NSString).deletingPathExtension
                if !profileNames.contains(name) {
                    profileNames.append(name)
                }
            }
        }
        return profileNames.sorted()
    }

    /// Resolves the file URL for a profile by name
    public func resolveProfileURL(named profileName: String) -> URL? {
        let fileManager = FileManager.default
        let searchCandidates = [
            "\(profileName).icc",
            "\(profileName).icm",
            profileName
        ]

        for dir in profileSearchDirs {
            for candidate in searchCandidates {
                let fullPath = (dir as NSString).appendingPathComponent(candidate)
                if fileManager.fileExists(atPath: fullPath) {
                    return URL(fileURLWithPath: fullPath)
                }
            }
        }

        // Direct standard aliases
        switch profileName.lowercased() {
        case "srgb":
            return resolveProfileURL(named: "sRGB Profile")
        case "display p3", "p3":
            return resolveProfileURL(named: "Display P3")
        case "adobe rgb", "adobergb1998", "adobe rgb 1998":
            return resolveProfileURL(named: "AdobeRGB1998")
        default:
            return nil
        }
    }

    // MARK: - Profile Management

    public func getCurrentProfileName(for displayID: CGDirectDisplayID) -> String? {
        guard let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return nil
        }

        guard let profileInfo = ColorSyncDeviceCopyDeviceInfo(deviceClass, cfUUID) as? [CFString: Any] else {
            return nil
        }

        let customKey = kColorSyncCustomProfiles.takeUnretainedValue()
        let defaultKey = kColorSyncDeviceDefaultProfileID.takeUnretainedValue()
        let factoryKey = kColorSyncFactoryProfiles.takeUnretainedValue()

        if let customProfiles = profileInfo[customKey] as? [CFString: Any],
           let currentURL = customProfiles[defaultKey] as? URL {
            return currentURL.deletingPathExtension().lastPathComponent
        }

        if let factoryProfiles = profileInfo[factoryKey] as? [CFString: Any],
           let defaultURL = factoryProfiles[defaultKey] as? URL {
            return defaultURL.deletingPathExtension().lastPathComponent
        }

        return nil
    }

    public func setProfile(named profileName: String, for displayID: CGDirectDisplayID) throws {
        guard let profileURL = resolveProfileURL(named: profileName) else {
            throw ColorSyncError.profileNotFound(profileName)
        }

        guard let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            throw ColorSyncError.deviceUnavailable(displayID)
        }

        let customKey = kColorSyncCustomProfiles.takeUnretainedValue()
        let defaultKey = kColorSyncDeviceDefaultProfileID.takeUnretainedValue()
        let factoryKey = kColorSyncFactoryProfiles.takeUnretainedValue()

        // Save original profile before changing if not already saved
        if originalProfiles[displayID] == nil {
            if let info = ColorSyncDeviceCopyDeviceInfo(deviceClass, cfUUID) as? [CFString: Any] {
                if let customProfiles = info[customKey] as? [CFString: Any],
                   let currentURL = customProfiles[defaultKey] as? URL {
                    originalProfiles[displayID] = currentURL as CFURL
                } else if let factoryProfiles = info[factoryKey] as? [CFString: Any],
                          let defaultURL = factoryProfiles[defaultKey] as? URL {
                    originalProfiles[displayID] = defaultURL as CFURL
                }
            }
        }

        // Apply custom profile
        let profileDictionary: [CFString: Any] = [
            defaultKey: profileURL as CFURL
        ]

        let success = ColorSyncDeviceSetCustomProfiles(
            deviceClass,
            cfUUID,
            profileDictionary as CFDictionary
        )

        if !success {
            throw ColorSyncError.setProfileFailed("Failed to set profile \(profileName) for display \(displayID)")
        }
    }

    public func restoreOriginalProfile(for displayID: CGDirectDisplayID) throws {
        guard let originalURL = originalProfiles.removeValue(forKey: displayID) else {
            return
        }

        guard let deviceClass = kColorSyncDisplayDeviceClass?.takeUnretainedValue(),
              let cfUUID = CGDisplayCreateUUIDFromDisplayID(displayID)?.takeRetainedValue() else {
            return
        }

        let defaultKey = kColorSyncDeviceDefaultProfileID.takeUnretainedValue()
        let profileDictionary: [CFString: Any] = [
            defaultKey: originalURL
        ]

        _ = ColorSyncDeviceSetCustomProfiles(
            deviceClass,
            cfUUID,
            profileDictionary as CFDictionary
        )
    }
}

// MARK: - Mock ColorSync Controller (For Unit Testing)

public actor MockColorSyncController: ColorSyncControllerProtocol {
    private var activeProfiles: [CGDirectDisplayID: String] = [:]
    private var originalProfiles: [CGDirectDisplayID: String] = [:]
    public var availableProfiles: [String] = ["sRGB", "Display P3", "Adobe RGB (1998)", "Rec. 709", "Calibrated-SpyderX-D65", "Calibrite-Display-WideGamut"]

    public init() {}

    public func getCurrentProfileName(for displayID: CGDirectDisplayID) -> String? {
        activeProfiles[displayID] ?? "Display P3"
    }

    public func setProfile(named profileName: String, for displayID: CGDirectDisplayID) throws {
        if originalProfiles[displayID] == nil {
            originalProfiles[displayID] = activeProfiles[displayID] ?? "Display P3"
        }
        activeProfiles[displayID] = profileName
    }

    public func restoreOriginalProfile(for displayID: CGDirectDisplayID) throws {
        if let original = originalProfiles.removeValue(forKey: displayID) {
            activeProfiles[displayID] = original
        }
    }

    public func availableStandardProfiles() -> [String] {
        availableProfiles
    }
}

// MARK: - Errors

public enum ColorSyncError: Error, LocalizedError, Equatable {
    case profileNotFound(String)
    case deviceUnavailable(CGDirectDisplayID)
    case setProfileFailed(String)

    public var errorDescription: String? {
        switch self {
        case .profileNotFound(let name):
            return "ColorSync profile '\(name)' was not found."
        case .deviceUnavailable(let id):
            return "Display device '\(id)' could not be accessed in ColorSync."
        case .setProfileFailed(let reason):
            return "ColorSync error: \(reason)"
        }
    }
}
