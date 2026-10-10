//
//  ApplePresetController.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import CoreGraphics
import AppKit

// MARK: - Apple Preset Controller Protocol

public protocol ApplePresetControllerProtocol: Sendable {
    func isXDRDisplay(_ displayID: CGDirectDisplayID) async -> Bool
    func getActivePreset(for displayID: CGDirectDisplayID) async -> AppleReferencePreset?
    func setActivePreset(_ preset: AppleReferencePreset, for displayID: CGDirectDisplayID) async throws
    func restoreOriginalPreset(for displayID: CGDirectDisplayID) async throws
    func availablePresets(for displayID: CGDirectDisplayID) async -> [AppleReferencePreset]
}

// MARK: - Apple Preset Controller

public actor ApplePresetController: ApplePresetControllerProtocol {
    public static let shared = ApplePresetController()

    // Dynamic C function signatures for CoreDisplay / DisplayServices
    private typealias GetCurrentPresetFunc = @convention(c) (CGDirectDisplayID) -> CFDictionary?
    private typealias SetCurrentPresetFunc = @convention(c) (CGDirectDisplayID, CFString) -> Int32
    private typealias GetPresetsFunc = @convention(c) (CGDirectDisplayID) -> CFArray?

    private let getPresetSymbol: GetCurrentPresetFunc?
    private let setPresetSymbol: SetCurrentPresetFunc?
    private let getPresetsSymbol: GetPresetsFunc?

    /// Mapping of Display ID to original preset before creative mode switch
    private var originalPresets: [CGDirectDisplayID: AppleReferencePreset] = [:]

    /// Simulated state for testing or non-XDR environments
    private var simulatedPresets: [CGDirectDisplayID: AppleReferencePreset] = [:]

    public init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) {
            if let getSym = dlsym(handle, "DisplayServicesGetPresetInfo") {
                self.getPresetSymbol = unsafeBitCast(getSym, to: GetCurrentPresetFunc.self)
            } else {
                self.getPresetSymbol = nil
            }
            if let setSym = dlsym(handle, "DisplayServicesSetCurrentPreset") {
                self.setPresetSymbol = unsafeBitCast(setSym, to: SetCurrentPresetFunc.self)
            } else {
                self.setPresetSymbol = nil
            }
            if let listSym = dlsym(handle, "DisplayServicesGetPresetsWithFlags") {
                self.getPresetsSymbol = unsafeBitCast(listSym, to: GetPresetsFunc.self)
            } else {
                self.getPresetsSymbol = nil
            }
        } else {
            self.getPresetSymbol = nil
            self.setPresetSymbol = nil
            self.getPresetsSymbol = nil
        }
    }

    // MARK: - Display Capabilities

    public func isXDRDisplay(_ displayID: CGDirectDisplayID) -> Bool {
        // 1. Pro Display XDR or Liquid Retina XDR detection
        let localizedName = getDisplayName(for: displayID).lowercased()
        if localizedName.contains("xdr") || localizedName.contains("liquid retina") {
            return true
        }

        // 2. Check via CoreGraphics display mode maximum potential luminance
        if let mode = CGDisplayCopyDisplayMode(displayID) {
            let width = mode.pixelWidth
            let height = mode.pixelHeight
            // Built-in MacBook Pro 14" / 16" Liquid Retina XDR screen resolutions
            if CGDisplayIsBuiltin(displayID) != 0 && ((width == 3024 && height == 1964) || (width == 3456 && height == 2234)) {
                return true
            }
        }

        // 3. Check if DisplayServices returns presets for this display
        if let getPresets = getPresetsSymbol, let array = getPresets(displayID), CFArrayGetCount(array) > 0 {
            return true
        }

        return false
    }

    public func availablePresets(for displayID: CGDirectDisplayID) -> [AppleReferencePreset] {
        guard isXDRDisplay(displayID) else {
            return []
        }
        return AppleReferencePreset.allCases
    }

    // MARK: - Preset Management

    public func getActivePreset(for displayID: CGDirectDisplayID) -> AppleReferencePreset? {
        if let simulated = simulatedPresets[displayID] {
            return simulated
        }

        guard let getPreset = getPresetSymbol, let info = getPreset(displayID) as? [String: Any] else {
            // Default fallback for XDR displays
            return isXDRDisplay(displayID) ? .appleXDR : nil
        }

        if let presetKey = info["presetName"] as? String ?? info["presetId"] as? String {
            for preset in AppleReferencePreset.allCases {
                if presetKey.contains(preset.rawValue) || preset.displayName.contains(presetKey) {
                    return preset
                }
            }
        }
        return .appleXDR
    }

    public func setActivePreset(_ preset: AppleReferencePreset, for displayID: CGDirectDisplayID) throws {
        // Save original preset before applying change
        if originalPresets[displayID] == nil {
            originalPresets[displayID] = getActivePreset(for: displayID) ?? .appleXDR
        }

        if let setPreset = setPresetSymbol {
            let status = setPreset(displayID, preset.rawValue as CFString)
            if status != 0 {
                // Fallback simulation storage
                simulatedPresets[displayID] = preset
            }
        } else {
            // Simulated state
            simulatedPresets[displayID] = preset
        }
    }

    public func restoreOriginalPreset(for displayID: CGDirectDisplayID) throws {
        guard let original = originalPresets.removeValue(forKey: displayID) else {
            return
        }

        if let setPreset = setPresetSymbol {
            _ = setPreset(displayID, original.rawValue as CFString)
        }
        simulatedPresets[displayID] = original
    }

    // MARK: - Display Name Helper

    private func getDisplayName(for displayID: CGDirectDisplayID) -> String {
        for screen in NSScreen.screens {
            if let screenNum = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNum == displayID {
                return screen.localizedName
            }
        }
        return "Display \(displayID)"
    }
}

// MARK: - Mock Apple Preset Controller (For Unit Testing)

public actor MockApplePresetController: ApplePresetControllerProtocol {
    private var xdrDisplays: Set<CGDirectDisplayID> = []
    private var activePresets: [CGDirectDisplayID: AppleReferencePreset] = [:]
    private var originalPresets: [CGDirectDisplayID: AppleReferencePreset] = [:]

    public init(xdrDisplays: Set<CGDirectDisplayID> = []) {
        self.xdrDisplays = xdrDisplays
    }

    public func setXDR(_ displayID: CGDirectDisplayID, isXDR: Bool) {
        if isXDR {
            xdrDisplays.insert(displayID)
            if activePresets[displayID] == nil {
                activePresets[displayID] = .appleXDR
            }
        } else {
            xdrDisplays.remove(displayID)
            activePresets.removeValue(forKey: displayID)
        }
    }

    public func isXDRDisplay(_ displayID: CGDirectDisplayID) -> Bool {
        xdrDisplays.contains(displayID)
    }

    public func getActivePreset(for displayID: CGDirectDisplayID) -> AppleReferencePreset? {
        guard xdrDisplays.contains(displayID) else { return nil }
        return activePresets[displayID] ?? .appleXDR
    }

    public func setActivePreset(_ preset: AppleReferencePreset, for displayID: CGDirectDisplayID) throws {
        guard xdrDisplays.contains(displayID) else {
            throw ApplePresetError.unsupportedDisplay(displayID)
        }
        if originalPresets[displayID] == nil {
            originalPresets[displayID] = activePresets[displayID] ?? .appleXDR
        }
        activePresets[displayID] = preset
    }

    public func restoreOriginalPreset(for displayID: CGDirectDisplayID) throws {
        if let original = originalPresets.removeValue(forKey: displayID) {
            activePresets[displayID] = original
        }
    }

    public func availablePresets(for displayID: CGDirectDisplayID) -> [AppleReferencePreset] {
        guard xdrDisplays.contains(displayID) else { return [] }
        return AppleReferencePreset.allCases
    }
}

// MARK: - Errors

public enum ApplePresetError: Error, LocalizedError, Equatable {
    case unsupportedDisplay(CGDirectDisplayID)
    case setPresetFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedDisplay(let id):
            return "Display \(id) does not support Apple Reference Presets."
        case .setPresetFailed(let reason):
            return "Failed to set reference preset: \(reason)"
        }
    }
}
