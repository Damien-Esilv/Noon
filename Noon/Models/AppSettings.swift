//
//  AppSettings.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import Combine

// MARK: - Language Support
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case en = "en"
    case fr = "fr"
    case it = "it"
    case de = "de"
    case es = "es"
    case pt = "pt"
    case zh = "zh-Hans"
    case ar = "ar"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .en: return "English"
        case .fr: return "Français"
        case .it: return "Italiano"
        case .de: return "Deutsch"
        case .es: return "Español"
        case .pt: return "Português"
        case .zh: return "中文"
        case .ar: return "العربية"
        }
    }
}

enum AccentColorMode: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case custom = "custom"
    
    var id: String { rawValue }
    var displayName: LocalizedStringKey {
        switch self {
        case .system: return "Système"
        case .custom: return "Personnalisé"
        }
    }
}

enum AppColorScheme: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .system: return "Système"
        case .light: return "Clair"
        case .dark: return "Sombre"
        }
    }
}

@Observable
final class AppSettings {
    
    // MARK: - Singleton
    
    static let shared = AppSettings()
    
    // MARK: - Storage Keys
    
    private enum Keys {
        static let monitoredApps      = "noon_monitoredApps"
        static let reactivationMode   = "noon_reactivationMode"
        static let timerDuration      = "noon_timerDuration"
        static let launchAtLogin      = "noon_launchAtLogin"
        static let showNotifications  = "noon_showNotifications"
        static let manageTrueTone     = "noon_manageTrueTone"
        static let manageNightShift   = "noon_manageNightShift"
        static let soundOnToggle      = "noon_soundOnToggle"
        static let iconStyleNormal    = "noon_iconStyleNormal"
        static let colorNormal        = "noon_colorNormal"
        static let colorCreative      = "noon_colorCreative"
        static let colorError         = "noon_colorError"
        static let showTimerInMenuBar = "noon_showTimerInMenuBar"
        static let resetTimerOnReturn = "noon_resetTimerOnReturn"
        static let menuBarIconStyle   = "noon_menuBarIconStyle"
        static let isMonitoringEnabled = "noon_isMonitoringEnabled"
        static let appLanguage        = "noon_appLanguage"
        static let accentColorMode    = "noon_accentColorMode"
        static let customAccentColor  = "noon_customAccentColor"
        static let appColorScheme     = "noon_appColorScheme"
    }
    
    // MARK: - General Settings
    
    var monitoredApps: [MonitoredApp] {
        didSet { save(monitoredApps, forKey: Keys.monitoredApps) }
    }
    
    var reactivationMode: ReactivationMode {
        didSet { UserDefaults.standard.set(reactivationMode.rawValue, forKey: Keys.reactivationMode) }
    }
    
    var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    
    var showNotifications: Bool {
        didSet { UserDefaults.standard.set(showNotifications, forKey: Keys.showNotifications) }
    }
    
    var manageTrueTone: Bool {
        didSet { UserDefaults.standard.set(manageTrueTone, forKey: Keys.manageTrueTone) }
    }
    
    var manageNightShift: Bool {
        didSet { UserDefaults.standard.set(manageNightShift, forKey: Keys.manageNightShift) }
    }
    
    var soundOnToggle: Bool {
        didSet { UserDefaults.standard.set(soundOnToggle, forKey: Keys.soundOnToggle) }
    }
    
    var isMonitoringEnabled: Bool {
        didSet { UserDefaults.standard.set(isMonitoringEnabled, forKey: Keys.isMonitoringEnabled) }
    }
    
    var appLanguage: AppLanguage {
        didSet {
            save(appLanguage, forKey: Keys.appLanguage)
            LocalizationService.applyLanguage(appLanguage)
        }
    }
    
    var selectedLocale: Locale {
        if appLanguage == .system {
            // Check if current system language matches one of our supported
            let sysCode = Locale.current.language.languageCode?.identifier ?? "en"
            let supported = AppLanguage.allCases.map { $0.rawValue }
            if supported.contains(sysCode) {
                return Locale.current
            }
            // Fallback to English if system UI isn't supported
            return Locale(identifier: "en")
        }
        return Locale(identifier: appLanguage.rawValue)
    }
    
    // MARK: - Timer Settings
    
    var timerDuration: TimeInterval {
        didSet { UserDefaults.standard.set(timerDuration, forKey: Keys.timerDuration) }
    }
    
    var showTimerInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showTimerInMenuBar, forKey: Keys.showTimerInMenuBar) }
    }
    
    var resetTimerOnReturn: Bool {
        didSet { UserDefaults.standard.set(resetTimerOnReturn, forKey: Keys.resetTimerOnReturn) }
    }
    
    // MARK: - Appearance Settings
    
    var colorNormal: Color {
        didSet { saveColor(colorNormal, forKey: Keys.colorNormal) }
    }
    
    var colorCreative: Color {
        didSet { saveColor(colorCreative, forKey: Keys.colorCreative) }
    }
    
    var colorError: Color {
        didSet { saveColor(colorError, forKey: Keys.colorError) }
    }
    
    var menuBarIconStyle: MenuBarIconStyle {
        didSet { UserDefaults.standard.set(menuBarIconStyle.rawValue, forKey: Keys.menuBarIconStyle) }
    }
    
    var accentColorMode: AccentColorMode {
        didSet { save(accentColorMode, forKey: Keys.accentColorMode) }
    }
    
    var customAccentColor: Color {
        didSet { saveColor(customAccentColor, forKey: Keys.customAccentColor) }
    }

    var effectiveAccentColor: Color? {
        if accentColorMode == .system { return nil }
        return customAccentColor
    }
    
    var appColorScheme: AppColorScheme {
        didSet { save(appColorScheme, forKey: Keys.appColorScheme) }
    }
    
    // MARK: - Transient State
    
    var invalidApps: [MonitoredApp] {
        monitoredApps.filter { !$0.isValid }
    }
    
    var hasErrors: Bool {
        !invalidApps.isEmpty
    }
    
    // MARK: - Initialization
    
    private init() {
        let defaults = UserDefaults.standard
        
        // Load monitored apps
        if let data = defaults.data(forKey: Keys.monitoredApps),
           let apps = try? JSONDecoder().decode([MonitoredApp].self, from: data) {
            self.monitoredApps = apps
        } else {
            self.monitoredApps = []
        }
        
        // Load enums
        if let modeStr = defaults.string(forKey: Keys.reactivationMode),
           let mode = ReactivationMode(rawValue: modeStr) {
            self.reactivationMode = mode
        } else {
            self.reactivationMode = .immediate
        }
        
        if let styleStr = defaults.string(forKey: Keys.menuBarIconStyle),
           let style = MenuBarIconStyle(rawValue: styleStr) {
            self.menuBarIconStyle = style
        } else {
            self.menuBarIconStyle = .sunMinFill
        }
        
        // Load booleans with defaults
        self.launchAtLogin      = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        self.showNotifications  = defaults.object(forKey: Keys.showNotifications) as? Bool ?? true
        self.manageTrueTone     = defaults.object(forKey: Keys.manageTrueTone) as? Bool ?? true
        self.manageNightShift   = defaults.object(forKey: Keys.manageNightShift) as? Bool ?? true
        self.soundOnToggle      = defaults.object(forKey: Keys.soundOnToggle) as? Bool ?? false
        self.showTimerInMenuBar = defaults.object(forKey: Keys.showTimerInMenuBar) as? Bool ?? true
        self.resetTimerOnReturn = defaults.object(forKey: Keys.resetTimerOnReturn) as? Bool ?? true
        self.isMonitoringEnabled = defaults.object(forKey: Keys.isMonitoringEnabled) as? Bool ?? true
        
        if let data = defaults.data(forKey: Keys.appLanguage),
           let savedLang = try? JSONDecoder().decode(AppLanguage.self, from: data) {
            self.appLanguage = savedLang
        } else {
            self.appLanguage = .system
        }
        
        if let data = defaults.data(forKey: Keys.accentColorMode),
           let savedMode = try? JSONDecoder().decode(AccentColorMode.self, from: data) {
            self.accentColorMode = savedMode
        } else {
            self.accentColorMode = .system
        }
        self.customAccentColor = Self.loadColor(forKey: Keys.customAccentColor) ?? .blue
        
        if let data = defaults.data(forKey: Keys.appColorScheme),
           let savedScheme = try? JSONDecoder().decode(AppColorScheme.self, from: data) {
            self.appColorScheme = savedScheme
        } else {
            self.appColorScheme = .system
        }
        
        // Load timer duration (default 5 minutes)
        let savedDuration = defaults.double(forKey: Keys.timerDuration)
        self.timerDuration = savedDuration > 0 ? savedDuration : 300.0
        
        // Load colors
        self.colorNormal   = Self.loadColor(forKey: Keys.colorNormal)   ?? .blue
        self.colorCreative = Self.loadColor(forKey: Keys.colorCreative) ?? .orange
        self.colorError    = Self.loadColor(forKey: Keys.colorError)    ?? .red
        
        // Apply language override to Bundle.main on startup
        // This MUST be called last since it uses 'self.appLanguage'
        LocalizationService.applyLanguage(self.appLanguage)
    }
    
    // MARK: - Persistence Helpers
    
    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func saveColor(_ color: Color, forKey key: String) {
        let nsColor = NSColor(color)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private static func loadColor(forKey key: String) -> Color? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let nsColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
            return nil
        }
        return Color(nsColor)
    }
    
    // MARK: - App Management
    
    func addApp(_ app: MonitoredApp) {
        guard !monitoredApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else { return }
        monitoredApps.append(app)
    }
    
    func removeApp(_ app: MonitoredApp) {
        monitoredApps.removeAll { $0.id == app.id }
    }
    
    func removeApps(at offsets: IndexSet) {
        monitoredApps.remove(atOffsets: offsets)
    }
    
    /// Validate all apps and update paths if they've moved (e.g. version update)
    func validateAndRepairApps() -> [MonitoredApp] {
        var invalidApps: [MonitoredApp] = []
        
        for i in monitoredApps.indices {
            if !monitoredApps[i].isValid {
                if let newPath = monitoredApps[i].resolvedPath {
                    // App found at new path — auto-repair
                    monitoredApps[i].path = newPath
                } else {
                    invalidApps.append(monitoredApps[i])
                }
            }
        }
        
        return invalidApps
    }
    
    // MARK: - Reset
    
    func resetAppearance() {
        colorNormal   = .blue
        colorCreative = .orange
        colorError    = .red
        menuBarIconStyle = .sunMinFill
        accentColorMode = .system
        customAccentColor = .blue
    }
}
