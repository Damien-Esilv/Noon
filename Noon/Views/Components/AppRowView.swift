//
//  AppRowView.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

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
                
                // Validity indicator
                if !app.isValid {
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
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : .clear)
        )
        // Ensure the entire rectangle is interactive, even the empty spaces
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .scaleEffect(isHovered ? 1.005 : 1.0)
    }
}

// MARK: - Compact Row (for Menu Bar popover)

struct AppRowCompact: View {
    let app: MonitoredApp
    let isActive: Bool
    
    var body: some View {
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
    }
    .padding()
    .frame(width: 400)
}
