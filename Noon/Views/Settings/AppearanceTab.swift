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
                
                // MARK: - Popup Background Style
                popupStyleSection

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
                        iconStyleButton(style: style, isSelected: isSelected)
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
    
    private func iconStyleButton(style: MenuBarIconStyle, isSelected: Bool) -> some View {
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
            .modifier(IconStyleCardModifier(
                isSelected: isSelected,
                accentColor: settings.effectiveAccentColor ?? .accentColor
            ))
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Popup Background Style
    
    private var popupStyleSection: some View {
        GroupBox {
            HStack {
                Text("Style de la fenêtre")
                Spacer()
                Picker("", selection: $settings.popupMaterialStyle) {
                    ForEach(PopupMaterialStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize(horizontal: true, vertical: false)
            }
            .padding(4)
        } label: {
            Label("Menu de la barre d'état", systemImage: "macwindow")
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
                .fixedSize(horizontal: true, vertical: false)
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
                    .fixedSize(horizontal: true, vertical: false)
                }
                
                if settings.accentColorMode == .system {
                    HStack(spacing: 12) {
                        systemAccentSwatch
                        
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
                                presetColorSwatch(preset: preset)
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
    
    @ViewBuilder
    private var systemAccentSwatch: some View {
        if #available(macOS 15.0, *) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)
                )
                .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
        } else {
            // macOS 14 fallback
            Circle()
                .fill(Color.accentColor)
                .frame(width: 32, height: 32)
                .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
    }
    
    @ViewBuilder
    private func presetColorSwatch(preset: Color) -> some View {
        let isSelected = settings.customAccentColor == preset
        if #available(macOS 15.0, *) {
            Circle()
                .fill(preset)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.primary.opacity(0.35) : Color.white.opacity(0.15),
                            lineWidth: isSelected ? 2 : 0.5
                        )
                        .blendMode(.overlay)
                        .padding(isSelected ? -2 : 0)
                )
                .shadow(color: preset.opacity(isSelected ? 0.35 : 0.1), radius: 3, x: 0, y: 1)
                .onTapGesture {
                    withAnimation { settings.customAccentColor = preset }
                }
        } else {
            // macOS 14 fallback
            Circle()
                .fill(preset)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: isSelected ? 2 : 0)
                        .padding(-2)
                )
                .onTapGesture {
                    withAnimation { settings.customAccentColor = preset }
                }
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
                // Preview icon container
                previewIconContainer(previewColor: previewColor)
                
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
                    let isCurrentColor = previewColor == preset
                    Circle()
                        .fill(preset)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.2), lineWidth: isCurrentColor ? 2 : 0)
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
    
    @ViewBuilder
    private func previewIconContainer(previewColor: Color) -> some View {
        if #available(macOS 15.0, *) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(previewColor.opacity(0.12))
                            .blendMode(.color)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(previewColor.opacity(0.3), lineWidth: 0.5)
                            .blendMode(.overlay)
                    )
                
                Image(systemName: settings.menuBarIconStyle.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(previewColor)
            }
            .frame(width: 32, height: 32)
        } else {
            // macOS 14 fallback
            Image(systemName: settings.menuBarIconStyle.rawValue)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(previewColor)
                .frame(width: 32)
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

// MARK: - Icon Style Card Modifier

private struct IconStyleCardModifier: ViewModifier {
    let isSelected: Bool
    let accentColor: Color
    
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.regularMaterial)
                        
                        if isSelected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(accentColor.opacity(0.12))
                                .blendMode(.color)
                            
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [accentColor.opacity(0.15), accentColor.opacity(0.02)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .blendMode(.plusLighter)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(
                                        color: isSelected ? accentColor.opacity(0.8) : Color.white.opacity(0.15),
                                        location: 0.0
                                    ),
                                    .init(
                                        color: isSelected ? accentColor.opacity(0.4) : Color.white.opacity(0.05),
                                        location: 1.0
                                    )
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                        .blendMode(.overlay)
                )
                .shadow(
                    color: isSelected ? accentColor.opacity(0.2) : Color.black.opacity(0.06),
                    radius: isSelected ? 6 : 3,
                    x: 0,
                    y: 2
                )
                .materialActiveAppearance(.matchWindow)
        } else {
            // macOS 14 fallback
            content
                .background(
                    ZStack {
                        if isSelected {
                            accentColor.opacity(0.1)
                        }
                        Rectangle().fill(.regularMaterial)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isSelected ? accentColor.opacity(0.8) : Color.primary.opacity(0.1),
                            lineWidth: isSelected ? 1.5 : 0.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        }
    }
}
