//
//  BrightnessTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

struct BrightnessTab: View {
    @Bindable var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Creative Brightness Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Luminosité en Mode Créatif")
                        .font(.headline)

                    Toggle(isOn: $settings.enablePresetBrightness) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Luminosité prédéfinie en mode créatif")
                                .font(.body)
                            Text("Réglez librement votre écran au quotidien. Dès qu'une application ou un site surveillé est actif, la luminosité s'ajuste automatiquement à ce niveau.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if settings.enablePresetBrightness {
                        HStack(spacing: 12) {
                            Image(systemName: "sun.min")
                                .foregroundStyle(.secondary)
                            Slider(value: $settings.presetBrightnessLevel, in: 0.1...1.0, step: 0.05)
                            Image(systemName: "sun.max")
                                .foregroundStyle(.secondary)
                            Text("\(Int(settings.presetBrightnessLevel * 100))%")
                                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                                .frame(width: 44, alignment: .trailing)
                        }
                        .padding(.leading, 24)
                        .padding(.vertical, 2)
                    }

                    Toggle(isOn: $settings.lock100NitsCalibration) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Verrouiller la calibration standard (100 Nits / 50%)")
                                .font(.body)
                            Text("Applique 100 nits sur écrans XDR (standard studio SDR) ou 50% sur écrans Retina standards.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(settings.enablePresetBrightness)
                    .opacity(settings.enablePresetBrightness ? 0.5 : 1.0)

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

                // MARK: - Environment & Display
                VStack(alignment: .leading, spacing: 10) {
                    Text("Environnement & Affichage")
                        .font(.headline)

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
