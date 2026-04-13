//
//  GlassCard.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

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
