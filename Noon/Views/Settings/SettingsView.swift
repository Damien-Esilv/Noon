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
            
            MonitoredAppsTab(settings: settings)
                .tabItem {
                    Label("Apps Surveillées", systemImage: "app.badge.checkmark")
                }
                .tag(1)
            
            AppearanceTab(settings: settings)
                .tabItem {
                    Label("Apparence", systemImage: "paintbrush")
                }
                .tag(2)
            
            TimersTab(settings: settings)
                .tabItem {
                    Label("Minuteurs", systemImage: "timer")
                }
                .tag(3)
        }
        .frame(width: 520, height: 420)
        .id("settings-view-\(settings.appLanguage.rawValue)")
        // Both are needed: .tint for SwiftUI components, .accentColor for native macOS TabView tabs
        .tint(settings.effectiveAccentColor ?? .accentColor)
        .accentColor(settings.effectiveAccentColor)
    }
}
