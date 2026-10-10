//
//  DynamicHUDView.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

public struct DynamicHUDView: View {
    public let isCreativeMode: Bool
    public let activePreset: AppleReferencePreset?
    public let is100NitsLocked: Bool
    public let isLightingDriftExceeded: Bool
    public let driftPercentage: Double

    public init(
        isCreativeMode: Bool,
        activePreset: AppleReferencePreset? = nil,
        is100NitsLocked: Bool = false,
        isLightingDriftExceeded: Bool = false,
        driftPercentage: Double = 0.0
    ) {
        self.isCreativeMode = isCreativeMode
        self.activePreset = activePreset
        self.is100NitsLocked = is100NitsLocked
        self.isLightingDriftExceeded = isLightingDriftExceeded
        self.driftPercentage = driftPercentage
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Creative status badge
            ZStack {
                Circle()
                    .fill(isCreativeMode ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: isCreativeMode ? "sun.max.fill" : "sun.min")
                    .foregroundColor(isCreativeMode ? .accentColor : .secondary)
                    .font(.system(size: 16, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(isCreativeMode ? "Mode Créatif Actif" : "Mode Standard")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))

                    if is100NitsLocked {
                        Text("100 NITS")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }

                if let preset = activePreset {
                    Text(preset.displayName)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                if isLightingDriftExceeded {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Dérive lumineuse ambiante (+\(Int(driftPercentage))%)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isCreativeMode ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        .frame(minWidth: 260)
    }
}
