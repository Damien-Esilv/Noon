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
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                }
                
                // Validity indicator
                if !app.isValid {
                    invalidBadge
                }
                
                // Delete button
                if isHovered, let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(rowBackground)
        // Ensure the entire rectangle is interactive, even the empty spaces
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.005 : 1.0)
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
                .materialActiveAppearance(.matchWindow)
        } else {
            // macOS 14 fallback: subtle primary fill on hover
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : .clear)
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
            // macOS 14 fallback
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
            // macOS 14 fallback
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
    
    var body: some View {
        if #available(macOS 15.0, *) {
            HStack(spacing: 10) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 0.5)
                }
                
                Text(app.name)
                    .font(.system(.caption, design: .rounded, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? .primary : .secondary)
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
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isActive ? Color.orange.opacity(0.06) : Color.clear)
                    .blendMode(.plusLighter)
            )
        } else {
            // macOS 14 fallback
            HStack(spacing: 10) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                
                Text(app.name)
                    .font(.system(.caption, design: .rounded, weight: isActive ? .semibold : .regular))
                    .lineLimit(1)
                
                Spacer()
                
                if isActive {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 4) {
        AppRowView(
            app: MonitoredApp(name: "Adobe Photoshop", bundleIdentifier: "com.adobe.Photoshop", path: "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app"),
            isRunning: true,
            onDelete: {}
        )
        
        AppRowView(
            app: MonitoredApp(name: "Missing App", bundleIdentifier: "com.missing.app", path: "/Applications/Missing.app"),
            isRunning: false,
            onDelete: {}
        )
        
        Divider()
        
        AppRowCompact(
            app: MonitoredApp(name: "Adobe Photoshop", bundleIdentifier: "com.adobe.Photoshop", path: "/Applications/Adobe Photoshop 2025/Adobe Photoshop 2025.app"),
            isActive: true
        )
        
        AppRowCompact(
            app: MonitoredApp(name: "DaVinci Resolve", bundleIdentifier: "com.blackmagic-design.DaVinciResolve", path: "/Applications/DaVinci Resolve/DaVinci Resolve.app"),
            isActive: false
        )
    }
    .padding()
    .frame(width: 400)
}
