//
//  DisplayModels.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import CoreGraphics

// MARK: - Apple Reference Presets

/// Factory and custom reference presets supported by Apple XDR displays
public enum AppleReferencePreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case appleXDR = "com.apple.preset.xdr"
    case appleDisplay = "com.apple.preset.apple-display"
    case photographyP3D65 = "com.apple.preset.photography.p3-d65"
    case designPrintP3D50 = "com.apple.preset.design-print.p3-d50"
    case digitalCinemaP3DCI = "com.apple.preset.cinema.p3-dci"
    case digitalCinemaP3D65 = "com.apple.preset.cinema.p3-d65"
    case hdtvVideoBT709 = "com.apple.preset.hdtv.bt709"
    case ntscVideoBT601 = "com.apple.preset.ntsc.bt601"
    case palSecamBT601 = "com.apple.preset.pal.bt601"
    case internetWebSRGB = "com.apple.preset.web.srgb"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .appleXDR: return "Apple XDR Display (P3-1600 nits)"
        case .appleDisplay: return "Apple Display (P3-500 nits)"
        case .photographyP3D65: return "Photography (P3-D65)"
        case .designPrintP3D50: return "Design & Print (P3-D50)"
        case .digitalCinemaP3DCI: return "Digital Cinema (P3-DCI)"
        case .digitalCinemaP3D65: return "Digital Cinema (P3-D65)"
        case .hdtvVideoBT709: return "HDTV Video (BT.709-BT.1886)"
        case .ntscVideoBT601: return "NTSC Video (BT.601 SMPTE-C)"
        case .palSecamBT601: return "PAL & SECAM Video (BT.601 EBU)"
        case .internetWebSRGB: return "Internet & Web (sRGB)"
        }
    }

    /// Nominal SDR calibrated luminance target (in nits / cd/m²)
    public var nominalSDRLuminance: Float {
        switch self {
        case .appleXDR: return 500.0
        case .appleDisplay: return 500.0
        case .photographyP3D65: return 160.0
        case .designPrintP3D50: return 160.0
        case .digitalCinemaP3DCI: return 48.0
        case .digitalCinemaP3D65: return 48.0
        case .hdtvVideoBT709: return 100.0
        case .ntscVideoBT601: return 100.0
        case .palSecamBT601: return 100.0
        case .internetWebSRGB: return 100.0
        }
    }

    /// Whether this preset imposes a strict hardware luminance lock
    public var hasHardwareLuminanceLock: Bool {
        switch self {
        case .appleXDR, .appleDisplay:
            return false
        case .photographyP3D65, .designPrintP3D50, .digitalCinemaP3DCI,
             .digitalCinemaP3D65, .hdtvVideoBT709, .ntscVideoBT601,
             .palSecamBT601, .internetWebSRGB:
            return true
        }
    }
}

// MARK: - Calibration Mode

public enum CalibrationTarget: Codable, Equatable, Sendable {
    /// Apple industry standard calibration: 100 nits for XDR, 50% (~120 nits) for standard Apple screens
    case appleRecommended
    /// Fixed custom luminance target in nits
    case fixedNits(Float)
    /// Manual percentage slider (0.0 ... 1.0)
    case sliderPercent(Float)
}

// MARK: - Display Info

public struct DisplayInfo: Identifiable, Codable, Equatable, Sendable {
    public let id: CGDirectDisplayID
    public var uuid: String
    public var name: String
    public var isBuiltin: Bool
    public var isXDR: Bool
    public var isAppleDisplay: Bool
    public var supportsAppleReferencePresets: Bool
    public var supportsDDC: Bool
    public var isManagementEnabled: Bool
    public var currentBrightness: Float
    public var activeReferencePreset: AppleReferencePreset?
    public var activeColorProfileName: String?

    public init(
        id: CGDirectDisplayID,
        uuid: String = UUID().uuidString,
        name: String,
        isBuiltin: Bool,
        isXDR: Bool,
        isAppleDisplay: Bool,
        supportsAppleReferencePresets: Bool = false,
        supportsDDC: Bool = false,
        isManagementEnabled: Bool = true,
        currentBrightness: Float = 0.5,
        activeReferencePreset: AppleReferencePreset? = nil,
        activeColorProfileName: String? = nil
    ) {
        self.id = id
        self.uuid = uuid
        self.name = name
        self.isBuiltin = isBuiltin
        self.isXDR = isXDR
        self.isAppleDisplay = isAppleDisplay
        self.supportsAppleReferencePresets = supportsAppleReferencePresets
        self.supportsDDC = supportsDDC
        self.isManagementEnabled = isManagementEnabled
        self.currentBrightness = currentBrightness
        self.activeReferencePreset = activeReferencePreset
        self.activeColorProfileName = activeColorProfileName
    }
}

// MARK: - DDC VCP Opcodes

public enum DDCVcpCode: UInt8, Sendable {
    case factoryReset = 0x04
    case luminance = 0x10
    case contrast = 0x12
    case colorPreset = 0x14
    case powerMode = 0xD6

    // Standard VCP 0x14 preset values
    public enum ColorPresetValue: UInt16, Sendable {
        case sRGB = 0x01
        case displayP3 = 0x02
        case dciP3 = 0x03
        case colorTemp5000K = 0x04
        case colorTemp6500K = 0x05
        case colorTemp7500K = 0x06
        case colorTemp9300K = 0x08
        case adobeRGB = 0x09
        case userPreset1 = 0x0B
    }
}

// MARK: - Per-App Granular Action Toggles

public struct PerAppActionConfig: Codable, Equatable, Sendable {
    public var manageTrueTone: Bool?
    public var manageNightShift: Bool?
    public var manageAutoBrightness: Bool?
    public var calibrationTarget: CalibrationTarget?
    public var targetReferencePreset: AppleReferencePreset?
    public var targetColorProfileName: String?
    public var customReversionTimer: TimeInterval?
    public var targetDisplayIDs: [CGDirectDisplayID]?
    public var isWebTarget: Bool
    public var urlPattern: String?
    public var windowTitlePattern: String?

    public init(
        manageTrueTone: Bool? = nil,
        manageNightShift: Bool? = nil,
        manageAutoBrightness: Bool? = nil,
        calibrationTarget: CalibrationTarget? = nil,
        targetReferencePreset: AppleReferencePreset? = nil,
        targetColorProfileName: String? = nil,
        customReversionTimer: TimeInterval? = nil,
        targetDisplayIDs: [CGDirectDisplayID]? = nil,
        isWebTarget: Bool = false,
        urlPattern: String? = nil,
        windowTitlePattern: String? = nil
    ) {
        self.manageTrueTone = manageTrueTone
        self.manageNightShift = manageNightShift
        self.manageAutoBrightness = manageAutoBrightness
        self.calibrationTarget = calibrationTarget
        self.targetReferencePreset = targetReferencePreset
        self.targetColorProfileName = targetColorProfileName
        self.customReversionTimer = customReversionTimer
        self.targetDisplayIDs = targetDisplayIDs
        self.isWebTarget = isWebTarget
        self.urlPattern = urlPattern
        self.windowTitlePattern = windowTitlePattern
    }
}

// MARK: - Ambient Light Sensor Reading

public struct AmbientLightReading: Codable, Equatable, Sendable {
    public let lux: Double
    public let timestamp: Date
    public let rawLeft: Double
    public let rawRight: Double

    public init(lux: Double, timestamp: Date = Date(), rawLeft: Double = 0, rawRight: Double = 0) {
        self.lux = lux
        self.timestamp = timestamp
        self.rawLeft = rawLeft
        self.rawRight = rawRight
    }
}
