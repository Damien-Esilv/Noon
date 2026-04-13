//
//  LoginItemService.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import ServiceManagement

final class LoginItemService {
    
    static let shared = LoginItemService()
    
    private init() {}
    
    // MARK: - Status
    
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .notRegistered:
            return "Non enregistré"
        case .enabled:
            return "Activé"
        case .requiresApproval:
            return "Approbation requise"
        case .notFound:
            return "Non trouvé"
        @unknown default:
            return "Inconnu"
        }
    }
    
    // MARK: - Actions
    
    func enable() throws {
        try SMAppService.mainApp.register()
    }
    
    func disable() throws {
        try SMAppService.mainApp.unregister()
    }
    
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try enable()
        } else {
            try disable()
        }
    }
}
