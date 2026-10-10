//
//  SettingsView.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

struct SettingsView: View {
    let displayService: DisplayService
    let monitorService: AppMonitorService
    @Bindable var settings: AppSettings
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralTab(
                settings: settings,
                displayService: displayService,
                monitorService: monitorService
            )
            .tabItem {
                Label("Général", systemImage: "gearshape")
            }
            .tag(0)

            BrightnessTab(settings: settings)
                .tabItem {
                    Label("Luminosité", systemImage: "sun.max")
                }
                .tag(1)

            CalibrationTab(settings: settings)
                .tabItem {
                    Label("Calibrage", systemImage: "paintpalette")
                }
                .tag(2)
            
            MonitoredAppsTab(settings: settings)
                .tabItem {
                    Label("Apps Surveillées", systemImage: "app.badge.checkmark")
                }
                .tag(3)
            
            AppearanceTab(settings: settings)
                .tabItem {
                    Label("Apparence", systemImage: "paintbrush")
                }
                .tag(4)
            
            TimersTab(settings: settings)
                .tabItem {
                    Label("Minuteurs", systemImage: "timer")
                }
                .tag(5)
        }
        .frame(width: 560, height: 480)
        .id("settings-view-\(settings.appLanguage.rawValue)-\(LocalizationService.currentResolvedLanguageCode)-\(settings.appColorScheme.rawValue)")
        // Both are needed: .tint for SwiftUI components, .accentColor for native macOS TabView tabs
        .tint(settings.effectiveAccentColor ?? .accentColor)
        .accentColor(settings.effectiveAccentColor)
        .onChange(of: settings.appColorScheme) { _, newScheme in
            settings.applyColorScheme(newScheme)
        }
    }
}
