//
//  DisplaysTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

struct DisplaysTab: View {
    @Bindable var settings: AppSettings
    @State private var displayManager = DisplayManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Connected Displays Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Écrans Détectés")
                        .font(.headline)

                    Text("Activez ou désactivez la gestion des couleurs et de la calibration pour chaque écran.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if displayManager.connectedDisplays.isEmpty {
                        GlassCard {
                            HStack {
                                Image(systemName: "display.trianglebadge.exclamationmark")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Aucun écran détecté.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                        }
                    } else {
                        ForEach(displayManager.connectedDisplays) { display in
                            GlassCard {
                                HStack(spacing: 12) {
                                    Image(systemName: display.isBuiltin ? "laptopcomputer" : "display")
                                        .font(.title2)
                                        .foregroundStyle(display.isManagementEnabled ? (settings.effectiveAccentColor ?? .accentColor) : .secondary)

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(display.name)
                                                .font(.headline)

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
                                        }
                                    ))
                                    .labelsHidden()
                                }
                                .padding(6)
                            }
                        }
                    }
                }

                Divider()

                // MARK: - Calibration & Brightness Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Calibration & Luminance")
                        .font(.headline)

                    Toggle(isOn: $settings.lock100NitsCalibration) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Verrouiller la calibration standard (100 Nits / 50%)")
                                .font(.body)
                            Text("Applique 100 nits sur écrans XDR (standard studio SDR) ou 50% sur écrans Retina standards.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $settings.manageAutoBrightness) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Désactiver le réglage automatique de luminosité")
                                .font(.body)
                            Text("Maintient une intensité lumineuse constante pendant l'exécution des apps créatives.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                // MARK: - Advanced Monitoring & HUD
                VStack(alignment: .leading, spacing: 10) {
                    Text("Outils Web & Environnement")
                        .font(.headline)

                    Toggle(isOn: $settings.monitorWebApps) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Surveiller les outils créatifs Web (Figma, Canva, Photopea)")
                                .font(.body)
                            Text("Active automatiquement le mode créatif lors de l'utilisation d'onglets de design dans Safari, Chrome, Arc ou Edge.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $settings.enableAmbientLightMonitoring) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Surveillance de la lumière ambiante")
                                .font(.body)
                            Text("Alerte en cas de variation lumineuse dans la pièce risquant de fausser l'évaluation des couleurs.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Toggle(isOn: $settings.showHUDOnSwitch) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Afficher l'indicateur visuel dynamique (HUD)")
                                .font(.body)
                            Text("Affiche brièvement une bannière sous l'encoche confirmant le profil de fidélité et la calibration.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}
