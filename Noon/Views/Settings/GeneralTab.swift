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
    
    @State private var loginItemError: String?
    @State private var showAbout = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Status Overview
                statusCard
                
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
            .padding(24)
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
                        Text("Framework\nnon chargé")
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    private func featurePill(name: String, enabled: Bool, managed: Bool) -> some View {
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
                
                Picker(selection: $settings.appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                } label: {
                    Label("Langue de l'app", systemImage: "globe")
                }
                .frame(maxWidth: 300, alignment: .leading)
            }
            .padding(4)
        } label: {
            Label("Comportement", systemImage: "switch.2")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
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
                } else {
                    HStack {
                        Label("True Tone", systemImage: "sun.max.fill")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Non supporté sur cet écran")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Divider()
                
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
            .padding(4)
        } label: {
            Label("Fonctionnalités d'affichage", systemImage: "display")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Reactivation Mode
    
    private var reactivationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Picker(selection: $settings.reactivationMode) {
                    ForEach(ReactivationMode.allCases) { mode in
                        Label(mode.displayName, systemImage: mode.systemImage)
                            .tag(mode)
                    }
                } label: {
                    Text("Mode de réactivation")
                }
                .pickerStyle(.segmented)
                
                // Description of selected mode
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: settings.reactivationMode.systemImage)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    
                    Text(settings.reactivationMode.descriptionKey)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer(minLength: 0)
                }
                .padding(8)
                .background(.quaternary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .padding(4)
        } label: {
            Label("Réactivation", systemImage: "arrow.uturn.backward.circle")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Notifications
    
    private var notificationsSection: some View {
        GroupBox {
            HStack {
                Toggle(isOn: $settings.showNotifications) {
                    Label("Notifications macOS", systemImage: "bell.badge")
                }
                Spacer()
            }
            .padding(4)
        } label: {
            Label("Notifications", systemImage: "bell")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - About
    
    private var aboutSection: some View {
        GlassCard(material: .regularMaterial, shadowRadius: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Noon")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Display Color Manager for Creative Professionals")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Image(systemName: settings.menuBarIconStyle.rawValue)
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(settings.effectiveAccentColor ?? .accentColor)
            }
        }
    }
}
