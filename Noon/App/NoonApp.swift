//
//  NoonApp.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import AppKit

@main
struct NoonApp: App {
    
    // MARK: - Services
    
    @State private var settings = AppSettings.shared
    @State private var displayService = DisplayService()
    @State private var notificationService = NotificationService.shared
    @State private var monitorService: AppMonitorService?
    
    @State private var showSettings = false
    
    // MARK: - Body
    
    var body: some Scene {
        
        // MARK: - Menu Bar
        MenuBarExtra {
            if let monitor = monitorService {
                MenuBarView(
                    monitorService: monitor,
                    displayService: displayService,
                    settings: settings
                )
                .id("menubar-\(settings.appLanguage.rawValue)-\(settings.appColorScheme.rawValue)")
                .tint(settings.effectiveAccentColor)
                .preferredColorScheme(settings.appColorScheme == .system ? nil : (settings.appColorScheme == .light ? .light : .dark))
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Initialisation...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
            }
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
        // Inject dynamic locale to auto-translate SwiftUI components
        .environment(\.locale, settings.selectedLocale)
        
        // MARK: - Settings Window
        Settings {
            if let monitor = monitorService {
                SettingsView(
                    displayService: displayService,
                    monitorService: monitor,
                    settings: settings
                )
                .id("settings-\(settings.appLanguage.rawValue)-\(settings.appColorScheme.rawValue)")
                .environment(\.locale, settings.selectedLocale)
                .tint(settings.effectiveAccentColor)
                .preferredColorScheme(settings.appColorScheme == .system ? nil : (settings.appColorScheme == .light ? .light : .dark))
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NSApp.setActivationPolicy(.regular)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                .onDisappear {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
    }
    
    // MARK: - Menu Bar Icon
    
    @ViewBuilder
    private var menuBarLabel: some View {
        HStack(spacing: 4) {
            // Dynamic icon based on state
            Image(systemName: currentIconName)
                .symbolRenderingMode(.hierarchical)
            
            // Timer countdown in menu bar (if enabled)
            if settings.showTimerInMenuBar,
               let monitor = monitorService,
               case .timerActive = monitor.currentState {
                Text(monitor.formattedTimerRemaining)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .monospacedDigit()
            }
        }
        .onAppear {
            initializeServices()
        }
    }
    
    // MARK: - Icon Logic
    
    private var currentIconName: String {
        guard let monitor = monitorService else {
            return settings.menuBarIconStyle.rawValue
        }
        
        switch monitor.currentState {
        case .normal:
            return settings.menuBarIconStyle.rawValue
        case .creativeMode:
            // Use the filled variant when in creative mode
            return settings.menuBarIconStyle == .sunMin ? "sun.min.fill" : "sun.min"
        case .error:
            return "exclamationmark.triangle.fill"
        case .timerActive:
            return "timer"
        case .paused:
            return "pause.circle"
        }
    }
    
    // MARK: - Initialization
    
    private func initializeServices() {
        guard monitorService == nil else { return }
        
        // Request notification permissions
        notificationService.requestPermission()
        
        // Initialize monitor service
        let monitor = AppMonitorService(
            displayService: displayService,
            settings: settings,
            notificationService: notificationService
        )
        monitorService = monitor
        
        // Ensure starting in accessory mode
        NSApp.setActivationPolicy(.accessory)
        
        // Start monitoring
        monitor.startMonitoring()

        
        // Initial app validation
        let invalidApps = settings.validateAndRepairApps()
        if !invalidApps.isEmpty && settings.showNotifications {
            for app in invalidApps {
                notificationService.sendAppNotFoundNotification(app: app)
            }
        }
        
        // Sync login item state
        settings.launchAtLogin = LoginItemService.shared.isEnabled
    }

    // MARK: - Automation & URL Routing (noon://)

    private func handleIncomingURL(_ url: URL) {
        guard let command = NoonCommandRouter.shared.parseURL(url) else { return }

        Task { @MainActor in
            switch command {
            case .toggleCreativeMode:
                if DisplayManager.shared.isCreativeModeActive {
                    await DisplayManager.shared.restoreNormalInterventions()
                    displayService.restoreFromCreativeMode(settings: settings)
                } else {
                    let config = PerAppActionConfig(
                        manageAutoBrightness: settings.manageAutoBrightness,
                        calibrationTarget: settings.lock100NitsCalibration ? .appleRecommended : .sliderPercent(1.0)
                    )
                    await DisplayManager.shared.applyCreativeInterventions(for: config)
                    displayService.disableForCreativeMode(settings: settings)
                }

            case .enableCreativeMode:
                let config = PerAppActionConfig(
                    manageAutoBrightness: settings.manageAutoBrightness,
                    calibrationTarget: settings.lock100NitsCalibration ? .appleRecommended : .sliderPercent(1.0)
                )
                await DisplayManager.shared.applyCreativeInterventions(for: config)
                displayService.disableForCreativeMode(settings: settings)

            case .disableCreativeMode:
                await DisplayManager.shared.restoreNormalInterventions()
                displayService.restoreFromCreativeMode(settings: settings)

            case .setPreset(let preset):
                if let mainScreen = NSScreen.main,
                   let id = mainScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                    try? await ApplePresetController.shared.setActivePreset(preset, for: id)
                }

            case .setCalibratedBrightness(let target):
                let config = PerAppActionConfig(calibrationTarget: target)
                await DisplayManager.shared.applyCreativeInterventions(for: config)

            case .setBrightness(let val):
                if let mainScreen = NSScreen.main,
                   let id = mainScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
                    try? await BrightnessManager.shared.setBrightness(val, for: id)
                }

            case .statusQuery:
                break
            }
        }
    }
}
