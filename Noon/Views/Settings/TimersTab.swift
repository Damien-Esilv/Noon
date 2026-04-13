//
//  TimersTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

struct TimersTab: View {
    @Bindable var settings: AppSettings
    
    // Preset durations in seconds
    private let presets: [(label: String, duration: TimeInterval)] = [
        ("1 min", 60),
        ("2 min", 120),
        ("5 min", 300),
        ("10 min", 600),
        ("15 min", 900),
        ("30 min", 1800),
    ]
    
    // Smart Slider Scale (1s to 15s by 1s, then by 10s to 5min, then by 1m to 30m)
    private var allowedDurations: [TimeInterval] {
        var values: [TimeInterval] = []
        for i in 1...15 { values.append(TimeInterval(i)) }
        for i in stride(from: 20, through: 300, by: 10) { values.append(TimeInterval(i)) }
        for i in stride(from: 360, through: 1800, by: 60) { values.append(TimeInterval(i)) }
        return values
    }
    
    private var sliderIndex: Binding<Double> {
        Binding<Double>(
            get: {
                let durations = allowedDurations
                let closestIndex = durations.firstIndex(where: { $0 >= settings.timerDuration }) ?? (durations.count - 1)
                return Double(closestIndex)
            },
            set: { newValue in
                let index = Int(newValue)
                let durations = allowedDurations
                if index >= 0 && index < durations.count {
                    settings.timerDuration = durations[index]
                }
            }
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Mode Info
                modeInfoCard
                
                // MARK: - Timer Duration
                timerDurationSection
                
                // MARK: - Presets
                presetsSection
                
                // MARK: - Options
                optionsSection
                
                // MARK: - Visual Preview
                visualPreviewSection
            }
            .padding(24)
        }
    }
    
    // MARK: - Mode Info
    
    private var modeInfoCard: some View {
        AccentGlassCard(
            accentColor: settings.reactivationMode == .timer ? (settings.effectiveAccentColor ?? .accentColor) : .gray
        ) {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(settings.reactivationMode == .timer ? (settings.effectiveAccentColor ?? .accentColor) : .secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Mode Minuteur")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                        
                        if settings.reactivationMode == .timer {
                            Text("ACTIF")
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(settings.effectiveAccentColor ?? .accentColor)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text("Un minuteur démarre lorsque vous quittez une app créative. Si vous y revenez avant la fin, le minuteur s'annule.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Duration
    
    private var timerDurationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Délai de réactivation")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                    
                    Spacer()
                    
                    Text(formattedDuration)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(settings.effectiveAccentColor ?? .accentColor)
                        .monospacedDigit()
                }
                
                // Smart Slider
                Slider(
                    value: sliderIndex,
                    in: 0...Double(allowedDurations.count - 1),
                    step: 1
                ) {
                    Text("Durée")
                } minimumValueLabel: {
                    Text("1s")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } maximumValueLabel: {
                    Text("30m")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .tint(settings.effectiveAccentColor ?? .accentColor)
                
                // Fine adjustments text hint
                HStack {
                    Text("L'échelle s'adapte automatiquement : 1s -> 10s -> 1min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
            }
            .padding(4)
        } label: {
            Label("Durée", systemImage: "clock.arrow.circlepath")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Presets
    
    private var presetsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Préréglages rapides")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(presets, id: \.duration) { preset in
                        let isSelected = abs(settings.timerDuration - preset.duration) < 1
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                settings.timerDuration = preset.duration
                            }
                        } label: {
                            Text(preset.label)
                                .font(.system(.subheadline, design: .rounded, weight: isSelected ? .bold : .regular))
                                .foregroundStyle(isSelected ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSelected ? (settings.effectiveAccentColor ?? .accentColor) : Color.primary.opacity(0.05))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Préréglages", systemImage: "dial.low")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Options
    
    private var optionsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $settings.resetTimerOnReturn) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Annuler le minuteur au retour")
                        Text("Le minuteur est remis à zéro si vous revenez sur une app créative")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Divider()
                
                Toggle(isOn: $settings.showTimerInMenuBar) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Compte à rebours dans la barre des menus")
                        Text("Affiche le temps restant à côté de l'icône")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Options", systemImage: "slider.horizontal.3")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Visual Preview
    
    private var visualPreviewSection: some View {
        GlassCard(material: .regularMaterial) {
            VStack(spacing: 12) {
                Text("Fonctionnement")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 0) {
                    // Step 1
                    timelineStep(
                        icon: "paintpalette.fill",
                        color: .orange,
                        label: "App créative\nen premier plan",
                        isActive: true
                    )
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                    
                    // Step 2
                    timelineStep(
                        icon: "timer",
                        color: settings.effectiveAccentColor ?? .accentColor,
                        label: "Minuteur\n\(formattedDuration)",
                        isActive: true
                    )
                    
                    // Arrow
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                    
                    // Step 3
                    timelineStep(
                        icon: "sun.min",
                        color: .blue,
                        label: "True Tone\nréactivé",
                        isActive: true
                    )
                }
            }
        }
    }
    
    private func timelineStep(icon: String, color: Color, label: String, isActive: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helpers
    
    private var formattedDuration: String {
        let minutes = Int(settings.timerDuration) / 60
        let seconds = Int(settings.timerDuration) % 60
        if seconds == 0 {
            return "\(minutes) min"
        }
        return "\(minutes)m \(seconds)s"
    }
}
