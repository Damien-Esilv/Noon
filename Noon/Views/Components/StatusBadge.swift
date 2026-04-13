//
//  StatusBadge.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

struct StatusBadge: View {
    let state: MenuBarState
    let settings: AppSettings
    let size: CGFloat
    
    @State private var isPulsing = false
    
    init(state: MenuBarState, settings: AppSettings, size: CGFloat = 10) {
        self.state = state
        self.settings = settings
        self.size = size
    }
    
    private var color: Color {
        switch state {
        case .normal:       return settings.colorNormal
        case .creativeMode: return settings.colorCreative
        case .error:        return settings.colorError
        case .timerActive:  return settings.colorCreative.opacity(0.8)
        case .paused:       return .gray
        }
    }
    
    private var shouldPulse: Bool {
        switch state {
        case .creativeMode, .error, .timerActive: return true
        default: return false
        }
    }
    
    var body: some View {
        ZStack {
            // Outer pulse ring
            if shouldPulse {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * 2, height: size * 2)
                    .scaleEffect(isPulsing ? 1.3 : 0.8)
                    .opacity(isPulsing ? 0 : 0.6)
            }
            
            // Inner dot
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
        }
        .onAppear {
            if shouldPulse {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: state) { _, newState in
            isPulsing = false
            if shouldPulse {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Status Label

struct StatusLabel: View {
    let state: MenuBarState
    let settings: AppSettings
    
    var body: some View {
        HStack(spacing: 8) {
            StatusBadge(state: state, settings: settings)
            
            Text(state.displayName)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StatusLabel(state: .normal, settings: .shared)
        StatusLabel(state: .creativeMode, settings: .shared)
        StatusLabel(state: .error("Test"), settings: .shared)
        StatusLabel(state: .timerActive(120), settings: .shared)
        StatusLabel(state: .paused, settings: .shared)
    }
    .padding(30)
}
