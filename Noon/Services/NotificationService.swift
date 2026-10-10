//
//  NotificationService.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import UserNotifications

final class NotificationService {
    
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Setup
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[Noon] Notification permission error: \(error.localizedDescription)")
            }
            print("[Noon] Notification permission granted: \(granted)")
        }
    }
    
    // MARK: - App Not Found
    
    func sendAppNotFoundNotification(app: MonitoredApp) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Noon — Application introuvable", comment: "")
        content.body = String(
            format: NSLocalizedString("\"%@\" n'a pas été trouvée à son emplacement prévu. Vérifiez si l'app a été mise à jour ou déplacée.", comment: ""),
            app.name
        )
        content.sound = .default
        content.categoryIdentifier = "APP_NOT_FOUND"
        content.userInfo = ["bundleIdentifier": app.bundleIdentifier, "appName": app.name]
        
        let request = UNNotificationRequest(
            identifier: "noon.appNotFound.\(app.bundleIdentifier)",
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[Noon] Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Framework Error
    
    func sendFrameworkErrorNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Noon — Erreur système", comment: "")
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "FRAMEWORK_ERROR"
        
        let request = UNNotificationRequest(
            identifier: "noon.frameworkError.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Creative Mode Toggle
    
    func sendCreativeModeNotification(enabled: Bool, appName: String) {
        let content = UNMutableNotificationContent()
        content.title = enabled 
            ? NSLocalizedString("Noon — Mode Créatif activé", comment: "") 
            : NSLocalizedString("Noon — Mode Créatif désactivé", comment: "")
        content.body = enabled
            ? String(format: NSLocalizedString("True Tone et Night Shift ont été désactivés pour %@.", comment: ""), appName)
            : NSLocalizedString("True Tone et Night Shift ont été restaurés.", comment: "")
        content.sound = .default
        content.categoryIdentifier = "CREATIVE_MODE"
        
        let request = UNNotificationRequest(
            identifier: "noon.creativeMode.\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - App Version Mismatch
    
    func sendAppVersionMismatchNotification(app: MonitoredApp, newPath: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("Noon — App mise à jour détectée", comment: "")
        content.body = String(
            format: NSLocalizedString("\"%@\" a été trouvée à un nouvel emplacement. Le chemin a été mis à jour automatiquement.", comment: ""),
            app.name
        )
        content.sound = .default
        content.categoryIdentifier = "APP_UPDATED"
        
        let request = UNNotificationRequest(
            identifier: "noon.appUpdated.\(app.bundleIdentifier)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
