//
//  MenuBarState.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI

enum MenuBarState: Equatable {
    /// Normal state — True Tone / Night Shift are active (user's original settings)
    case normal
    
    /// Creative mode detected — A monitored app is in the foreground, display features disabled
    case creativeMode
    
    /// Error or alert — Something needs attention (e.g., missing app, framework error)
    case error(String)
    
    /// Timer counting down — Waiting before reactivation
    case timerActive(TimeInterval)
    
    /// Monitoring is paused by the user
    case paused
    
    var displayName: LocalizedStringKey {
        switch self {
        case .normal:         return "En marche"
        case .creativeMode:   return "Mode Créatif"
        case .error(let msg): return "Erreur: \(msg)"
        case .timerActive:    return "Minuteur actif"
        case .paused:         return "En pause"
        }
    }
    
    var systemImage: String {
        return systemImage(for: .sunMin) // Fallback
    }
    
    func systemImage(for style: MenuBarIconStyle) -> String {
        switch self {
        case .normal:       return style.rawValue
        case .creativeMode: return style == .sunMin ? "sun.min.fill" : "sun.min"
        case .error:        return "exclamationmark.triangle.fill"
        case .timerActive:  return "timer"
        case .paused:       return "pause.circle.fill"
        }
    }
    
    static func == (lhs: MenuBarState, rhs: MenuBarState) -> Bool {
        switch (lhs, rhs) {
        case (.normal, .normal): return true
        case (.creativeMode, .creativeMode): return true
        case (.error(let a), .error(let b)): return a == b
        case (.timerActive(let a), .timerActive(let b)): return a == b
        case (.paused, .paused): return true
        default: return false
        }
    }
}

// MARK: - Menu Bar Icon Style

enum MenuBarIconStyle: String, Codable, CaseIterable, Identifiable {
    case sunMinFill = "sun.min.fill"
    case sunMin = "sun.min"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .sunMinFill: return "Soleil (Plein)"
        case .sunMin:     return "Soleil (Contour)"
        }
    }
}
