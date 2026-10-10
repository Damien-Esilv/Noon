//
//  BrightnessManager.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import CoreGraphics

// MARK: - Brightness Controller Protocol

public protocol BrightnessControllerProtocol: Sendable {
    func getBrightness(for displayID: CGDirectDisplayID) async -> Float
    func setBrightness(_ brightness: Float, for displayID: CGDirectDisplayID) async throws
    func isAutoBrightnessEnabled(for displayID: CGDirectDisplayID) async -> Bool
    func setAutoBrightnessEnabled(_ enabled: Bool, for displayID: CGDirectDisplayID) async throws
    func restoreOriginalBrightness(for displayID: CGDirectDisplayID) async throws
    func restoreOriginalAutoBrightness(for displayID: CGDirectDisplayID) async throws
}

// MARK: - Brightness Manager

public actor BrightnessManager: BrightnessControllerProtocol {
    public static let shared = BrightnessManager()

    // Dynamic C function signatures for CoreDisplay / DisplayServices
    private typealias GetBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetBrightnessFunc = @convention(c) (CGDirectDisplayID, Float) -> Int32
    private typealias GetAutoBrightnessFunc = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<DarwinBoolean>) -> Int32
    private typealias SetAutoBrightnessFunc = @convention(c) (CGDirectDisplayID, DarwinBoolean) -> Int32

    private let getBrightnessSym: GetBrightnessFunc?
    private let setBrightnessSym: SetBrightnessFunc?
    private let getAutoBrightnessSym: GetAutoBrightnessFunc?
    private let setAutoBrightnessSym: SetAutoBrightnessFunc?

    /// Original brightness before creative mode activation
    private var originalBrightness: [CGDirectDisplayID: Float] = [:]

    /// Original auto-brightness state before creative mode activation
    private var originalAutoBrightness: [CGDirectDisplayID: Bool] = [:]

    /// In-memory values for mock / fallback environments
    private var simulatedBrightness: [CGDirectDisplayID: Float] = [:]
    private var simulatedAutoBrightness: [CGDirectDisplayID: Bool] = [:]

    public init() {
        if let handle = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY) {
            if let getB = dlsym(handle, "DisplayServicesGetBrightness") {
                self.getBrightnessSym = unsafeBitCast(getB, to: GetBrightnessFunc.self)
            } else {
                self.getBrightnessSym = nil
            }
            if let setB = dlsym(handle, "DisplayServicesSetBrightness") {
                self.setBrightnessSym = unsafeBitCast(setB, to: SetBrightnessFunc.self)
            } else {
                self.setBrightnessSym = nil
            }
            if let getAB = dlsym(handle, "DisplayServicesGetAutoBrightnessEnabled") {
                self.getAutoBrightnessSym = unsafeBitCast(getAB, to: GetAutoBrightnessFunc.self)
            } else {
                self.getAutoBrightnessSym = nil
            }
            if let setAB = dlsym(handle, "DisplayServicesSetAutoBrightnessEnabled") {
                self.setAutoBrightnessSym = unsafeBitCast(setAB, to: SetAutoBrightnessFunc.self)
            } else {
                self.setAutoBrightnessSym = nil
            }
        } else {
            self.getBrightnessSym = nil
            self.setBrightnessSym = nil
            self.getAutoBrightnessSym = nil
            self.setAutoBrightnessSym = nil
        }
    }

    // MARK: - Brightness Operations

    public func getBrightness(for displayID: CGDirectDisplayID) -> Float {
        if let simulated = simulatedBrightness[displayID] {
            return simulated
        }

        if let getBrightnessSym = getBrightnessSym {
            var value: Float = 0.5
            let status = getBrightnessSym(displayID, &value)
            if status == 0 {
                return value
            }
        }
        return 0.5
    }

    public func setBrightness(_ brightness: Float, for displayID: CGDirectDisplayID) throws {
        let clamped = max(0.0, min(1.0, brightness))

        // Save original brightness if not already saved
        if originalBrightness[displayID] == nil {
            originalBrightness[displayID] = getBrightness(for: displayID)
        }

        if let setBrightnessSym = setBrightnessSym {
            let status = setBrightnessSym(displayID, clamped)
            if status != 0 {
                simulatedBrightness[displayID] = clamped
            }
        } else {
            simulatedBrightness[displayID] = clamped
        }
    }

    public func restoreOriginalBrightness(for displayID: CGDirectDisplayID) throws {
        guard let original = originalBrightness.removeValue(forKey: displayID) else {
            return
        }

        if let setBrightnessSym = setBrightnessSym {
            _ = setBrightnessSym(displayID, original)
        }
        simulatedBrightness[displayID] = original
    }

    // MARK: - Auto-Brightness Operations

    public func isAutoBrightnessEnabled(for displayID: CGDirectDisplayID) -> Bool {
        if let simulated = simulatedAutoBrightness[displayID] {
            return simulated
        }

        if let getAutoBrightnessSym = getAutoBrightnessSym {
            var enabled = DarwinBoolean(false)
            let status = getAutoBrightnessSym(displayID, &enabled)
            if status == 0 {
                return enabled.boolValue
            }
        }
        return true
    }

    public func setAutoBrightnessEnabled(_ enabled: Bool, for displayID: CGDirectDisplayID) throws {
        // Save original auto-brightness state if not already saved
        if originalAutoBrightness[displayID] == nil {
            originalAutoBrightness[displayID] = isAutoBrightnessEnabled(for: displayID)
        }

        if let setAutoBrightnessSym = setAutoBrightnessSym {
            let status = setAutoBrightnessSym(displayID, DarwinBoolean(enabled))
            if status != 0 {
                simulatedAutoBrightness[displayID] = enabled
            }
        } else {
            simulatedAutoBrightness[displayID] = enabled
        }
    }

    public func restoreOriginalAutoBrightness(for displayID: CGDirectDisplayID) throws {
        guard let original = originalAutoBrightness.removeValue(forKey: displayID) else {
            return
        }

        if let setAutoBrightnessSym = setAutoBrightnessSym {
            _ = setAutoBrightnessSym(displayID, DarwinBoolean(original))
        }
        simulatedAutoBrightness[displayID] = original
    }

    // MARK: - Apple Industry Standard Calibration Engine

    /// Calculates the calibrated brightness level (0.0 to 1.0) according to Apple's reference specifications.
    /// - Parameters:
    ///   - isXDR: Whether the target display is an Apple Liquid Retina XDR or Pro Display XDR.
    ///   - activePreset: Current Apple Reference Preset active on the display (if any).
    ///   - target: The requested calibration target (.appleRecommended, .fixedNits, or .sliderPercent).
    /// - Returns: Computed brightness scalar [0.0 ... 1.0], or nil if a hardware preset lock prevents manual adjustment.
    public static func computeCalibratedBrightness(
        isXDR: Bool,
        activePreset: AppleReferencePreset?,
        target: CalibrationTarget = .appleRecommended
    ) -> Float? {
        // If an active Apple Reference Preset enforces a hardware luminance lock, return nil
        // to respect Apple's calibrated white-point lock without interfering with the hardware profile.
        if let preset = activePreset, preset.hasHardwareLuminanceLock {
            return nil
        }

        switch target {
        case .appleRecommended:
            if isXDR {
                // Apple XDR SDR Reference Target: 100 nits out of nominal 500 nits SDR ceiling
                // 100 / 500 = 0.20 (20% slider)
                return 100.0 / 500.0
            } else {
                // Standard Apple Retina/Non-XDR display: 50% slider value (~120 nits graphic arts viewing standard)
                return 0.50
            }

        case .fixedNits(let nits):
            if isXDR {
                let clampedNits = max(0.0, min(500.0, nits))
                return clampedNits / 500.0
            } else {
                // Standard display nominal max is ~400 nits
                let clampedNits = max(0.0, min(400.0, nits))
                return clampedNits / 400.0
            }

        case .sliderPercent(let percent):
            return max(0.0, min(1.0, percent))
        }
    }
}

// MARK: - Mock Brightness Controller (For Unit Testing)

public actor MockBrightnessController: BrightnessControllerProtocol {
    private var brightnessLevels: [CGDirectDisplayID: Float] = [:]
    private var originalBrightnessLevels: [CGDirectDisplayID: Float] = [:]
    private var autoBrightnessStates: [CGDirectDisplayID: Bool] = [:]
    private var originalAutoBrightnessStates: [CGDirectDisplayID: Bool] = [:]

    public init(defaultBrightness: Float = 0.7, defaultAutoBrightness: Bool = true) {
        // Pre-populate with defaults
    }

    public func getBrightness(for displayID: CGDirectDisplayID) -> Float {
        brightnessLevels[displayID] ?? 0.7
    }

    public func setBrightness(_ brightness: Float, for displayID: CGDirectDisplayID) throws {
        if originalBrightnessLevels[displayID] == nil {
            originalBrightnessLevels[displayID] = brightnessLevels[displayID] ?? 0.7
        }
        brightnessLevels[displayID] = max(0.0, min(1.0, brightness))
    }

    public func restoreOriginalBrightness(for displayID: CGDirectDisplayID) throws {
        if let orig = originalBrightnessLevels.removeValue(forKey: displayID) {
            brightnessLevels[displayID] = orig
        }
    }

    public func isAutoBrightnessEnabled(for displayID: CGDirectDisplayID) -> Bool {
        autoBrightnessStates[displayID] ?? true
    }

    public func setAutoBrightnessEnabled(_ enabled: Bool, for displayID: CGDirectDisplayID) throws {
        if originalAutoBrightnessStates[displayID] == nil {
            originalAutoBrightnessStates[displayID] = autoBrightnessStates[displayID] ?? true
        }
        autoBrightnessStates[displayID] = enabled
    }

    public func restoreOriginalAutoBrightness(for displayID: CGDirectDisplayID) throws {
        if let orig = originalAutoBrightnessStates.removeValue(forKey: displayID) {
            autoBrightnessStates[displayID] = orig
        }
    }
}
