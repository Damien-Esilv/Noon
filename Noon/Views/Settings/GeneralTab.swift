//
//  GeneralTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

struct GeneralTab: View {
    @Bindable var settings: AppSettings
    let displayService: DisplayService
    let monitorService: AppMonitorService
    
    @State private var displayManager = DisplayManager.shared
    @State private var loginItemError: String?
    @State private var showAbout = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Status Overview
                statusCard
                
                // MARK: - Detected Displays
                detectedDisplaysSection
                
                // MARK: - Launch & Behavior
                behaviorSection
                
                // MARK: - Display Features
                displayFeaturesSection
                
                // MARK: - Reactivation Mode
                reactivationSection
                
                // MARK: - Notifications
                notificationsSection
                
                // MARK: - About
                aboutSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .task {
            displayManager.refreshConnectedDisplays()
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        GlassCard(material: .regularMaterial) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: monitorService.currentState.systemImage(for: settings.menuBarIconStyle))
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("État actuel")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text(monitorService.currentState.displayName)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    
                    HStack(spacing: 12) {
                        if displayService.isTrueToneSupported {
                            featurePill(
                                name: "True Tone",
                                enabled: displayService.isTrueToneEnabled,
                                managed: settings.manageTrueTone
                            )
                        }
                        featurePill(
                            name: "Night Shift",
                            enabled: displayService.isNightShiftEnabled,
                            managed: settings.manageNightShift
                        )
                    }
                }
                
                Spacer()
                
                if !displayService.isFrameworkLoaded {
                    VStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.title3)
                        Text("Framework non chargé")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    private func featurePill(name: LocalizedStringKey, enabled: Bool, managed: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(managed ? (enabled ? .green : .red.opacity(0.7)) : .red.opacity(0.7))
                .frame(width: 5, height: 5)
            Text(name)
                .font(.caption2)
                .foregroundStyle(managed ? .primary : .quaternary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.3))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch monitorService.currentState {
        case .normal:
            return settings.colorNormal
        case .creativeMode:
            return settings.colorCreative
        case .error:
            return settings.colorError
        case .timerActive:
            return .orange
        case .paused:
            return .gray
        }
    }
    
    // MARK: - Detected Displays Section
    
    private var detectedDisplaysSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cochez les écrans que vous souhaitez gérer avec Noon lors de l'exécution d'applications créatives.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if displayManager.connectedDisplays.isEmpty {
                    HStack {
                        Image(systemName: "display.trianglebadge.exclamationmark")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("Aucun écran détecté.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                } else {
                    VStack(spacing: 8) {
                        ForEach(displayManager.connectedDisplays) { display in
                            HStack(spacing: 12) {
                                Image(systemName: display.isBuiltin ? "laptopcomputer" : "display")
                                    .font(.title2)
                                    .foregroundStyle(display.isManagementEnabled ? (settings.effectiveAccentColor ?? .accentColor) : .secondary)
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(display.name)
                                            .font(.system(.body, design: .rounded, weight: .semibold))
                                        
                                        if display.isXDR {
                                            Text("XDR")
                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.purple.opacity(0.2))
                                                .foregroundColor(.purple)
                                                .clipShape(Capsule())
                                        }
                                        
                                        if display.supportsDDC {
                                            Text("DDC/CI")
                                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    
                                    HStack(spacing: 8) {
                                        if let preset = display.activeReferencePreset {
                                            Text(preset.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        if let profile = display.activeColorProfileName {
                                            Text("• \(profile)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { display.isManagementEnabled },
                                    set: { enabled in
                                        displayManager.setManagementEnabled(enabled, for: display.id)
                                        if !enabled {
                                            displayService.restoreUnmanagedFeaturesIfNeeded(settings: settings)
                                        } else if displayService.isSuppressed {
                                            displayService.disableForCreativeMode(settings: settings)
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.03))
                            )
                        }
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Écrans Détectés", systemImage: "display.2")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Behavior
    
    private var behaviorSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Toggle(isOn: $settings.launchAtLogin) {
                        Label("Lancer au démarrage", systemImage: "power")
                    }
                    .onChange(of: settings.launchAtLogin) { _, newValue in
                        do {
                            try LoginItemService.shared.setEnabled(newValue)
                            loginItemError = nil
                        } catch {
                            loginItemError = error.localizedDescription
                            settings.launchAtLogin = !newValue
                        }
                    }
                    
                    Spacer()
                    
                    Link(destination: URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!) {
                        Image(systemName: "arrow.up.right.square")
                    }
                    .help("Ouvrir les réglages du Mac")
                }
                
                if let error = loginItemError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Toggle(isOn: $settings.soundOnToggle) {
                    Label("Son lors du basculement", systemImage: "speaker.wave.2")
                }
                
                Divider()
                
                HStack {
                    Label("Langue de l'app", systemImage: "globe")
                    Spacer()
                    Picker("", selection: $settings.appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            Label("Comportement", systemImage: "switch.2")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Display Features
    
    private var displayFeaturesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                if displayService.isTrueToneSupported {
                    Toggle(isOn: $settings.manageTrueTone) {
                        HStack {
                            Label("Gérer True Tone", systemImage: "sun.max.fill")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Désactive True Tone en mode créatif")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                
                Toggle(isOn: $settings.manageNightShift) {
                    HStack {
                        Label("Gérer Night Shift", systemImage: "moon.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("Désactive Night Shift en mode créatif")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            Label("Fonctionnalités d'affichage", systemImage: "display")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Reactivation Mode
    
    private var reactivationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Mode de réactivation", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Picker("", selection: $settings.reactivationMode) {
                        ForEach(ReactivationMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                Text(settings.reactivationMode.descriptionKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            Label("Réactivation", systemImage: "clock.arrow.circlepath")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Notifications
    
    private var notificationsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $settings.showNotifications) {
                    HStack {
                        Label("Activer les notifications", systemImage: "bell.badge")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("Prévenir lors des changements d'état")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(4)
        } label: {
            Label("Notifications", systemImage: "bell")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - About
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var aboutSection: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Noon")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                    Text("Version \(appVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Made by Sunazur")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Button("À propos") {
                    showAbout = true
                }
                .buttonStyle(.bordered)
            }
            .padding(4)
        } label: {
            Label("À propos", systemImage: "info.circle")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showAbout) {
            aboutSheet
        }
    }
    
    private var aboutSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 48))
                .foregroundStyle(settings.effectiveAccentColor ?? .orange)
            
            Text("Noon")
                .font(.system(.title2, design: .rounded, weight: .bold))
            
            Text("Désactive automatiquement True Tone et Night Shift lorsque vous lancez des applications créatives.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    Text("Version")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                }
                
                HStack {
                    Text("Build")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                }
                
                HStack {
                    Text("Auteur")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Sunazur")
                }
                
                HStack {
                    Text("Licence")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("CC BY-NC-SA 4.0")
                }
            }
            .font(.caption)
            
            Divider()
            
            Button("Fermer") {
                showAbout = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(24)
        .frame(width: 320)
    }
}
