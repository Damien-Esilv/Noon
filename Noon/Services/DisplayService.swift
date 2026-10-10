//
//  DisplayService.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import AppKit

@Observable
final class DisplayService {
    
    // MARK: - State
    
    private(set) var isNightShiftEnabled: Bool = false
    private(set) var isTrueToneEnabled: Bool = false
    private(set) var isTrueToneSupported: Bool = false
    private(set) var isFrameworkLoaded: Bool = false
    private(set) var lastError: String?
    
    /// Stores the user's original settings before Noon disabled them
    private var savedNightShiftState: Bool?
    private var savedTrueToneState: Bool?
    
    /// Whether display features are currently suppressed by Noon
    private(set) var isSuppressed: Bool = false
    
    private let wrapper: CoreBrightnessWrapper? = CoreBrightnessWrapper.shared()
    
    private var pollingTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        refreshStatus()
        startPolling()
        wrapper?.registerStatusChangeHandler { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, !self.isSuppressed else { return }
                self.refreshStatus()
            }
        }
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
    
    private func startPolling() {
        // Poll every 1.5 seconds in .common mode so UI keeps synchronized even while menu bar popup is open
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.isSuppressed {
                self.refreshStatus()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.pollingTimer = timer
    }
    
    // MARK: - Status Refresh
    
    func refreshStatus() {
        guard let wrapper = wrapper else {
            isFrameworkLoaded = false
            lastError = "CoreBrightness framework not available."
            return
        }
        
        isFrameworkLoaded = wrapper.isFrameworkLoaded
        isTrueToneSupported = wrapper.isTrueToneSupported
        
        if !isFrameworkLoaded {
            lastError = "CoreBrightness framework failed to load."
            return
        }
        
        // Read current states
        var error: NSError?
        
        isNightShiftEnabled = wrapper.isNightShiftEnabled(error: &error)
        if let err = error {
            lastError = "Night Shift: \(err.localizedDescription)"
            error = nil
        }
        
        if isTrueToneSupported {
            isTrueToneEnabled = wrapper.isTrueToneEnabled(error: &error)
            if let err = error {
                lastError = "True Tone: \(err.localizedDescription)"
            }
        }
    }
    
    // MARK: - Disable (Creative Mode)
    
    /// Saves current state and disables True Tone / Night Shift based on settings and display management
    func disableForCreativeMode(settings: AppSettings) {
        guard let wrapper = wrapper, isFrameworkLoaded else {
            lastError = "Cannot disable: framework not loaded."
            return
        }
        
        let shouldManageTrueTone = settings.manageTrueTone && DisplayManager.shared.isTrueToneDisplayManaged
        let shouldManageNightShift = settings.manageNightShift && DisplayManager.shared.isNightShiftManaged
        
        guard shouldManageTrueTone || shouldManageNightShift else {
            return
        }
        
        // Save current state before disabling
        refreshStatus()
        savedNightShiftState = isNightShiftEnabled
        savedTrueToneState = isTrueToneEnabled
        
        var error: NSError?
        
        // Disable Night Shift if managed
        if shouldManageNightShift && isNightShiftEnabled {
            let success = wrapper.setNightShiftEnabled(false, error: &error)
            if !success {
                lastError = "Failed to disable Night Shift: \(error?.localizedDescription ?? "unknown")"
            }
        }
        
        // Disable True Tone if managed and supported
        if shouldManageTrueTone && isTrueToneSupported && isTrueToneEnabled {
            error = nil
            let success = wrapper.setTrueToneEnabled(false, error: &error)
            if !success {
                lastError = "Failed to disable True Tone: \(error?.localizedDescription ?? "unknown")"
            }
        }
        
        isSuppressed = true
        if shouldManageNightShift {
            isNightShiftEnabled = false
        }
        if shouldManageTrueTone && isTrueToneSupported {
            isTrueToneEnabled = false
        }
        
        // Play sound if enabled
        if settings.soundOnToggle {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
    }
    
    // MARK: - Restore (Normal Mode)
    
    /// Restores True Tone / Night Shift to the state saved before creative mode
    func restoreFromCreativeMode(settings: AppSettings) {
        guard let wrapper = wrapper, isFrameworkLoaded else {
            lastError = "Cannot restore: framework not loaded."
            return
        }
        
        guard isSuppressed else { return }
        
        var error: NSError?
        
        // Restore Night Shift
        if let savedState = savedNightShiftState, savedState {
            let success = wrapper.setNightShiftEnabled(true, error: &error)
            if !success {
                lastError = "Failed to restore Night Shift: \(error?.localizedDescription ?? "unknown")"
            }
        }
        
        // Restore True Tone
        if isTrueToneSupported {
            if let savedState = savedTrueToneState, savedState {
                error = nil
                let success = wrapper.setTrueToneEnabled(true, error: &error)
                if !success {
                    lastError = "Failed to restore True Tone: \(error?.localizedDescription ?? "unknown")"
                }
            }
        }
        
        isSuppressed = false
        savedNightShiftState = nil
        savedTrueToneState = nil
        
        // Play sound if enabled
        if settings.soundOnToggle {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
        
        refreshStatus()
    }
    
    /// Restores display features if they are no longer managed (e.g. user disabled screen in settings)
    func restoreUnmanagedFeaturesIfNeeded(settings: AppSettings) {
        guard isSuppressed, let wrapper = wrapper, isFrameworkLoaded else { return }
        
        let shouldManageTrueTone = settings.manageTrueTone && DisplayManager.shared.isTrueToneDisplayManaged
        let shouldManageNightShift = settings.manageNightShift && DisplayManager.shared.isNightShiftManaged
        
        var error: NSError?
        
        if !shouldManageTrueTone, let savedTT = savedTrueToneState, savedTT {
            _ = wrapper.setTrueToneEnabled(true, error: &error)
            savedTrueToneState = nil
        }
        
        if !shouldManageNightShift, let savedNS = savedNightShiftState, savedNS {
            _ = wrapper.setNightShiftEnabled(true, error: &error)
            savedNightShiftState = nil
        }
        
        if savedNightShiftState == nil && savedTrueToneState == nil {
            isSuppressed = false
        }
        
        refreshStatus()
    }
    
    // MARK: - Manual Toggle
    
    func setNightShift(enabled: Bool) {
        guard let wrapper = wrapper else { return }
        var error: NSError?
        _ = wrapper.setNightShiftEnabled(enabled, error: &error)
        if let err = error { lastError = err.localizedDescription }
        refreshStatus()
    }
    
    func setTrueTone(enabled: Bool) {
        guard let wrapper = wrapper, isTrueToneSupported else { return }
        var error: NSError?
        _ = wrapper.setTrueToneEnabled(enabled, error: &error)
        if let err = error { lastError = err.localizedDescription }
        refreshStatus()
    }
    
    // MARK: - Error Management
    
    func clearError() {
        lastError = nil
    }
}
