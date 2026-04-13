//
//  AppMonitorService.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import AppKit
import Combine

@Observable
final class AppMonitorService {
    
    // MARK: - Dependencies
    
    private let displayService: DisplayService
    private let settings: AppSettings
    private let notificationService: NotificationService
    
    // MARK: - State
    
    private(set) var currentState: MenuBarState = .normal
    private(set) var activeMonitoredApp: MonitoredApp?
    private(set) var timerRemaining: TimeInterval = 0
    
    /// Currently running monitored apps
    private(set) var runningMonitoredApps: [MonitoredApp] = []
    
    // MARK: - Internal
    
    private var reactivationTimer: DispatchWorkItem?
    private var countdownTimer: Timer?
    private var appValidationTimer: Timer?
    private var workspaceObservers: [NSObjectProtocol] = []
    
    // MARK: - Initialization
    
    init(displayService: DisplayService, settings: AppSettings, notificationService: NotificationService) {
        self.displayService = displayService
        self.settings = settings
        self.notificationService = notificationService
    }
    
    // MARK: - Lifecycle
    
    func startMonitoring() {
        stopMonitoring()
        
        guard settings.isMonitoringEnabled else {
            currentState = .paused
            return
        }
        
        let center = NSWorkspace.shared.notificationCenter
        
        // Watch for app activation
        let activateObserver = center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivated(notification)
        }
        
        // Watch for app termination
        let terminateObserver = center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppTerminated(notification)
        }
        
        // Watch for app deactivation
        let deactivateObserver = center.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppDeactivated(notification)
        }
        
        workspaceObservers = [activateObserver, terminateObserver, deactivateObserver]
        
        // Periodic app validation (every 60 seconds)
        appValidationTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.validateMonitoredApps()
        }
        
        // Initial validation
        validateMonitoredApps()
        updateRunningApps()
        
        // Check current frontmost app
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            checkIfMonitored(bundleIdentifier: frontApp.bundleIdentifier)
        }
    }
    
    func stopMonitoring() {
        let center = NSWorkspace.shared.notificationCenter
        for observer in workspaceObservers {
            center.removeObserver(observer)
        }
        workspaceObservers.removeAll()
        
        cancelReactivationTimer()
        appValidationTimer?.invalidate()
        appValidationTimer = nil
    }
    
    func pauseMonitoring() {
        settings.isMonitoringEnabled = false
        cancelReactivationTimer()
        
        // Restore display if currently suppressed
        if displayService.isSuppressed {
            displayService.restoreFromCreativeMode(settings: settings)
        }
        
        currentState = .paused
        activeMonitoredApp = nil
    }
    
    func resumeMonitoring() {
        settings.isMonitoringEnabled = true
        startMonitoring()
        if currentState == .paused {
            currentState = .normal
        }
    }
    
    // MARK: - App Event Handlers
    
    private func handleAppActivated(_ notification: Notification) {
        guard settings.isMonitoringEnabled else { return }
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        
        updateRunningApps()
        checkIfMonitored(bundleIdentifier: bundleID)
    }
    
    private func handleAppDeactivated(_ notification: Notification) {
        guard settings.isMonitoringEnabled else { return }
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        
        // Only react if the deactivated app was a monitored one
        guard isMonitoredBundleID(bundleID) else { return }
        
        // In immediate mode, check if the newly frontmost app is also monitored.
        // If so, we should stay in creative mode — no need to restore and re-disable.
        if settings.reactivationMode == .immediate {
            // Use a tiny async dispatch to let the system finish the app switch.
            // By then, the new frontmost app will be set.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Check if the new frontmost app is also in the monitored list
                if let newFrontApp = NSWorkspace.shared.frontmostApplication,
                   let newBundleID = newFrontApp.bundleIdentifier,
                   self.isMonitoredBundleID(newBundleID) {
                    // Another monitored app took focus — stay in creative mode
                    return
                }
                
                // Non-monitored app (or no app) — restore display settings
                self.handleReactivation()
            }
        }
    }
    
    private func handleAppTerminated(_ notification: Notification) {
        guard settings.isMonitoringEnabled else { return }
        
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        
        updateRunningApps()
        
        guard isMonitoredBundleID(bundleID) else { return }
        
        // In onQuit mode, check if ALL monitored apps are now closed
        if settings.reactivationMode == .onQuit {
            if runningMonitoredApps.isEmpty {
                handleReactivation()
            }
        }
    }
    
    // MARK: - Core Logic
    
    private func checkIfMonitored(bundleIdentifier: String?) {
        guard let bundleID = bundleIdentifier else { return }
        
        if let monitoredApp = settings.monitoredApps.first(where: { $0.bundleIdentifier == bundleID }) {
            // A monitored app is now in the foreground
            activateCreativeMode(for: monitoredApp)
        } else if displayService.isSuppressed {
            // Non-monitored app came to front while suppressed
            // Only handle focus lost if we are not already running a timer
            if case .timerActive = currentState {
                // Keep the timer running, do nothing
            } else {
                handleFocusLost()
            }
        }
    }
    
    private func activateCreativeMode(for app: MonitoredApp) {
        // Cancel any pending reactivation timer
        cancelReactivationTimer()
        
        activeMonitoredApp = app
        currentState = .creativeMode
        
        // Only disable if not already suppressed
        if !displayService.isSuppressed {
            displayService.disableForCreativeMode(settings: settings)
        }
    }
    
    private func handleFocusLost() {
        activeMonitoredApp = nil
        
        switch settings.reactivationMode {
        case .immediate:
            handleReactivation()
            
        case .onQuit:
            // Don't restore — wait for all monitored apps to quit
            // State stays in .creativeMode
            break
            
        case .timer:
            startReactivationTimer()
        }
    }
    
    private func handleReactivation() {
        cancelReactivationTimer()
        displayService.restoreFromCreativeMode(settings: settings)
        activeMonitoredApp = nil
        
        if settings.hasErrors {
            currentState = .error("Apps introuvables")
        } else {
            currentState = .normal
        }
    }
    
    // MARK: - Timer Management
    
    private func startReactivationTimer() {
        cancelReactivationTimer()
        
        let duration = settings.timerDuration
        timerRemaining = duration
        currentState = .timerActive(duration)
        
        // Countdown timer for UI updates
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timerRemaining -= 1
            self.currentState = .timerActive(self.timerRemaining)
            
            if self.timerRemaining <= 0 {
                self.handleReactivation()
            }
        }
        
        // Backup: DispatchWorkItem for precise firing
        let workItem = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                self?.handleReactivation()
            }
        }
        reactivationTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }
    
    private func cancelReactivationTimer() {
        reactivationTimer?.cancel()
        reactivationTimer = nil
        countdownTimer?.invalidate()
        countdownTimer = nil
        timerRemaining = 0
    }
    
    // MARK: - App Validation
    
    private func updateRunningApps() {
        let runningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        runningMonitoredApps = settings.monitoredApps.filter { runningBundleIDs.contains($0.bundleIdentifier) }
    }
    
    private func validateMonitoredApps() {
        let invalidApps = settings.validateAndRepairApps()
        
        if !invalidApps.isEmpty {
            currentState = .error("\(invalidApps.count) app(s) introuvable(s)")
            
            // Send notification for each invalid app
            if settings.showNotifications {
                for app in invalidApps {
                    notificationService.sendAppNotFoundNotification(app: app)
                }
            }
        }
    }
    
    private func isMonitoredBundleID(_ bundleID: String) -> Bool {
        settings.monitoredApps.contains { $0.bundleIdentifier == bundleID }
    }
    
    // MARK: - Formatted Timer
    
    var formattedTimerRemaining: String {
        let minutes = Int(timerRemaining) / 60
        let seconds = Int(timerRemaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
