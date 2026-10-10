//
//  CalibrationTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import AppKit

struct CalibrationTab: View {
    @Bindable var settings: AppSettings
    @State private var availableProfiles: [String] = []
    @State private var displayManager = DisplayManager.shared

    private let standardAppleProfiles: Set<String> = [
        "Display P3", "sRGB", "Adobe RGB (1998)", "Rec. 709", "Rec. 2020", "DCI-P3"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Calibration Mode Header & Toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profils Colorimétriques & Étalonnage")
                        .font(.headline)

                    Text("Gérez la fidélité des couleurs de votre écran pour vos créations graphiques et vidéos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle(isOn: $settings.enableCreativeColorProfile) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Activer le profil de calibration en mode créatif")
                                .font(.body)
                            Text("Applique automatiquement votre profil d'écran étalonné dès qu'une application ou un site surveillé est actif.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: - Target Calibration Profile Selector
                if settings.enableCreativeColorProfile {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profil d'étalonnage cible")
                            .font(.headline)

                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Image(systemName: "paintpalette.fill")
                                        .font(.title2)
                                        .foregroundStyle(settings.effectiveAccentColor ?? .accentColor)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Profil d'étalonnage sélectionné")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Picker("", selection: $settings.creativeColorProfileName) {
                                            if !customCalibrationProfiles.isEmpty {
                                                Section("Profils personnalisés (Sondes & Outils externes)") {
                                                    ForEach(customCalibrationProfiles, id: \.self) { profile in
                                                        Text(profile).tag(profile)
                                                    }
                                                }
                                            }

                                            Section("Profils standard Apple & Industrie") {
                                                ForEach(standardProfilesList, id: \.self) { profile in
                                                    Text(profile).tag(profile)
                                                }
                                            }
                                        }
                                        .labelsHidden()
                                    }
                                }

                                Divider()

                                HStack {
                                    Button {
                                        Task {
                                            await refreshProfiles()
                                        }
                                    } label: {
                                        Label("Rafraîchir les profils", systemImage: "arrow.clockwise")
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)

                                    Spacer()

                                    Button {
                                        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    } label: {
                                        Label("Ouvrir les réglages Moniteurs macOS...", systemImage: "display")
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                }

                                Text("Les profils créés avec des sondes tierces (Calibrite, Spyder, etc.) ou l'assistant macOS sont automatiquement pris en charge.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }
                    }
                }

                // MARK: - Apple XDR Reference Presets (if applicable)
                if displayManager.connectedDisplays.contains(where: { $0.isXDR }) {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Préréglages de Référence Apple XDR")
                            .font(.headline)

                        Text("Sur les écrans Apple Pro Display XDR ou Liquid Retina XDR, les préréglages studio verrouillent matériellement le point blanc et la courbe gamma.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(displayManager.connectedDisplays.filter { $0.isXDR }) { display in
                            GlassCard {
                                HStack {
                                    Image(systemName: "sparkles.tv")
                                        .font(.title2)
                                        .foregroundStyle(.purple)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(display.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        if let preset = display.activeReferencePreset {
                                            Text(preset.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(6)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .task {
            await refreshProfiles()
        }
    }

    private var customCalibrationProfiles: [String] {
        availableProfiles.filter { !standardAppleProfiles.contains($0) }
    }

    private var standardProfilesList: [String] {
        let list = availableProfiles.filter { standardAppleProfiles.contains($0) }
        return list.isEmpty ? ["Display P3", "sRGB", "Adobe RGB (1998)", "Rec. 709"] : list
    }

    private func refreshProfiles() async {
        let profiles = await ColorSyncController.shared.availableStandardProfiles()
        await MainActor.run {
            self.availableProfiles = profiles
            if !profiles.contains(settings.creativeColorProfileName), let first = profiles.first {
                settings.creativeColorProfileName = first
            }
        }
    }
}
