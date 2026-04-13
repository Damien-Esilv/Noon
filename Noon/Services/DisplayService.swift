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
    }
    
    deinit {
        pollingTimer?.invalidate()
    }
    
    private func startPolling() {
        // Poll every 3 seconds to keep UI synchronized with external changes
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Only refresh if not actively suppressing to avoid reading false negative states
            if !self.isSuppressed {
                self.refreshStatus()
            }
        }
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
    
    /// Saves current state and disables True Tone / Night Shift based on settings
    func disableForCreativeMode(settings: AppSettings) {
        guard let wrapper = wrapper, isFrameworkLoaded else {
            lastError = "Cannot disable: framework not loaded."
            return
        }
        
        // Save current state before disabling
        refreshStatus()
        savedNightShiftState = isNightShiftEnabled
        savedTrueToneState = isTrueToneEnabled
        
        var error: NSError?
        
        // Disable Night Shift if managed
        if settings.manageNightShift && isNightShiftEnabled {
            let success = wrapper.setNightShiftEnabled(false, error: &error)
            if !success {
                lastError = "Failed to disable Night Shift: \(error?.localizedDescription ?? "unknown")"
            }
        }
        
        // Disable True Tone if managed and supported
        if settings.manageTrueTone && isTrueToneSupported && isTrueToneEnabled {
            error = nil
            let success = wrapper.setTrueToneEnabled(false, error: &error)
            if !success {
                lastError = "Failed to disable True Tone: \(error?.localizedDescription ?? "unknown")"
            }
        }
        
        isSuppressed = true
        
        // Play sound if enabled
        if settings.soundOnToggle {
            NSSound(named: NSSound.Name("Pop"))?.play()
        }
        
        refreshStatus()
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
        if settings.manageNightShift, let savedState = savedNightShiftState, savedState {
            let success = wrapper.setNightShiftEnabled(true, error: &error)
            if !success {
                lastError = "Failed to restore Night Shift: \(error?.localizedDescription ?? "unknown")"
            }
        }
        
        // Restore True Tone
        if settings.manageTrueTone && isTrueToneSupported {
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
