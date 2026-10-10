//
//  MenuBarView.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    let monitorService: AppMonitorService
    let displayService: DisplayService
    let settings: AppSettings
    @State private var displayManager = DisplayManager.shared
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isHoveringPause = false
    @State private var isHoveringTrueTone = false
    @State private var isHoveringNightShift = false
    @State private var isHoveringSettings = false
    @State private var isHoveringQuit = false
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerSection
            
            Divider()
                .padding(.horizontal, 16)
                .opacity(0.5)
            
            // MARK: - Status Section
            statusSection
            
            // MARK: - Display Controls
            displayControlsSection
            
            Divider()
                .padding(.horizontal, 16)
                .opacity(0.5)
            
            // MARK: - Connected Displays Section
            connectedDisplaysSection
            
            // MARK: - Running Apps
            if !monitorService.runningMonitoredApps.isEmpty {
                Divider()
                    .padding(.horizontal, 16)
                    .opacity(0.5)
                runningAppsSection
            }
            
            Divider()
                .padding(.horizontal, 16)
                .opacity(0.5)
            
            // MARK: - Footer Actions
            footerSection
        }
        .frame(width: 320)
        .padding(.vertical, 8)
        .background(popupContainerBackground)
        .onAppear {
            displayService.refreshStatus()
            displayManager.refreshConnectedDisplays()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                displayService.refreshStatus()
            }
        }
    }

    @ViewBuilder
    private var popupContainerBackground: some View {
        switch settings.popupMaterialStyle {
        case .solid:
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
        case .semiTransparent:
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
        case .transparent:
            Color.clear
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 10) {
            headerIconView
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Noon")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                
                StatusLabel(state: monitorService.currentState, settings: settings)
            }
            
            Spacer()
            
            // Pause/Resume button with Apple spring micro-interaction
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if settings.isMonitoringEnabled {
                        monitorService.pauseMonitoring()
                    } else {
                        monitorService.resumeMonitoring()
                    }
                }
            } label: {
                Image(systemName: settings.isMonitoringEnabled ? "pause.circle" : "play.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(settings.isMonitoringEnabled ? (settings.effectiveAccentColor ?? .accentColor) : .green)
                    .scaleEffect(isHoveringPause ? 1.12 : 1.0)
                    .contentTransition(.symbolEffect(.replace))
                    .animation(.spring(response: 0.22, dampingFraction: 0.65), value: isHoveringPause)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringPause = $0 }
            .help(settings.isMonitoringEnabled ? "Mettre en pause" : "Reprendre")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private var headerIconView: some View {
        if #available(macOS 15.0, *) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                statusColor.opacity(0.28),
                                statusColor.opacity(0.08)
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: 18
                        )
                    )
                    .blendMode(.color)
                
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [statusColor.opacity(0.4), statusColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
                    .blendMode(.overlay)
                
                Image(systemName: monitorService.currentState.systemImage(for: settings.menuBarIconStyle))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusColor)
                    .shadow(color: statusColor.opacity(0.3), radius: 2)
            }
            .frame(width: 36, height: 36)
        } else {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: monitorService.currentState.systemImage(for: settings.menuBarIconStyle))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 10) {
            // Timer countdown
            if case .timerActive = monitorService.currentState {
                GlassCard(cornerRadius: 10, padding: 12, material: .thinMaterial) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(settings.effectiveAccentColor ?? .accentColor)
                            .font(.system(size: 14))
                        
                        Text("Réactivation dans")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(monitorService.formattedTimerRemaining)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(settings.effectiveAccentColor ?? .accentColor)
                            .monospacedDigit()
                    }
                }
                .appleHoverEffect(scale: 1.015, liftOffset: -1)
            }
            
            // Error display
            if let error = displayService.lastError {
                GlassCard(cornerRadius: 10, padding: 10, material: .thinMaterial) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.system(size: 12))
                        
                        Text(error)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        Button {
                            displayService.clearError()
                        } label: {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 12))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Display Controls
    
    private var displayControlsSection: some View {
        VStack(spacing: 4) {
            // True Tone row
            if displayService.isTrueToneSupported {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(displayService.isTrueToneEnabled ? .blue : .secondary)
                        .frame(width: 20)
                    
                    Text("True Tone")
                        .font(.system(.subheadline, design: .rounded))
                    
                    Spacer()
                    
                    trueToneStatusBadge
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHoveringTrueTone ? Color.primary.opacity(0.04) : Color.clear)
                )
                .scaleEffect(isHoveringTrueTone ? 1.008 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHoveringTrueTone)
                .onHover { isHoveringTrueTone = $0 }
            }
            
            // Night Shift row
            HStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(displayService.isNightShiftEnabled ? .yellow : .secondary)
                    .frame(width: 20)
                
                Text("Night Shift")
                    .font(.system(.subheadline, design: .rounded))
                
                Spacer()
                
                nightShiftStatusBadge
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHoveringNightShift ? Color.primary.opacity(0.04) : Color.clear)
            )
            .scaleEffect(isHoveringNightShift ? 1.008 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHoveringNightShift)
            .onHover { isHoveringNightShift = $0 }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var trueToneStatusBadge: some View {
        let isManaged = settings.manageTrueTone && DisplayManager.shared.isTrueToneDisplayManaged
        let isEnabled = displayService.isTrueToneEnabled
        
        if #available(macOS 15.0, *) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isManaged ? (isEnabled ? .green : .red.opacity(0.7)) : .red.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .shadow(color: (isManaged && isEnabled) ? .green.opacity(0.5) : .clear, radius: 2)
                
                Text(isManaged ? (isEnabled ? "Activé" : "Désactivé") : "(non géré)")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                            .blendMode(.overlay)
                    )
            )
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(isManaged ? (isEnabled ? .green : .red.opacity(0.6)) : .red.opacity(0.6))
                    .frame(width: 6, height: 6)
                
                Text(isManaged ? (isEnabled ? "Activé" : "Désactivé") : "(non géré)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var nightShiftStatusBadge: some View {
        let isManaged = settings.manageNightShift && DisplayManager.shared.isNightShiftManaged
        let isEnabled = displayService.isNightShiftEnabled
        
        if #available(macOS 15.0, *) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isManaged ? (isEnabled ? .green : .red.opacity(0.7)) : .red.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .shadow(color: (isManaged && isEnabled) ? .green.opacity(0.5) : .clear, radius: 2)
                
                Text(isManaged ? (isEnabled ? "Activé" : "Désactivé") : "(non géré)")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                            .blendMode(.overlay)
                    )
            )
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(isManaged ? (isEnabled ? .green : .red.opacity(0.6)) : .red.opacity(0.6))
                    .frame(width: 6, height: 6)
                
                Text(isManaged ? (isEnabled ? "Activé" : "Désactivé") : "(non géré)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Connected Displays Section
    
    private var connectedDisplaysSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Écrans Connectés")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 8)
            
            let displays = displayManager.connectedDisplays.isEmpty
                ? [DisplayInfo(id: CGMainDisplayID(), name: "Écran Retina", isBuiltin: true, isXDR: false, isAppleDisplay: true, isManagementEnabled: true)]
                : displayManager.connectedDisplays
            
            VStack(spacing: 2) {
                ForEach(displays) { display in
                    ConnectedDisplayRow(display: display, settings: settings, displayService: displayService)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // MARK: - Running Apps Section
    
    private var runningAppsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("APPS SURVEILLÉES ACTIVES")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
            
            VStack(spacing: 2) {
                ForEach(monitorService.runningMonitoredApps) { app in
                    AppRowCompact(
                        app: app,
                        isActive: monitorService.activeMonitoredApp?.id == app.id
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            // Settings button
            SettingsLink {
                HStack(spacing: 5) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                    Text("Réglages")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .foregroundStyle(isHoveringSettings ? .primary : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(settingsHoverBackground)
                .scaleEffect(isHoveringSettings ? 1.04 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHoveringSettings)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringSettings = $0 }
            .simultaneousGesture(TapGesture().onEnded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows {
                        if window.isVisible && window.canBecomeKey && !(window is NSPanel) {
                            window.makeKeyAndOrderFront(nil)
                            window.orderFrontRegardless()
                        }
                    }
                }
            })
            
            Spacer()
            
            // Quit button
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "power")
                        .font(.system(size: 12))
                    Text("Quitter")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                }
                .foregroundStyle(isHoveringQuit ? .red : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(quitHoverBackground)
                .scaleEffect(isHoveringQuit ? 1.04 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHoveringQuit)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringQuit = $0 }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var settingsHoverBackground: some View {
        if #available(macOS 15.0, *) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.thinMaterial)
                .opacity(isHoveringSettings ? 0.9 : 0.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                        .blendMode(.overlay)
                        .opacity(isHoveringSettings ? 1.0 : 0.0)
                )
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHoveringSettings ? Color.primary.opacity(0.06) : .clear)
        }
    }
    
    @ViewBuilder
    private var quitHoverBackground: some View {
        if #available(macOS 15.0, *) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.thinMaterial)
                .opacity(isHoveringQuit ? 0.8 : 0.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.red.opacity(isHoveringQuit ? 0.12 : 0.0))
                        .blendMode(.color)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.25), lineWidth: 0.5)
                        .blendMode(.overlay)
                        .opacity(isHoveringQuit ? 1.0 : 0.0)
                )
        } else {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHoveringQuit ? Color.red.opacity(0.1) : .clear)
        }
    }
    
    private var statusColor: Color {
        switch monitorService.currentState {
        case .normal:       return settings.colorNormal
        case .creativeMode: return settings.colorCreative
        case .error:        return settings.colorError
        case .timerActive:  return settings.colorCreative.opacity(0.8)
        case .paused:       return .gray
        }
    }
}

// MARK: - Connected Display Row with Apple Hover Interaction

private struct ConnectedDisplayRow: View {
    let display: DisplayInfo
    let settings: AppSettings
    let displayService: DisplayService
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: display.isBuiltin ? "laptopcomputer" : "display")
                .font(.system(size: 13))
                .foregroundStyle(display.isManagementEnabled ? (settings.effectiveAccentColor ?? .accentColor) : .secondary)
                .frame(width: 18)
                .scaleEffect(isHovered ? 1.08 : 1.0)
            
            Text(display.name)
                .font(.system(.subheadline, design: .rounded))
                .lineLimit(1)
            
            if display.isXDR {
                Text("XDR")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            displayStatusBadge(for: display)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.04) : Color.clear)
        )
        .scaleEffect(isHovered ? 1.008 : 1.0)
        .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
        .onHover { isHovered = $0 }
    }
    
    @ViewBuilder
    private func displayStatusBadge(for display: DisplayInfo) -> some View {
        let isManaged = display.isManagementEnabled
        let hasError = display.hasError || (displayService.lastError != nil)
        
        let dotColor: Color = hasError ? .orange : (isManaged ? .green : .red.opacity(0.8))
        let labelText: LocalizedStringKey = hasError ? "Erreur" : (isManaged ? "Surveillé" : "Non géré")
        
        if #available(macOS 15.0, *) {
            HStack(spacing: 5) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .shadow(color: dotColor.opacity(0.5), radius: 2)
                
                Text(labelText)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                            .blendMode(.overlay)
                    )
            )
        } else {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                
                Text(labelText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
