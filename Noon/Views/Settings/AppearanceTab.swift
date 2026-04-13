//
//  AppearanceTab.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

struct AppearanceTab: View {
    @Bindable var settings: AppSettings
    
    @State private var previewState: MenuBarState = .normal
    
    private let presetColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Icon Style
                iconStyleSection
                
                // MARK: - Color Scheme
                colorSchemeSection
                
                // MARK: - Advanced
                advancedSection
                
                // MARK: - Color Pickers
                colorPickersSection
                
                // MARK: - Reset
                resetSection
            }
            .padding(24)
        }
    }
    
    // MARK: - Icon Style
    
    private var iconStyleSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Style de l'icône")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                
                HStack(spacing: 12) {
                    ForEach(MenuBarIconStyle.allCases) { style in
                        let isSelected = settings.menuBarIconStyle == style
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                settings.menuBarIconStyle = style
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: style.rawValue)
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(isSelected ? (settings.effectiveAccentColor ?? .accentColor) : .secondary)
                            }
                            .frame(width: 64, height: 56)
                            .background(
                                ZStack {
                                    if isSelected {
                                        (settings.effectiveAccentColor ?? .accentColor).opacity(0.1)
                                    }
                                    Rectangle().fill(.regularMaterial)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        isSelected ? (settings.effectiveAccentColor ?? .accentColor).opacity(0.8) : Color.primary.opacity(0.1),
                                        lineWidth: isSelected ? 1.5 : 0.5
                                    )
                            )
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                        
                        // Label below button
                        // (shown separately so label doesn't stretch button width)
                    }
                    Spacer()
                }
                
                // Labels row below buttons
                HStack(spacing: 0) {
                    ForEach(MenuBarIconStyle.allCases) { style in
                        let isSelected = settings.menuBarIconStyle == style
                        Text(style.displayName)
                            .font(.caption2)
                            .foregroundStyle(isSelected ? (settings.effectiveAccentColor ?? .accentColor) : .secondary)
                            .frame(width: 76, alignment: .leading)
                    }
                    Spacer()
                }
            }
            .padding(4)
        } label: {
            Label("Icône", systemImage: "star.circle")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Color Scheme
    
    private var colorSchemeSection: some View {
        GroupBox {
            HStack {
                Text("Apparence")
                Spacer()
                Picker("", selection: $settings.appColorScheme) {
                    ForEach(AppColorScheme.allCases) { scheme in
                        Text(scheme.displayName).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(4)
        } label: {
            Label("Mode d'affichage", systemImage: "circle.lefthalf.filled")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Advanced
    
    private var advancedSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                // Mode picker
                HStack {
                    Text("Couleur d'accent")
                    Spacer()
                    Picker("", selection: $settings.accentColorMode) {
                        ForEach(AccentColorMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                
                if settings.accentColorMode == .system {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentColor) // System accent
                            .frame(width: 32, height: 32)
                            .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accent système utilisé")
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                            Text("La couleur d'accent de votre macOS")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                } else {
                    // Custom Color Palette + Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Préréglages de couleur")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            
                        HStack(spacing: 12) {
                            ForEach(presetColors.prefix(7), id: \.self) { preset in
                                Circle()
                                    .fill(preset)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: settings.customAccentColor == preset ? 2 : 0)
                                            .padding(-2)
                                    )
                                    .onTapGesture {
                                        withAnimation { settings.customAccentColor = preset }
                                    }
                            }
                            Spacer()
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Choisir une couleur")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                Text("Sélectionnez n'importe quelle couleur")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            ColorPicker("", selection: $settings.customAccentColor, supportsOpacity: false)
                                .labelsHidden()
                        }
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Avancé", systemImage: "slider.horizontal.3")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    // MARK: - Color Pickers
    
    private var colorPickersSection: some View {
        GroupBox {
            VStack(spacing: 16) {
                colorPickerRow(
                    title: "État Normal",
                    subtitle: "True Tone / Night Shift sont actifs",
                    systemImage: "checkmark.circle.fill",
                    color: $settings.colorNormal,
                    previewColor: settings.colorNormal
                )
                
                Divider()
                
                colorPickerRow(
                    title: "Mode Créatif",
                    subtitle: "True Tone / Night Shift sont désactivés",
                    systemImage: "paintpalette.fill",
                    color: $settings.colorCreative,
                    previewColor: settings.colorCreative
                )
                
                Divider()
                
                colorPickerRow(
                    title: "Erreur / Alerte",
                    subtitle: "Une attention est requise",
                    systemImage: "exclamationmark.triangle.fill",
                    color: $settings.colorError,
                    previewColor: settings.colorError
                )
            }
            .padding(4)
        } label: {
            Label("Couleurs des états", systemImage: "paintbrush.fill")
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
        }
    }
    
    private func colorPickerRow(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImage: String,
        color: Binding<Color>,
        previewColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Preview icon
                Image(systemName: settings.menuBarIconStyle.rawValue)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(previewColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            
            // Palette + Picker
            HStack(spacing: 8) {
                ForEach(presetColors, id: \.self) { preset in
                    Circle()
                        .fill(preset)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: previewColor == preset ? 2 : 0)
                                .padding(-2)
                        )
                        .onTapGesture {
                            withAnimation { color.wrappedValue = preset }
                        }
                }
                
                Spacer()
                
                ColorPicker("", selection: color, supportsOpacity: false)
                    .labelsHidden()
            }
            .padding(.leading, 44)
        }
    }
    
    // MARK: - Reset
    
    private var resetSection: some View {
        HStack {
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3)) {
                    settings.resetAppearance()
                }
            } label: {
                Label("Réinitialiser les couleurs", systemImage: "arrow.counterclockwise")
                    .font(.system(.caption, design: .rounded))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(nil)
            .foregroundStyle(.primary)
        }
    }
}
