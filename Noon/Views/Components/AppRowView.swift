//
//  AppRowView.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

// MARK: - AppRowView

struct AppRowView: View {
    let app: MonitoredApp
    let isRunning: Bool
    var onDelete: (() -> Void)?
    
    @State private var isHovered = false
    @State private var isDeleteHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon with subtle Apple hover scale
            Group {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .shadow(color: .black.opacity(isHovered ? 0.16 : 0.08), radius: isHovered ? 3 : 1.5, x: 0, y: isHovered ? 1.5 : 1)
                } else {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(.quaternary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "app.dashed")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 16))
                        )
                }
            }
            .scaleEffect(isHovered ? 1.06 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isHovered)
            
            // App Info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .lineLimit(1)
                
                Text(app.bundleIdentifier)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Status indicators
            HStack(spacing: 8) {
                // Running indicator
                if isRunning {
                    runningBadge
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Validity indicator
                if !app.isValid {
                    invalidBadge
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Delete button with spring micro-interaction
                if isHovered, let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(isDeleteHovered ? .red : .secondary)
                            .scaleEffect(isDeleteHovered ? 1.15 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isDeleteHovered)
                    }
                    .buttonStyle(.plain)
                    .onHover { isDeleteHovered = $0 }
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .offset(y: isHovered ? -0.5 : 0)
    }
    
    // MARK: - Row Background (macOS 15 vs macOS 14)
    
    @ViewBuilder
    private var rowBackground: some View {
        if #available(macOS 15.0, *) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.thinMaterial)
                .opacity(isHovered ? 0.95 : 0.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.18), location: 0.0),
                                    .init(color: Color.white.opacity(0.04), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                        .blendMode(.overlay)
                        .opacity(isHovered ? 1.0 : 0.0)
                )
                .shadow(color: Color.black.opacity(isHovered ? 0.06 : 0.0), radius: 4, x: 0, y: 2)
                .materialActiveAppearance(.matchWindow)
        } else {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.05) : .clear)
        }
    }
    
    // MARK: - Badges
    
    @ViewBuilder
    private var runningBadge: some View {
        if #available(macOS 15.0, *) {
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: .green.opacity(0.4), radius: 2)
                Text("Active")
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill(Color.green.opacity(0.12))
                            .blendMode(.color)
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.green.opacity(0.3), lineWidth: 0.5)
                    .blendMode(.overlay)
            )
        } else {
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Active")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.green.opacity(0.1))
            .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    private var invalidBadge: some View {
        if #available(macOS 15.0, *) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                Text("Introuvable")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .fill(Color.red.opacity(0.12))
                            .blendMode(.color)
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.red.opacity(0.3), lineWidth: 0.5)
                    .blendMode(.overlay)
            )
        } else {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.red)
                Text("Introuvable")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.red.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Compact Row (for Menu Bar popover)

struct AppRowCompact: View {
    let app: MonitoredApp
    let isActive: Bool
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06), radius: 1.5, x: 0, y: 0.5)
                    .scaleEffect(isHovered ? 1.08 : 1.0)
            }
            
            Text(app.name)
                .font(.system(.caption, design: .rounded, weight: isActive ? .semibold : .regular))
                .foregroundStyle(isActive ? .primary : (isHovered ? .primary : .secondary))
                .lineLimit(1)
            
            Spacer()
            
            if isActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: .orange.opacity(0.5), radius: 2)
                    
                    Text("Actif")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .fill(Color.orange.opacity(0.14))
                                .blendMode(.color)
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.orange.opacity(0.3), lineWidth: 0.5)
                        .blendMode(.overlay)
                )
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isActive ? Color.orange.opacity(0.08) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
        )
        .contentShape(Rectangle())
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
