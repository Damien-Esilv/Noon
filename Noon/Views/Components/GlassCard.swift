//
//  GlassCard.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

// MARK: - GlassCard

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let material: Material
    let borderOpacity: Double
    let shadowRadius: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        cornerRadius: CGFloat = 14,
        padding: CGFloat = 16,
        material: Material = .ultraThinMaterial,
        borderOpacity: Double = 0.15,
        shadowRadius: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.material = material
        self.borderOpacity = borderOpacity
        self.shadowRadius = shadowRadius
        self.content = content
    }
    
    var body: some View {
        if #available(macOS 15.0, *) {
            content()
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(material)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(borderOpacity * 1.6), location: 0.0),
                                    .init(color: Color.white.opacity(borderOpacity * 0.4), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                        .blendMode(.overlay)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.04), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.07), radius: shadowRadius, x: 0, y: 3)
                .materialActiveAppearance(.matchWindow)
        } else {
            // macOS 14 fallback: standard uniform stroke and material
            content()
                .padding(padding)
                .background(material)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            Color.white.opacity(borderOpacity),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: shadowRadius, x: 0, y: 4)
        }
    }
}

// MARK: - Accent Glass Card

struct AccentGlassCard<Content: View>: View {
    let accentColor: Color
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        accentColor: Color = .accentColor,
        cornerRadius: CGFloat = 14,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accentColor = accentColor
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        if #available(macOS 15.0, *) {
            content()
                .padding(16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                        
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(accentColor.opacity(0.10))
                            .blendMode(.color)
                        
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.06), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blendMode(.plusLighter)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: accentColor.opacity(0.45), location: 0.0),
                                    .init(color: accentColor.opacity(0.15), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                        .blendMode(.overlay)
                )
                .shadow(color: accentColor.opacity(0.12), radius: 8, x: 0, y: 3)
                .materialActiveAppearance(.matchWindow)
        } else {
            // macOS 14 fallback: flat accent layer with ultraThinMaterial
            content()
                .padding(16)
                .background(
                    ZStack {
                        accentColor.opacity(0.08)
                        Rectangle().fill(.ultraThinMaterial)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            accentColor.opacity(0.2),
                            lineWidth: 0.5
                        )
                )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Glass Card")
                    .font(.headline)
                Text("Glassmorphism container")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        
        AccentGlassCard(accentColor: .orange) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(.orange)
                Text("Creative Mode Active")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    .padding()
    .frame(width: 300)
}
