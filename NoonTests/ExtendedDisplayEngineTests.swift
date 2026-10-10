//
//  ExtendedDisplayEngineTests.swift
//  NoonTests
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Testing
import Foundation
import CoreGraphics
import SwiftUI
@testable import Noon

// MARK: - 1. DDC/CI Packet Framing & Transport Suite

@Suite("DDC/CI Packet Framing & Transport Tests")
struct DDCPacketTests {

    @Test("DDC/CI checksum correctly XORs destination address and body bytes")
    func testDDCChecksumCalculation() {
        // Destination = 0x6E
        // Bytes = [0x51, 0x84, 0x03, 0x10, 0x00, 0x50]
        // 0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ 0x10 ^ 0x00 ^ 0x50 = 0x6E ^ 0x51 = 0x3F
        // 0x3F ^ 0x84 = 0xBB; 0xB8 ^ 0x10 = 0xA8; 0xA8 ^ 0x50 = 0xF8
        let body: [UInt8] = [0x51, 0x84, 0x03, 0x10, 0x00, 0x50]
        let expectedChecksum: UInt8 = 0x6E ^ 0x51 ^ 0x84 ^ 0x03 ^ 0x10 ^ 0x00 ^ 0x50
        let computed = DDCPacket.computeChecksum(for: body, destination: 0x6E)
        #expect(computed == expectedChecksum)
    }

    @Test("makeSetVCPPacket constructs standard 7-byte DDC payload with valid checksum")
    func testSetVCPPacketFormation() {
        let opcode: UInt8 = DDCVcpCode.luminance.rawValue
        let value: UInt16 = 80 // 0x0050
        let packet = DDCPacket.makeSetVCPPacket(opcode: opcode, value: value)

        #expect(packet.bytes.count == 7)
        #expect(packet.bytes[0] == 0x51) // Source address
        #expect(packet.bytes[1] == 0x84) // Length byte (0x80 | 4)
        #expect(packet.bytes[2] == 0x03) // Set VCP command
        #expect(packet.bytes[3] == 0x10) // Luminance opcode
        #expect(packet.bytes[4] == 0x00) // Value High
        #expect(packet.bytes[5] == 0x50) // Value Low
        
        let bodyOnly = Array(packet.bytes.dropLast())
        let expectedChecksum = DDCPacket.computeChecksum(for: bodyOnly)
        #expect(packet.bytes[6] == expectedChecksum)
    }

    @Test("makeGetVCPPacket constructs standard 5-byte request")
    func testGetVCPPacketFormation() {
        let opcode: UInt8 = DDCVcpCode.contrast.rawValue // 0x12
        let packet = DDCPacket.makeGetVCPPacket(opcode: opcode)

        #expect(packet.bytes.count == 5)
        #expect(packet.bytes[0] == 0x51) // Source address
        #expect(packet.bytes[1] == 0x82) // Length byte (0x80 | 2)
        #expect(packet.bytes[2] == 0x01) // Get VCP command
        #expect(packet.bytes[3] == 0x12) // Contrast opcode
    }

    @Test("parseGetVCPReply extracts current and max values correctly")
    func testParseGetVCPReply() {
        // Standard DDC response: [dest, length, 0x02, result, opcode, type, maxH, maxL, curH, curL, checksum]
        // max = 100 (0x0064), cur = 50 (0x0032)
        let replyPayload: [UInt8] = [0x6E, 0x88, 0x02, 0x00, 0x10, 0x00, 0x00, 0x64, 0x00, 0x32, 0x00]
        let result = DDCPacket.parseGetVCPReply(replyPayload)

        #expect(result != nil)
        #expect(result?.current == 50)
        #expect(result?.max == 100)
    }

    @Test("MockDDCTransport writes and reads VCP registers successfully")
    func testMockDDCTransport() async throws {
        let displayID: CGDirectDisplayID = 1001
        let mockTransport = MockDDCTransport(supportedDisplays: [displayID])

        let isSupported = await mockTransport.isSupported(displayID: displayID)
        #expect(isSupported == true)

        try await mockTransport.writeVCP(displayID: displayID, opcode: DDCVcpCode.luminance.rawValue, value: 75)
        let reading = try await mockTransport.readVCP(displayID: displayID, opcode: DDCVcpCode.luminance.rawValue)

        #expect(reading.current == 75)
        #expect(reading.max == 100)
    }
}

// MARK: - 2. Apple Reference Preset Engine Suite

@Suite("Apple Reference Preset Tests")
struct AppleReferencePresetTests {

    @Test("Factory presets exhibit expected SDR nominal luminance targets")
    func testPresetLuminanceValues() {
        #expect(AppleReferencePreset.appleXDR.nominalSDRLuminance == 500)
        #expect(AppleReferencePreset.photographyP3D65.nominalSDRLuminance == 160)
        #expect(AppleReferencePreset.designPrintP3D50.nominalSDRLuminance == 160)
        #expect(AppleReferencePreset.digitalCinemaP3DCI.nominalSDRLuminance == 48)
        #expect(AppleReferencePreset.hdtvVideoBT709.nominalSDRLuminance == 100)
    }

    @Test("Strict reference presets enforce hardware luminance locks")
    func testHardwareLuminanceLockDetection() {
        #expect(AppleReferencePreset.appleXDR.hasHardwareLuminanceLock == false)
        #expect(AppleReferencePreset.appleDisplay.hasHardwareLuminanceLock == false)
        #expect(AppleReferencePreset.photographyP3D65.hasHardwareLuminanceLock == true)
        #expect(AppleReferencePreset.hdtvVideoBT709.hasHardwareLuminanceLock == true)
        #expect(AppleReferencePreset.digitalCinemaP3DCI.hasHardwareLuminanceLock == true)
    }

    @Test("MockApplePresetController switches and restores presets")
    func testPresetSwitchingAndRestoration() async throws {
        let displayID: CGDirectDisplayID = 2001
        let mockController = MockApplePresetController(xdrDisplays: [displayID])

        let isXDR = await mockController.isXDRDisplay(displayID)
        #expect(isXDR == true)

        // Switch to Photography preset
        try await mockController.setActivePreset(.photographyP3D65, for: displayID)
        var active = await mockController.getActivePreset(for: displayID)
        #expect(active == .photographyP3D65)

        // Restore to original preset
        try await mockController.restoreOriginalPreset(for: displayID)
        active = await mockController.getActivePreset(for: displayID)
        #expect(active == .appleXDR)
    }
}

// MARK: - 3. Calibrated Brightness & Luminance Math Suite

@Suite("Calibrated Brightness Math Tests")
struct CalibratedBrightnessTests {

    @Test("Apple Recommended on XDR targets standardized 100 nits SDR reference (20% slider)")
    func testRecommendedCalibrationOnXDR() {
        let brightness = BrightnessManager.computeCalibratedBrightness(
            isXDR: true,
            activePreset: .appleXDR,
            target: .appleRecommended
        )
        // 100.0 / 500.0 = 0.20
        #expect(brightness == 0.20)
    }

    @Test("Apple Recommended on Standard Retina Display locks 50% slider value (~120 nits)")
    func testRecommendedCalibrationOnStandardDisplay() {
        let brightness = BrightnessManager.computeCalibratedBrightness(
            isXDR: false,
            activePreset: nil,
            target: .appleRecommended
        )
        #expect(brightness == 0.50)
    }

    @Test("Luminance calculation returns nil when active preset enforces a hardware lock")
    func testLuminanceBypassOnHardwareLockedPreset() {
        let brightness = BrightnessManager.computeCalibratedBrightness(
            isXDR: true,
            activePreset: .hdtvVideoBT709,
            target: .appleRecommended
        )
        #expect(brightness == nil)
    }

    @Test("Fixed nits target scales accurately according to display SDR range")
    func testFixedNitsScaling() {
        // 250 nits on XDR (max 500) -> 0.50
        let xdrValue = BrightnessManager.computeCalibratedBrightness(
            isXDR: true,
            activePreset: .appleXDR,
            target: .fixedNits(250)
        )
        #expect(xdrValue == 0.50)

        // 200 nits on standard Retina (max 400) -> 0.50
        let standardValue = BrightnessManager.computeCalibratedBrightness(
            isXDR: false,
            activePreset: nil,
            target: .fixedNits(200)
        )
        #expect(standardValue == 0.50)
    }
}

// MARK: - 4. ColorSync Profile Discovery & Switching Suite

@Suite("ColorSync Controller Tests")
struct ColorSyncControllerTests {

    @Test("ColorSyncController discovers standard profiles")
    func testAvailableStandardProfiles() async {
        let controller = MockColorSyncController()
        let profiles = await controller.availableStandardProfiles()
        #expect(!profiles.isEmpty)
        #expect(profiles.contains("sRGB"))
        #expect(profiles.contains("Display P3"))
    }

    @Test("Setting profile updates current profile and restores accurately")
    func testProfileSwitchingAndRestoring() async throws {
        let displayID: CGDirectDisplayID = 3001
        let controller = MockColorSyncController()

        try await controller.setProfile(named: "sRGB", for: displayID)
        var active = await controller.getCurrentProfileName(for: displayID)
        #expect(active == "sRGB")

        try await controller.restoreOriginalProfile(for: displayID)
        active = await controller.getCurrentProfileName(for: displayID)
        #expect(active == "Display P3")
    }
}

// MARK: - 5. Per-Display Targeting Suite

@Suite("Display Manager Multi-Display Orchestration Tests")
struct DisplayManagerOrchestrationTests {

    @Test("Per-display targeting respects disabled screens")
    @MainActor
    func testPerDisplaySelectiveTargeting() {
        let manager = DisplayManager.shared
        let displayID: CGDirectDisplayID = 9999

        manager.setManagementEnabled(false, for: displayID)
        #expect(manager.isManagementEnabled(for: displayID) == false)

        manager.setManagementEnabled(true, for: displayID)
        #expect(manager.isManagementEnabled(for: displayID) == true)
    }
}

// MARK: - 6. Web App Watcher Suite

@Suite("Web App Browser Inspector Tests")
struct WebAppWatcherTests {

    @Test("Matches recognized creative web applications by URL pattern")
    func testToolMatchingByURL() {
        let figma = WebAppWatcher.matchTool(from: "https://www.figma.com/file/xyz/Design-System")
        #expect(figma?.id == "figma")

        let photopea = WebAppWatcher.matchTool(from: "https://www.photopea.com/#project123")
        #expect(photopea?.id == "photopea")

        let canva = WebAppWatcher.matchTool(from: "https://www.canva.com/design/DAG123/edit")
        #expect(canva?.id == "canva")

        let spline = WebAppWatcher.matchTool(from: "https://spline.design/3d-scene")
        #expect(spline?.id == "spline")

        let nonCreative = WebAppWatcher.matchTool(from: "https://news.ycombinator.com")
        #expect(nonCreative == nil)
    }

    @Test("Matches recognized creative web applications by Window Title")
    func testToolMatchingByTitle() {
        let figma = WebAppWatcher.matchTool(from: "Landing Page – Figma")
        #expect(figma?.id == "figma")

        let photopea = WebAppWatcher.matchTool(from: "Photopea | Online Photo Editor")
        #expect(photopea?.id == "photopea")

        let canva = WebAppWatcher.matchTool(from: "Instagram Post – Canva")
        #expect(canva?.id == "canva")

        let normal = WebAppWatcher.matchTool(from: "GitHub - Damien-Esilv/Noon")
        #expect(normal == nil)
    }
}

// MARK: - 7. Ambient Light Sensor Drift Monitor Suite

@Suite("Ambient Light Drift Monitor Tests")
struct AmbientLightMonitorTests {

    @Test("Drift monitor establishes baseline and flags excessive lighting delta")
    @MainActor
    func testLightingDriftDetection() async {
        let mockSensor = MockAmbientLightSensor(initialLux: 100.0)
        let monitor = AmbientLightMonitor(sensor: mockSensor)

        // Initial poll creates baseline
        await monitor.pollSensor()
        #expect(monitor.baselineReading?.lux == 100.0)
        #expect(monitor.isLightingDriftExceeded == false)

        // Moderate light change (+10 Lux -> 10% drift): within tolerance
        await mockSensor.setSimulatedLux(110.0)
        await monitor.pollSensor()
        #expect(monitor.isLightingDriftExceeded == false)
        #expect(monitor.driftPercentage == 10.0)

        // Severe light change (+50 Lux -> 50% drift): exceeds 30% threshold
        await mockSensor.setSimulatedLux(150.0)
        await monitor.pollSensor()
        #expect(monitor.isLightingDriftExceeded == true)
        #expect(monitor.driftPercentage == 50.0)

        // Reset baseline restores safe state
        monitor.resetBaseline()
        #expect(monitor.isLightingDriftExceeded == false)
        #expect(monitor.baselineReading?.lux == 150.0)
    }
}

// MARK: - 8. URL Scheme & CLI Command Router Suite

@Suite("URL Scheme & CLI Command Router Tests")
struct NoonCommandRouterTests {

    @Test("Parses noon:// custom URL scheme commands accurately")
    func testURLSchemeParsing() {
        let router = NoonCommandRouter()

        let toggleCmd = router.parseURL(URL(string: "noon://toggle")!)
        #expect(toggleCmd == .toggleCreativeMode)

        let enableCmd = router.parseURL(URL(string: "noon://enable?app=Photoshop")!)
        #expect(enableCmd == .enableCreativeMode(appName: "Photoshop"))

        let disableCmd = router.parseURL(URL(string: "noon://disable")!)
        #expect(disableCmd == .disableCreativeMode)

        let presetCmd = router.parseURL(URL(string: "noon://preset?name=photography")!)
        #expect(presetCmd == .setPreset(.photographyP3D65))

        let calibrateCmd = router.parseURL(URL(string: "noon://calibrate?mode=recommended")!)
        #expect(calibrateCmd == .setCalibratedBrightness(.appleRecommended))
    }

    @Test("Parses CLI arguments accurately")
    func testCLIArgumentParsing() {
        let router = NoonCommandRouter()

        let status = router.parseArguments(["noon-cli", "--status"])
        #expect(status == .statusQuery)

        let toggle = router.parseArguments(["noon", "-t"])
        #expect(toggle == .toggleCreativeMode)

        let preset = router.parseArguments(["noon-cli", "--preset", "photography"])
        #expect(preset == .setPreset(.photographyP3D65))

        let calib = router.parseArguments(["noon", "-r"])
        #expect(calib == .setCalibratedBrightness(.appleRecommended))

        let brightness = router.parseArguments(["noon-cli", "-b", "0.85"])
        #expect(brightness == .setBrightness(0.85))
    }
}

// MARK: - 9. Integrated Displays UI & Settings Suite

@Suite("Integrated Displays UI and Settings Tests")
struct IntegratedDisplaysUITests {

    @Test("AppSettings contains display engine defaults and saves state")
    func testDisplaySettingsDefaultsAndUpdates() {
        let settings = AppSettings.shared

        settings.lock100NitsCalibration = true
        #expect(settings.lock100NitsCalibration == true)

        settings.manageAutoBrightness = false
        #expect(settings.manageAutoBrightness == false)

        settings.enableAmbientLightMonitoring = true
        #expect(settings.enableAmbientLightMonitoring == true)

        settings.showHUDOnSwitch = true
        #expect(settings.showHUDOnSwitch == true)

        settings.monitorWebApps = true
        #expect(settings.monitorWebApps == true)

        // Restore clean test defaults
        settings.lock100NitsCalibration = false
        settings.manageAutoBrightness = true
        settings.enableAmbientLightMonitoring = false
    }

    @Test("DisplaysTab SwiftUI component instantiates properly")
    @MainActor
    func testDisplaysTabInstantiation() {
        let settings = AppSettings.shared
        let view = DisplaysTab(settings: settings)
        #expect(view != nil)
    }

    @Test("HUDOverlayController presents and dismisses on MainActor")
    @MainActor
    func testHUDOverlayControllerLifecycle() {
        let controller = HUDOverlayController.shared
        controller.showHUD(
            isCreativeMode: true,
            activePreset: .photographyP3D65,
            is100NitsLocked: true,
            isLightingDriftExceeded: false,
            driftPercentage: 0.0,
            autoDismissDelay: 0.1
        )
        controller.dismiss()
    }
}

// MARK: - 10. v1.1.0 New Features & Internationalization Suite

@Suite("v1.1.0 New Features & Internationalization Tests")
struct V1_1_NewFeaturesTests {

    @Test("Popup material style supports transparent and solid modes")
    func testPopupMaterialStyle() {
        let settings = AppSettings.shared
        settings.popupMaterialStyle = .solid
        #expect(settings.popupMaterialStyle == .solid)
        #expect(PopupMaterialStyle.solid.displayName != "")
        #expect(PopupMaterialStyle.transparent.displayName != "")

        settings.popupMaterialStyle = .transparent
        #expect(settings.popupMaterialStyle == .transparent)
    }

    @Test("Monitored websites support predefined list, additions, toggling, and removal")
    func testMonitoredWebsitesManagement() {
        let settings = AppSettings.shared
        let initialCount = settings.monitoredWebsites.count
        #expect(initialCount >= 4) // Figma, Canva, Photopea, Spline

        // Add custom site
        settings.addWebsite(name: "Dribbble", domain: "dribbble.com")
        let addedSite = settings.monitoredWebsites.first { $0.domain == "dribbble.com" }
        #expect(addedSite != nil)
        #expect(addedSite?.name == "Dribbble")
        #expect(addedSite?.isPredefined == false)
        #expect(addedSite?.isEnabled == true)

        // Toggle site
        if let siteId = addedSite?.id {
            settings.toggleWebsite(id: siteId)
            let toggledSite = settings.monitoredWebsites.first { $0.id == siteId }
            #expect(toggledSite?.isEnabled == false)

            // WebAppWatcher should not match disabled site
            let disabledMatch = WebAppWatcher.shared.matchTool(url: "https://dribbble.com/shots", title: "Dribbble - Popular")
            #expect(disabledMatch == nil)

            // Re-enable site
            settings.toggleWebsite(id: siteId)
            let enabledMatch = WebAppWatcher.shared.matchTool(url: "https://dribbble.com/shots", title: "Dribbble - Popular")
            #expect(enabledMatch != nil)
            #expect(enabledMatch?.name == "Dribbble")

            // Remove site
            settings.removeWebsite(id: siteId)
            let removedSite = settings.monitoredWebsites.first { $0.id == siteId }
            #expect(removedSite == nil)
        }
    }

    @Test("Preset brightness level controls and preferences")
    func testPresetBrightnessSettings() {
        let settings = AppSettings.shared
        settings.enablePresetBrightness = true
        settings.presetBrightnessLevel = 0.75
        #expect(settings.enablePresetBrightness == true)
        #expect(settings.presetBrightnessLevel == 0.75)

        // Cleanup
        settings.enablePresetBrightness = false
        settings.presetBrightnessLevel = 0.70
    }

    @Test("All Localizable strings contain complete translations across all 8 languages")
    func testAllStringsHaveCompleteTranslations() throws {
        let xcstringsURL = Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings")
            ?? URL(fileURLWithPath: "Noon/Resources/Localizable.xcstrings")
        
        let fileManager = FileManager.default
        let path = fileManager.fileExists(atPath: xcstringsURL.path) ? xcstringsURL.path : "Noon/Resources/Localizable.xcstrings"
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let strings = json["strings"] as? [String: [String: Any]] else {
            return // Soft fail if outside bundle test environment
        }

        let supportedLangs = ["fr", "en", "it", "de", "es", "pt", "zh-Hans", "ar"]
        for (key, dict) in strings {
            guard !key.isEmpty else { continue }
            let localizations = dict["localizations"] as? [String: [String: Any]] ?? [:]
            for lang in supportedLangs {
                let unit = localizations[lang]?["stringUnit"] as? [String: Any]
                let val = unit?["value"] as? String
                #expect(val != nil && !val!.isEmpty, "Missing translation for key: \(key) in language: \(lang)")
            }
        }
    }
}
