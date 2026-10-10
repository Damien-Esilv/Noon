//
//  NoonTests.swift
//  NoonTests
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Testing
import SwiftUI
@testable import Noon

@Suite("Noon Option-Disabling Logic & Settings Tests")
struct OptionDisablingLogicTests {
    
    @Test("Creative mode disables True Tone when manageTrueTone is enabled")
    @MainActor
    func testTrueToneDisablingWhenManaged() async throws {
        let settings = AppSettings()
        settings.manageTrueTone = true
        settings.manageNightShift = false
        
        let displayService = DisplayService()
        
        // When True Tone is supported, test suppression behavior
        if displayService.isTrueToneSupported {
            let wasInitiallyEnabled = displayService.isTrueToneEnabled
            displayService.disableForCreativeMode(settings: settings)
            
            #expect(displayService.isSuppressed == true)
            #expect(displayService.isTrueToneEnabled == false)
            
            // Restore
            displayService.restoreFromCreativeMode(settings: settings)
            #expect(displayService.isSuppressed == false)
            #expect(displayService.isTrueToneEnabled == wasInitiallyEnabled)
        } else {
            // When not supported, disabling should still update suppression flag safely
            displayService.disableForCreativeMode(settings: settings)
            #expect(displayService.isSuppressed == true)
            displayService.restoreFromCreativeMode(settings: settings)
            #expect(displayService.isSuppressed == false)
        }
    }
    
    @Test("Creative mode ignores True Tone when manageTrueTone is disabled")
    @MainActor
    func testTrueToneNotDisabledWhenUnmanaged() async throws {
        let settings = AppSettings()
        settings.manageTrueTone = false
        settings.manageNightShift = false
        
        let displayService = DisplayService()
        let initialTrueToneState = displayService.isTrueToneEnabled
        
        displayService.disableForCreativeMode(settings: settings)
        
        // True Tone state must NOT be modified when manageTrueTone is false
        #expect(displayService.isTrueToneEnabled == initialTrueToneState)
        
        displayService.restoreFromCreativeMode(settings: settings)
        #expect(displayService.isTrueToneEnabled == initialTrueToneState)
    }
    
    @Test("Creative mode disables Night Shift when manageNightShift is enabled")
    @MainActor
    func testNightShiftDisablingWhenManaged() async throws {
        let settings = AppSettings()
        settings.manageTrueTone = false
        settings.manageNightShift = true
        
        let displayService = DisplayService()
        let wasInitiallyEnabled = displayService.isNightShiftEnabled
        
        displayService.disableForCreativeMode(settings: settings)
        #expect(displayService.isSuppressed == true)
        #expect(displayService.isNightShiftEnabled == false)
        
        // Restore
        displayService.restoreFromCreativeMode(settings: settings)
        #expect(displayService.isSuppressed == false)
        #expect(displayService.isNightShiftEnabled == wasInitiallyEnabled)
    }
    
    @Test("Creative mode ignores Night Shift when manageNightShift is disabled")
    @MainActor
    func testNightShiftNotDisabledWhenUnmanaged() async throws {
        let settings = AppSettings()
        settings.manageTrueTone = false
        settings.manageNightShift = false
        
        let displayService = DisplayService()
        let initialNightShiftState = displayService.isNightShiftEnabled
        
        displayService.disableForCreativeMode(settings: settings)
        #expect(displayService.isNightShiftEnabled == initialNightShiftState)
        
        displayService.restoreFromCreativeMode(settings: settings)
        #expect(displayService.isNightShiftEnabled == initialNightShiftState)
    }
    
    @Test("Monitoring pause restores display and sets state to paused")
    @MainActor
    func testPauseMonitoringRestoresDisplay() async throws {
        let settings = AppSettings()
        settings.isMonitoringEnabled = true
        settings.manageTrueTone = false
        settings.manageNightShift = true
        // Ensure monitored apps list is clean for this test
        settings.monitoredApps = []
        
        let displayService = DisplayService()
        let monitorService = AppMonitorService(
            displayService: displayService,
            settings: settings,
            notificationService: NotificationService.shared
        )
        
        // Use a real system application that is guaranteed to be valid on macOS
        let finderApp = MonitoredApp(
            name: "Finder",
            bundleIdentifier: "com.apple.finder",
            path: "/System/Library/CoreServices/Finder.app"
        )
        settings.addApp(finderApp)
        
        // Pause monitoring
        monitorService.pauseMonitoring()
        #expect(settings.isMonitoringEnabled == false)
        #expect(monitorService.currentState == .paused)
        #expect(displayService.isSuppressed == false)
        
        // Resume monitoring with valid app returns to normal
        monitorService.resumeMonitoring()
        #expect(settings.isMonitoringEnabled == true)
        #expect(monitorService.currentState == .normal)
    }
    
    @Test("Invalid monitored app triggers error state on monitoring validation")
    @MainActor
    func testInvalidAppTriggersErrorState() async throws {
        let settings = AppSettings()
        settings.monitoredApps = []
        
        let displayService = DisplayService()
        let monitorService = AppMonitorService(
            displayService: displayService,
            settings: settings,
            notificationService: NotificationService.shared
        )
        
        let invalidApp = MonitoredApp(
            name: "MissingCreativeApp",
            bundleIdentifier: "com.missing.creativeapp",
            path: "/Applications/NonExistentApp.app"
        )
        settings.addApp(invalidApp)
        
        // Starting or resuming monitoring with an invalid app should trigger .error state
        monitorService.startMonitoring()
        if case .error(let msg) = monitorService.currentState {
            #expect(msg.contains("introuvable") || msg.contains("not found"))
        } else {
            Issue.record("Expected .error state when invalid app is monitored, got \(monitorService.currentState)")
        }
        
        monitorService.stopMonitoring()
        settings.removeApp(invalidApp)
        settings.monitoredApps = []
    }

    @Test("Disabling display management prevents True Tone and Night Shift modification")
    @MainActor
    func testDisplayManagementDisabledPreventsTrueToneAndNightShiftModification() async throws {
        let settings = AppSettings()
        settings.manageTrueTone = true
        settings.manageNightShift = true
        
        let displayManager = DisplayManager.shared
        let mainID = CGMainDisplayID()
        
        // Disable all displays in manager
        for d in displayManager.connectedDisplays {
            displayManager.setManagementEnabled(false, for: d.id)
        }
        displayManager.setManagementEnabled(false, for: mainID)
        
        let displayService = DisplayService()
        let initialTT = displayService.isTrueToneEnabled
        let initialNS = displayService.isNightShiftEnabled
        
        displayService.disableForCreativeMode(settings: settings)
        
        // Suppression must NOT happen when display is unmanaged
        #expect(displayService.isSuppressed == false)
        #expect(displayService.isTrueToneEnabled == initialTT)
        #expect(displayService.isNightShiftEnabled == initialNS)
        
        // Re-enable displays for clean state
        for d in displayManager.connectedDisplays {
            displayManager.setManagementEnabled(true, for: d.id)
        }
        displayManager.setManagementEnabled(true, for: mainID)
    }

    @Test("Disabled display IDs persist in AppSettings")
    @MainActor
    func testDisabledDisplayPersistence() {
        let settings = AppSettings()
        let testID: CGDirectDisplayID = 888877
        
        settings.setDisplayManagement(false, for: testID)
        #expect(settings.isDisplayManagementEnabled(for: testID) == false)
        #expect(settings.disabledDisplayIDs.contains(UInt32(testID)))
        
        settings.setDisplayManagement(true, for: testID)
        #expect(settings.isDisplayManagementEnabled(for: testID) == true)
        #expect(!settings.disabledDisplayIDs.contains(UInt32(testID)))
    }
}

@Suite("UI State and Appearance Tests")
struct UIStateAndAppearanceTests {
    
    @Test("MenuBarState system images match icon style configurations")
    func testStateSystemImages() throws {
        for style in MenuBarIconStyle.allCases {
            let normalImage = MenuBarState.normal.systemImage(for: style)
            let creativeImage = MenuBarState.creativeMode.systemImage(for: style)
            let errorImage = MenuBarState.error("Test Error").systemImage(for: style)
            let pausedImage = MenuBarState.paused.systemImage(for: style)
            let timerImage = MenuBarState.timerActive(120).systemImage(for: style)
            
            #expect(!normalImage.isEmpty)
            #expect(!creativeImage.isEmpty)
            #expect(!errorImage.isEmpty)
            #expect(!pausedImage.isEmpty)
            #expect(!timerImage.isEmpty)
            #expect(pausedImage == "pause.circle.fill")
            #expect(timerImage == "timer")
        }
    }
    
    @Test("AppSettings effectiveAccentColor resolves system vs custom mode")
    @MainActor
    func testEffectiveAccentColor() throws {
        let settings = AppSettings()
        
        // System mode should yield nil (using SwiftUI Color.accentColor)
        settings.accentColorMode = AccentColorMode.system
        #expect(settings.effectiveAccentColor == nil)
        
        // Custom mode should return custom accent color
        settings.accentColorMode = AccentColorMode.custom
        settings.customAccentColor = Color.purple
        #expect(settings.effectiveAccentColor == Color.purple)
    }
    
    @Test("AppSettings resetAppearance restores factory defaults")
    @MainActor
    func testResetAppearance() throws {
        let settings = AppSettings()
        settings.menuBarIconStyle = MenuBarIconStyle.sunMin
        settings.accentColorMode = AccentColorMode.custom
        settings.customAccentColor = Color.mint
        settings.colorNormal = Color.blue
        settings.colorCreative = Color.pink
        settings.colorError = Color.yellow
        
        settings.resetAppearance()
        
        #expect(settings.menuBarIconStyle == MenuBarIconStyle.sunMinFill)
        #expect(settings.accentColorMode == AccentColorMode.system)
        #expect(settings.colorNormal == Color.blue)
        #expect(settings.colorCreative == Color.orange)
        #expect(settings.colorError == Color.red)
    }
}

@Suite("SwiftUI Modern UI Component Instantiation Tests")
struct ModernUIComponentsTests {
    
    @Test("GlassCard renders content across macOS 15 and 14 branches")
    @MainActor
    func testGlassCardInstantiation() throws {
        let card = GlassCard(cornerRadius: 16, padding: 12, material: .regularMaterial, borderOpacity: 0.2, shadowRadius: 6) {
            Text("Glass Card Test")
        }
        _ = card.body
    }
    
    @Test("AccentGlassCard renders with custom accent color across branches")
    @MainActor
    func testAccentGlassCardInstantiation() throws {
        let accentCard = AccentGlassCard(accentColor: .indigo, cornerRadius: 12) {
            Text("Accent Glass Card Test")
        }
        _ = accentCard.body
    }
    
    @Test("AppRowView renders correctly with valid and invalid apps")
    @MainActor
    func testAppRowViewInstantiation() throws {
        let validApp = MonitoredApp(name: "Photoshop", bundleIdentifier: "com.adobe.photoshop", path: "/Applications/Photoshop.app")
        let rowRunning = AppRowView(app: validApp, isRunning: true, onDelete: {})
        _ = rowRunning.body
        
        let rowNotRunning = AppRowView(app: validApp, isRunning: false, onDelete: nil)
        _ = rowNotRunning.body
        
        let invalidApp = MonitoredApp(name: "MissingApp", bundleIdentifier: "com.missing.app", path: "/Applications/DoesNotExist.app")
        let rowInvalid = AppRowView(app: invalidApp, isRunning: false, onDelete: {})
        _ = rowInvalid.body
    }
    
    @Test("AppRowCompact renders for menu bar popover")
    @MainActor
    func testAppRowCompactInstantiation() throws {
        let app = MonitoredApp(name: "DaVinci", bundleIdentifier: "com.blackmagic.davinci", path: "/Applications/DaVinci.app")
        let compactActive = AppRowCompact(app: app, isActive: true)
        _ = compactActive.body
        
        let compactInactive = AppRowCompact(app: app, isActive: false)
        _ = compactInactive.body
    }
    
    @Test("MenuBarView instantiates with active services and settings")
    @MainActor
    func testMenuBarViewInstantiation() throws {
        let settings = AppSettings()
        let displayService = DisplayService()
        let monitorService = AppMonitorService(
            displayService: displayService,
            settings: settings,
            notificationService: NotificationService.shared
        )
        
        let menuBarView = MenuBarView(
            monitorService: monitorService,
            displayService: displayService,
            settings: settings
        )
        _ = menuBarView.body
    }
    
    @Test("AppearanceTab instantiates with bound settings")
    @MainActor
    func testAppearanceTabInstantiation() throws {
        let settings = AppSettings()
        let appearanceTab = AppearanceTab(settings: settings)
        _ = appearanceTab.body
    }
}
