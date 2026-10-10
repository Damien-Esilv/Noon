//
//  AppleHoverEffects.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

// MARK: - Apple Interactive Hover Effect Modifier

struct AppleHoverEffectModifier: ViewModifier {
    let scale: CGFloat
    let liftOffset: CGFloat
    let hoverTintOpacity: Double
    let cornerRadius: CGFloat
    
    @State private var isHovered = false
    
    init(
        scale: CGFloat = 1.012,
        liftOffset: CGFloat = -1.0,
        hoverTintOpacity: Double = 0.05,
        cornerRadius: CGFloat = 8
    ) {
        self.scale = scale
        self.liftOffset = liftOffset
        self.hoverTintOpacity = hoverTintOpacity
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? hoverTintOpacity : 0))
            )
            .scaleEffect(isHovered ? scale : 1.0)
            .offset(y: isHovered ? liftOffset : 0)
            .shadow(
                color: Color.black.opacity(isHovered ? 0.06 : 0.0),
                radius: isHovered ? 4 : 0,
                x: 0,
                y: isHovered ? 2 : 0
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Apple Interactive Button Style

struct AppleInteractiveButtonStyle: ButtonStyle {
    var hoverScale: CGFloat = 1.04
    var pressedScale: CGFloat = 0.96
    var cornerRadius: CGFloat = 8
    var activeBackground: Bool = true
    
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : (isHovered ? hoverScale : 1.0))
            .background(
                Group {
                    if activeBackground {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.primary.opacity(isHovered ? 0.08 : (configuration.isPressed ? 0.12 : 0)))
                    }
                }
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)
            .animation(.spring(response: 0.18, dampingFraction: 0.65), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies an Apple-grade subtle spring lift and highlight on hover.
    func appleHoverEffect(
        scale: CGFloat = 1.012,
        liftOffset: CGFloat = -1.0,
        hoverTintOpacity: Double = 0.05,
        cornerRadius: CGFloat = 8
    ) -> some View {
        self.modifier(AppleHoverEffectModifier(
            scale: scale,
            liftOffset: liftOffset,
            hoverTintOpacity: hoverTintOpacity,
            cornerRadius: cornerRadius
        ))
    }
    
    /// Applies a gentle row hover highlight typical of macOS native system apps.
    func appleRowHover(cornerRadius: CGFloat = 8) -> some View {
        self.modifier(AppleHoverEffectModifier(
            scale: 1.006,
            liftOffset: -0.5,
            hoverTintOpacity: 0.045,
            cornerRadius: cornerRadius
        ))
    }
}
