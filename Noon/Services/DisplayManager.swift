//
//  DisplayManager.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import CoreGraphics
import AppKit

@MainActor
@Observable
public final class DisplayManager {
    public static let shared = DisplayManager()

    // MARK: - State

    public private(set) var connectedDisplays: [DisplayInfo] = []
    public private(set) var isCreativeModeActive: Bool = false
    public private(set) var lastError: String?

    // Explicit per-display overrides (persists preferences across reconnects)
    private var managementOverrides: [CGDirectDisplayID: Bool] = [:]

    // MARK: - Dependencies

    private let applePresetController: ApplePresetControllerProtocol
    private let brightnessManager: BrightnessControllerProtocol
    private let colorSyncController: ColorSyncControllerProtocol
    private let ddcTransport: DDCTransportProtocol

    // MARK: - Lifecycle

    public init(
        applePresetController: ApplePresetControllerProtocol = ApplePresetController.shared,
        brightnessManager: BrightnessControllerProtocol = BrightnessManager.shared,
        colorSyncController: ColorSyncControllerProtocol = ColorSyncController.shared,
        ddcTransport: DDCTransportProtocol = NativeDDCTransport()
    ) {
        self.applePresetController = applePresetController
        self.brightnessManager = brightnessManager
        self.colorSyncController = colorSyncController
        self.ddcTransport = ddcTransport

        refreshConnectedDisplays()
    }

    // MARK: - Display Discovery

    public func refreshConnectedDisplays() {
        var activeDisplayCount: UInt32 = 0
        var activeDisplays = [CGDirectDisplayID](repeating: 0, count: 16)
        let err = CGGetActiveDisplayList(16, &activeDisplays, &activeDisplayCount)

        guard err == .success else {
            self.connectedDisplays = []
            return
        }

        var newDisplays: [DisplayInfo] = []

        for i in 0..<Int(activeDisplayCount) {
            let id = activeDisplays[i]
            let isBuiltin = CGDisplayIsBuiltin(id) != 0

            // Resolve friendly screen name
            var name = isBuiltin ? "Liquid Retina Display" : "External Display"
            for screen in NSScreen.screens {
                if let screenNum = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
                   screenNum == id {
                    name = screen.localizedName
                    break
                }
            }

            let isEnabled = managementOverrides[id] ?? AppSettings.shared.isDisplayManagementEnabled(for: id)

            let display = DisplayInfo(
                id: id,
                name: name,
                isBuiltin: isBuiltin,
                isXDR: false,
                isAppleDisplay: isBuiltin,
                supportsAppleReferencePresets: false,
                supportsDDC: !isBuiltin,
                isManagementEnabled: isEnabled,
                currentBrightness: 0.8,
                activeReferencePreset: nil,
                activeColorProfileName: "Color LCD"
            )
            newDisplays.append(display)
        }

        self.connectedDisplays = newDisplays

        // Perform async capability inspection
        Task {
            await inspectCapabilities()
        }
    }

    private func inspectCapabilities() async {
        var updatedDisplays = self.connectedDisplays

        for i in 0..<updatedDisplays.count {
            let id = updatedDisplays[i].id
            let isXDR = await applePresetController.isXDRDisplay(id)
            let activePreset = await applePresetController.getActivePreset(for: id)
            let brightness = await brightnessManager.getBrightness(for: id)
            let profileName = await colorSyncController.getCurrentProfileName(for: id)
            let supportsDDC = await ddcTransport.isSupported(displayID: id)

            updatedDisplays[i].isXDR = isXDR
            updatedDisplays[i].supportsAppleReferencePresets = isXDR
            updatedDisplays[i].activeReferencePreset = activePreset
            updatedDisplays[i].currentBrightness = brightness
            updatedDisplays[i].activeColorProfileName = profileName
            updatedDisplays[i].supportsDDC = supportsDDC
        }

        self.connectedDisplays = updatedDisplays
    }

    // MARK: - Per-Display Configuration

    public func setManagementEnabled(_ enabled: Bool, for displayID: CGDirectDisplayID) {
        managementOverrides[displayID] = enabled
        if let index = connectedDisplays.firstIndex(where: { $0.id == displayID }) {
            connectedDisplays[index].isManagementEnabled = enabled
        }
        AppSettings.shared.setDisplayManagement(enabled, for: displayID)
        
        if isCreativeModeActive && !enabled {
            Task {
                await restoreInterventions(for: displayID)
            }
        }
    }

    public func isManagementEnabled(for displayID: CGDirectDisplayID) -> Bool {
        if let overrideVal = managementOverrides[displayID] {
            return overrideVal
        }
        return AppSettings.shared.isDisplayManagementEnabled(for: displayID)
    }

    public var hasAnyManagedDisplay: Bool {
        if connectedDisplays.isEmpty {
            return isManagementEnabled(for: CGMainDisplayID())
        }
        return connectedDisplays.contains { isManagementEnabled(for: $0.id) }
    }

    public var isTrueToneDisplayManaged: Bool {
        if connectedDisplays.isEmpty {
            return isManagementEnabled(for: CGMainDisplayID())
        }
        let trueToneDisplays = connectedDisplays.filter { $0.isBuiltin || $0.isAppleDisplay }
        if trueToneDisplays.isEmpty {
            return isManagementEnabled(for: CGMainDisplayID())
        }
        return trueToneDisplays.contains { isManagementEnabled(for: $0.id) }
    }

    public var isNightShiftManaged: Bool {
        hasAnyManagedDisplay
    }

    public func restoreInterventions(for displayID: CGDirectDisplayID) async {
        guard let display = connectedDisplays.first(where: { $0.id == displayID }) else { return }
        do {
            if display.isXDR {
                try await applePresetController.restoreOriginalPreset(for: display.id)
            }
            try await colorSyncController.restoreOriginalProfile(for: display.id)
            try await brightnessManager.restoreOriginalAutoBrightness(for: display.id)
            try await brightnessManager.restoreOriginalBrightness(for: display.id)
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    // MARK: - Creative Mode Orchestration

    public func applyCreativeInterventions(
        for config: PerAppActionConfig? = nil
    ) async {
        guard hasAnyManagedDisplay else {
            isCreativeModeActive = false
            return
        }
        isCreativeModeActive = true
        lastError = nil

        let targetIDs = config?.targetDisplayIDs

        for display in connectedDisplays where isManagementEnabled(for: display.id) {
            // If target displays are specified, filter out other displays
            if let targetIDs = targetIDs, !targetIDs.contains(display.id) {
                continue
            }

            do {
                // 1. Apple Reference Preset Switch (for XDR displays)
                if display.isXDR, let targetPreset = config?.targetReferencePreset {
                    try await applePresetController.setActivePreset(targetPreset, for: display.id)
                }

                // 2. ColorSync Profile Switch
                let targetProfile = config?.targetColorProfileName ?? (AppSettings.shared.enableCreativeColorProfile ? AppSettings.shared.calibrationProfile(for: display.id) : nil)
                if let targetProfile = targetProfile, !targetProfile.isEmpty {
                    try await colorSyncController.setProfile(named: targetProfile, for: display.id)
                }

                // 3. Auto-Brightness Lock
                let shouldManageAutoBrightness = config?.manageAutoBrightness ?? true
                if shouldManageAutoBrightness {
                    try await brightnessManager.setAutoBrightnessEnabled(false, for: display.id)
                }

                // 4. Calibrated Luminance / Target Brightness
                if AppSettings.shared.enablePresetBrightness {
                    try await brightnessManager.setBrightness(Float(AppSettings.shared.presetBrightnessLevel), for: display.id)
                } else if AppSettings.shared.lock100NitsCalibration {
                    let calibration = config?.calibrationTarget ?? .appleRecommended
                    if let computedBrightness = BrightnessManager.computeCalibratedBrightness(
                        isXDR: display.isXDR,
                        activePreset: display.activeReferencePreset,
                        target: calibration
                    ) {
                        try await brightnessManager.setBrightness(computedBrightness, for: display.id)
                    }
                }

                // 5. External DDC/CI Hardware Commands
                if display.supportsDDC {
                    try await ddcTransport.writeVCP(
                        displayID: display.id,
                        opcode: DDCVcpCode.colorPreset.rawValue,
                        value: DDCVcpCode.ColorPresetValue.sRGB.rawValue
                    )
                }
            } catch {
                self.lastError = error.localizedDescription
            }
        }

        await inspectCapabilities()
    }

    // MARK: - Normal Mode Restoration

    public func restoreNormalInterventions() async {
        isCreativeModeActive = false
        lastError = nil

        for display in connectedDisplays where isManagementEnabled(for: display.id) {
            do {
                // 1. Restore Reference Preset
                if display.isXDR {
                    try await applePresetController.restoreOriginalPreset(for: display.id)
                }

                // 2. Restore ColorSync Profile
                try await colorSyncController.restoreOriginalProfile(for: display.id)

                // 3. Restore Auto-Brightness
                try await brightnessManager.restoreOriginalAutoBrightness(for: display.id)

                // 4. Restore original brightness level
                try await brightnessManager.restoreOriginalBrightness(for: display.id)

                // 5. Restore standard DDC color preset if applicable
                if display.supportsDDC {
                    try await ddcTransport.writeVCP(
                        displayID: display.id,
                        opcode: DDCVcpCode.colorPreset.rawValue,
                        value: DDCVcpCode.ColorPresetValue.sRGB.rawValue
                    )
                }
            } catch {
                self.lastError = error.localizedDescription
            }
        }

        await inspectCapabilities()
    }
}
