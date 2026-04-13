//
//  ReactivationMode.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import SwiftUI

enum ReactivationMode: String, Codable, CaseIterable, Identifiable {
    /// Restores immediately when the monitored app loses focus
    case immediate = "immediate"
    
    /// Restores only when ALL monitored apps are fully quit
    case onQuit = "onQuit"
    
    /// Restores after a user-configured delay without any monitored app in the foreground
    case timer = "timer"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .immediate: return "Immédiat"
        case .onQuit:    return "À la fermeture"
        case .timer:     return "Minuteur"
        }
    }
    
    var descriptionKey: LocalizedStringKey {
        switch self {
        case .immediate:
            return "True Tone et Night Shift sont réactivés dès que l'app créative perd le focus."
        case .onQuit:
            return "Attend que toutes les apps créatives soient complètement fermées avant de réactiver."
        case .timer:
            return "Attend un délai configurable hors des apps créatives avant de réactiver."
        }
    }
    
    var systemImage: String {
        switch self {
        case .immediate: return "bolt.fill"
        case .onQuit:    return "xmark.app.fill"
        case .timer:     return "timer"
        }
    }
}
