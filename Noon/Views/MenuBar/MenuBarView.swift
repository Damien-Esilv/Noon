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
    
    @Environment(\.dismiss) private var dismiss
    
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
            
            // MARK: - Running Apps
            if !monitorService.runningMonitoredApps.isEmpty {
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
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack(spacing: 10) {
            // App Icon with glow
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: monitorService.currentState.systemImage(for: settings.menuBarIconStyle))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Noon")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                
                StatusLabel(state: monitorService.currentState, settings: settings)
            }
            
            Spacer()
            
            // Pause/Resume button
            Button {
                withAnimation(.spring(response: 0.3)) {
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
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .help(settings.isMonitoringEnabled ? "Mettre en pause" : "Reprendre")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
        VStack(spacing: 6) {
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
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(settings.manageTrueTone ? (displayService.isTrueToneEnabled ? .green : .red.opacity(0.6)) : .red.opacity(0.6))
                            .frame(width: 6, height: 6)
                        
                        Text(settings.manageTrueTone ? (displayService.isTrueToneEnabled ? "Activé" : "Désactivé") : "(non géré)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
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
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(settings.manageNightShift ? (displayService.isNightShiftEnabled ? .green : .red.opacity(0.6)) : .red.opacity(0.6))
                        .frame(width: 6, height: 6)
                    
                    Text(settings.manageNightShift ? (displayService.isNightShiftEnabled ? "Activé" : "Désactivé") : "(non géré)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack {
            // Settings button — native SettingsLink prevents popover jump bugs.
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
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHoveringSettings ? Color.primary.opacity(0.06) : .clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHoveringSettings = $0 }
            .simultaneousGesture(TapGesture().onEnded {
                // Wait for the popup to fully close, then force settings to front
                // if it's already open (SettingsLink alone doesn't do this reliably).
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
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHoveringQuit ? Color.red.opacity(0.08) : .clear)
                )
            }
            .buttonStyle(.plain)
            .onHover { isHoveringQuit = $0 }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Helpers
    
    private var statusColor: Color {
        switch monitorService.currentState {
        case .normal:       return settings.colorNormal
        case .creativeMode: return settings.colorCreative
        case .error:        return settings.colorError
        case .timerActive:  return settings.colorCreative
        case .paused:       return .gray
        }
    }
    

}
