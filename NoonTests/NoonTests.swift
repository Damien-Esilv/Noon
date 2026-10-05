//
//  NoonTests.swift
//  NoonTests
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Testing
import Foundation
import SwiftUI
@testable import Noon

struct MonitoredAppTests {

    @Test func testSuggestionsCountAndContent() {
        let suggestions = MonitoredApp.suggestions
        #expect(!suggestions.isEmpty)
        #expect(suggestions.count >= 20)

        let bundleIDs = suggestions.map { $0.bundleIdentifier }
        #expect(bundleIDs.contains("com.adobe.Photoshop"))
        #expect(bundleIDs.contains("com.apple.FinalCut"))
        #expect(bundleIDs.contains("com.blackmagic-design.DaVinciResolve"))
        #expect(bundleIDs.contains("org.blender.blender"))
        #expect(bundleIDs.contains("com.figma.Desktop"))
    }

    @Test func testAppInitializationWithDefaults() {
        let app = MonitoredApp(name: "TestApp", bundleIdentifier: "com.example.testapp")
        #expect(app.name == "TestApp")
        #expect(app.bundleIdentifier == "com.example.testapp")
        #expect(app.path.contains("TestApp.app"))
    }

    @Test func testAppInitializationWithCustomPath() {
        let customPath = "/Custom/Path/TestApp.app"
        let app = MonitoredApp(name: "TestApp", bundleIdentifier: "com.example.testapp", path: customPath)
        #expect(app.path == customPath)
    }

    @Test func testEqualityAndHashing() {
        let app1 = MonitoredApp(name: "AppA", bundleIdentifier: "com.example.a")
        let app2 = MonitoredApp(name: "AppA", bundleIdentifier: "com.example.a")

        // Two distinct instances have different UUIDs
        #expect(app1 != app2)
        #expect(app1 == app1)

        var hasher1 = Hasher()
        var hasher2 = Hasher()
        app1.hash(into: &hasher1)
        app1.hash(into: &hasher2)
        #expect(hasher1.finalize() == hasher2.finalize())
    }

    @Test func testValidityCheck() {
        let invalidApp = MonitoredApp(name: "NonExistent", bundleIdentifier: "com.invalid.nonexistent", path: "/nonexistent/path/App.app")
        #expect(!invalidApp.isValid)
    }

    @Test func testCodableSerialization() throws {
        let original = MonitoredApp(name: "SerializableApp", bundleIdentifier: "com.example.serializable", path: "/Applications/Test.app")
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MonitoredApp.self, from: data)

        #expect(original.id == decoded.id)
        #expect(original.name == decoded.name)
        #expect(original.bundleIdentifier == decoded.bundleIdentifier)
        #expect(original.path == decoded.path)
    }
}

struct ReactivationModeTests {

    @Test func testAllCases() {
        let cases = ReactivationMode.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.immediate))
        #expect(cases.contains(.onQuit))
        #expect(cases.contains(.timer))
    }

    @Test func testRawValuesAndIDs() {
        #expect(ReactivationMode.immediate.rawValue == "immediate")
        #expect(ReactivationMode.immediate.id == "immediate")
        #expect(ReactivationMode.onQuit.rawValue == "onQuit")
        #expect(ReactivationMode.timer.rawValue == "timer")
    }

    @Test func testSystemImages() {
        #expect(ReactivationMode.immediate.systemImage == "bolt.fill")
        #expect(ReactivationMode.onQuit.systemImage == "xmark.app.fill")
        #expect(ReactivationMode.timer.systemImage == "timer")
    }
}

struct MenuBarStateTests {

    @Test func testStateEquality() {
        #expect(MenuBarState.normal == MenuBarState.normal)
        #expect(MenuBarState.creativeMode == MenuBarState.creativeMode)
        #expect(MenuBarState.paused == MenuBarState.paused)
        #expect(MenuBarState.error("Test Error") == MenuBarState.error("Test Error"))
        #expect(MenuBarState.error("A") != MenuBarState.error("B"))
        #expect(MenuBarState.timerActive(30) == MenuBarState.timerActive(30))
        #expect(MenuBarState.timerActive(30) != MenuBarState.timerActive(60))
        #expect(MenuBarState.normal != MenuBarState.creativeMode)
    }

    @Test func testSystemImagesForStyles() {
        let normalState = MenuBarState.normal
        #expect(normalState.systemImage(for: .sunMinFill) == "sun.min.fill")
        #expect(normalState.systemImage(for: .sunMin) == "sun.min")

        let creativeState = MenuBarState.creativeMode
        #expect(creativeState.systemImage(for: .sunMinFill) == "sun.min")
        #expect(creativeState.systemImage(for: .sunMin) == "sun.min.fill")

        let errorState = MenuBarState.error("Alert")
        #expect(errorState.systemImage(for: .sunMinFill) == "exclamationmark.triangle.fill")

        let timerState = MenuBarState.timerActive(15)
        #expect(timerState.systemImage(for: .sunMin) == "timer")

        let pausedState = MenuBarState.paused
        #expect(pausedState.systemImage(for: .sunMinFill) == "pause.circle.fill")
    }
}

struct AppSettingsTests {

    @Test func testSharedInstance() {
        let settings = AppSettings.shared
        #expect(settings != nil)
    }

    @Test func testAddingAndRemovingMonitoredApps() {
        let settings = AppSettings.shared
        let initialCount = settings.monitoredApps.count

        let testApp = MonitoredApp(name: "Test Unique App", bundleIdentifier: "com.test.unique.app")
        settings.addApp(testApp)
        #expect(settings.monitoredApps.contains(where: { $0.id == testApp.id }))

        // Attempting to add duplicate bundle Identifier
        let duplicateApp = MonitoredApp(name: "Test Unique App Copy", bundleIdentifier: "com.test.unique.app")
        settings.addApp(duplicateApp)
        #expect(!settings.monitoredApps.contains(where: { $0.id == duplicateApp.id }))

        // Remove app
        settings.removeApp(testApp)
        #expect(!settings.monitoredApps.contains(where: { $0.id == testApp.id }))
    }

    @Test func testResetAppearance() {
        let settings = AppSettings.shared
        settings.colorNormal = .red
        settings.colorCreative = .green
        settings.menuBarIconStyle = .sunMin

        settings.resetAppearance()

        #expect(settings.menuBarIconStyle == .sunMinFill)
        #expect(settings.accentColorMode == .system)
    }

    @Test func testEffectiveAccentColor() {
        let settings = AppSettings.shared
        settings.accentColorMode = .system
        #expect(settings.effectiveAccentColor == nil)

        settings.accentColorMode = .custom
        settings.customAccentColor = .purple
        #expect(settings.effectiveAccentColor == .purple)

        // Restore
        settings.accentColorMode = .system
    }

    @Test func testSelectedLocale() {
        let settings = AppSettings.shared
        settings.appLanguage = .fr
        #expect(settings.selectedLocale.identifier == "fr")

        settings.appLanguage = .en
        #expect(settings.selectedLocale.identifier == "en")

        settings.appLanguage = .system
    }
}

struct AppLanguageTests {

    @Test func testAllCasesAndDisplayNames() {
        let cases = AppLanguage.allCases
        #expect(cases.contains(.system))
        #expect(cases.contains(.en))
        #expect(cases.contains(.fr))
        #expect(cases.contains(.de))
        #expect(cases.contains(.es))
        #expect(cases.contains(.it))
        #expect(cases.contains(.pt))
        #expect(cases.contains(.zh))
        #expect(cases.contains(.ar))

        #expect(AppLanguage.en.displayName == "English")
        #expect(AppLanguage.fr.displayName == "Français")
        #expect(AppLanguage.de.displayName == "Deutsch")
        #expect(AppLanguage.es.displayName == "Español")
        #expect(AppLanguage.it.displayName == "Italiano")
        #expect(AppLanguage.pt.displayName == "Português")
        #expect(AppLanguage.zh.displayName == "中文")
        #expect(AppLanguage.ar.displayName == "العربية")
        #expect(AppLanguage.system.displayName == "System")
    }

    @Test func testLanguageIDs() {
        #expect(AppLanguage.fr.id == "fr")
        #expect(AppLanguage.zh.id == "zh-Hans")
    }
}

struct AppColorSchemeTests {

    @Test func testColorSchemeCases() {
        let cases = AppColorScheme.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.system))
        #expect(cases.contains(.light))
        #expect(cases.contains(.dark))

        #expect(AppColorScheme.system.id == "system")
        #expect(AppColorScheme.light.id == "light")
        #expect(AppColorScheme.dark.id == "dark")
    }
}
