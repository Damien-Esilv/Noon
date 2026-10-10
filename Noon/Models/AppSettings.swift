//
//  AppSettings.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import SwiftUI
import Combine

// MARK: - Enums

// MARK: - Popup Background Style
enum PopupMaterialStyle: String, CaseIterable, Identifiable, Codable {
    case transparent = "transparent"
    case semiTransparent = "semiTransparent"
    case solid = "solid"
    
    var id: String { rawValue }
    
    var displayName: LocalizedStringKey {
        switch self {
        case .transparent: return "Transparent"
        case .semiTransparent: return "Flou"
        case .solid: return "Solide"
        }
    }
}

// MARK: - Monitored Website
public struct MonitoredWebsite: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var domain: String
    public var isEnabled: Bool
    public var isPredefined: Bool

    public init(id: UUID = UUID(), name: String, domain: String, isEnabled: Bool = true, isPredefined: Bool = false) {
        self.id = id
        self.name = name
        self.domain = domain
        self.isEnabled = isEnabled
        self.isPredefined = isPredefined
    }

    public static let standardWebsites: [MonitoredWebsite] = [
        MonitoredWebsite(name: "Figma", domain: "figma.com", isEnabled: true, isPredefined: true),
        MonitoredWebsite(name: "Canva", domain: "canva.com", isEnabled: true, isPredefined: true),
        MonitoredWebsite(name: "Photopea", domain: "photopea.com", isEnabled: true, isPredefined: true),
        MonitoredWebsite(name: "Spline", domain: "spline.design", isEnabled: true, isPredefined: true)
    ]
}

enum AccentColorMode: String, CaseIterable, Identifiable, Codable {
    case system
    case custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "Système"
        case .custom: return "Personnalisé"
        }
    }
}

enum AppColorScheme: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "Système"
        case .light: return "Clair"
        case .dark: return "Sombre"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case french = "fr"
    case english = "en"
    case italian = "it"
    case german = "de"
    case spanish = "es"
    case portuguese = "pt"
    case chinese = "zh-Hans"
    case arabic = "ar"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "Langue du système"
        case .french: return "Français"
        case .english: return "English"
        case .italian: return "Italiano"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .chinese: return "简体中文"
        case .arabic: return "العربية"
        }
    }
    
    var locale: Locale {
        switch self {
        case .system:
            return Locale(identifier: LocalizationService.currentResolvedLanguageCode)
        default:
            return Locale(identifier: rawValue)
        }
    }
}

// MARK: - AppSettings

@Observable
final class AppSettings {
    
    static let shared = AppSettings()
    
    // MARK: - Keys
    
    private enum Keys {
        static let monitoredApps              = "noon_monitoredApps"
        static let reactivationMode           = "noon_reactivationMode"
        static let launchAtLogin              = "noon_launchAtLogin"
        static let showNotifications          = "noon_showNotifications"
        static let manageTrueTone             = "noon_manageTrueTone"
        static let manageNightShift           = "noon_manageNightShift"
        static let soundOnToggle              = "noon_soundOnToggle"
        static let timerDuration              = "noon_timerDuration"
        static let showTimerInMenuBar         = "noon_showTimerInMenuBar"
        static let resetTimerOnReturn         = "noon_resetTimerOnReturn"
        static let menuBarIconStyle           = "noon_menuBarIconStyle"
        static let isMonitoringEnabled        = "noon_isMonitoringEnabled"
        static let appLanguage                = "noon_appLanguage"
        static let accentColorMode            = "noon_accentColorMode"
        static let customAccentColor          = "noon_customAccentColor"
        static let appColorScheme             = "noon_appColorScheme"
        static let colorNormal                = "noon_colorNormal"
        static let colorCreative              = "noon_colorCreative"
        static let colorError                 = "noon_colorError"
        
        // Display & Advanced Color Fidelity Keys
        static let lock100NitsCalibration     = "noon_lock100NitsCalibration"
        static let manageAutoBrightness       = "noon_manageAutoBrightness"
        static let enableAmbientLightMonitoring = "noon_enableAmbientLightMonitoring"
        static let showHUDOnSwitch            = "noon_showHUDOnSwitch"
        static let monitorWebApps             = "noon_monitorWebApps"
        static let popupMaterialStyle         = "noon_popupMaterialStyle"
        static let monitoredWebsites          = "noon_monitoredWebsites"
        static let enablePresetBrightness     = "noon_enablePresetBrightness"
        static let presetBrightnessLevel      = "noon_presetBrightnessLevel"
        static let enableCreativeColorProfile = "noon_enableCreativeColorProfile"
        static let creativeColorProfileName   = "noon_creativeColorProfileName"
        static let displayCalibrationProfiles = "noon_displayCalibrationProfiles"
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
        appLanguage.locale
    }
    
    var lock100NitsCalibration: Bool {
        didSet { UserDefaults.standard.set(lock100NitsCalibration, forKey: Keys.lock100NitsCalibration) }
    }
    
    var manageAutoBrightness: Bool {
        didSet { UserDefaults.standard.set(manageAutoBrightness, forKey: Keys.manageAutoBrightness) }
    }
    
    var enableAmbientLightMonitoring: Bool {
        didSet { UserDefaults.standard.set(enableAmbientLightMonitoring, forKey: Keys.enableAmbientLightMonitoring) }
    }
    
    var showHUDOnSwitch: Bool {
        didSet { UserDefaults.standard.set(showHUDOnSwitch, forKey: Keys.showHUDOnSwitch) }
    }
    
    var popupMaterialStyle: PopupMaterialStyle {
        didSet { UserDefaults.standard.set(popupMaterialStyle.rawValue, forKey: Keys.popupMaterialStyle) }
    }
    
    var monitoredWebsites: [MonitoredWebsite] {
        didSet { save(monitoredWebsites, forKey: Keys.monitoredWebsites) }
    }
    
    var enablePresetBrightness: Bool {
        didSet { UserDefaults.standard.set(enablePresetBrightness, forKey: Keys.enablePresetBrightness) }
    }
    
    var presetBrightnessLevel: Double {
        didSet { UserDefaults.standard.set(presetBrightnessLevel, forKey: Keys.presetBrightnessLevel) }
    }

    var enableCreativeColorProfile: Bool {
        didSet { UserDefaults.standard.set(enableCreativeColorProfile, forKey: Keys.enableCreativeColorProfile) }
    }

    var creativeColorProfileName: String {
        didSet { UserDefaults.standard.set(creativeColorProfileName, forKey: Keys.creativeColorProfileName) }
    }

    var displayCalibrationProfiles: [String: String] {
        didSet { save(displayCalibrationProfiles, forKey: Keys.displayCalibrationProfiles) }
    }

    var monitorWebApps: Bool {
        didSet { UserDefaults.standard.set(monitorWebApps, forKey: Keys.monitorWebApps) }
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
        didSet {
            save(appColorScheme, forKey: Keys.appColorScheme)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.applyColorScheme(self.appColorScheme)
            }
        }
    }
    
    // MARK: - Transient State
    
    var invalidApps: [MonitoredApp] {
        monitoredApps.filter { !$0.isValid }
    }
    
    var hasErrors: Bool {
        !invalidApps.isEmpty
    }
    
    // MARK: - Per-Display Calibration Helper
    
    func calibrationProfile(for displayID: CGDirectDisplayID) -> String {
        displayCalibrationProfiles[String(displayID)] ?? creativeColorProfileName
    }

    func setCalibrationProfile(_ profileName: String, for displayID: CGDirectDisplayID) {
        displayCalibrationProfiles[String(displayID)] = profileName
        creativeColorProfileName = profileName
    }

    // MARK: - Initialization
    
    init() {
        let defaults = UserDefaults.standard
        
        // Load monitored apps
        var loadedApps: [MonitoredApp] = []
        if let data = defaults.data(forKey: Keys.monitoredApps),
           let apps = try? JSONDecoder().decode([MonitoredApp].self, from: data) {
            loadedApps = apps
        }
        loadedApps.removeAll { $0.bundleIdentifier == "com.missing.creativeapp" }
        self.monitoredApps = loadedApps
        
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
        self.showTimerInMenuBar = defaults.object(forKey: Keys.showTimerInMenuBar) as? Bool ?? false
        self.resetTimerOnReturn = defaults.object(forKey: Keys.resetTimerOnReturn) as? Bool ?? false
        self.isMonitoringEnabled = defaults.object(forKey: Keys.isMonitoringEnabled) as? Bool ?? true
        
        // Display & Advanced Color Fidelity Defaults
        self.lock100NitsCalibration     = defaults.object(forKey: Keys.lock100NitsCalibration) as? Bool ?? false
        self.manageAutoBrightness       = defaults.object(forKey: Keys.manageAutoBrightness) as? Bool ?? true
        self.enableAmbientLightMonitoring = defaults.object(forKey: Keys.enableAmbientLightMonitoring) as? Bool ?? false
        self.showHUDOnSwitch            = defaults.object(forKey: Keys.showHUDOnSwitch) as? Bool ?? true
        self.monitorWebApps             = defaults.object(forKey: Keys.monitorWebApps) as? Bool ?? true

        // Popup style
        if let styleStr = defaults.string(forKey: Keys.popupMaterialStyle),
           let style = PopupMaterialStyle(rawValue: styleStr) {
            self.popupMaterialStyle = style
        } else {
            self.popupMaterialStyle = .transparent
        }
        
        // Monitored websites
        if let data = defaults.data(forKey: Keys.monitoredWebsites),
           let websites = try? JSONDecoder().decode([MonitoredWebsite].self, from: data) {
            self.monitoredWebsites = websites
        } else {
            self.monitoredWebsites = MonitoredWebsite.standardWebsites
        }
        
        // Preset Brightness in creative mode
        self.enablePresetBrightness = defaults.object(forKey: Keys.enablePresetBrightness) as? Bool ?? false
        self.presetBrightnessLevel = defaults.object(forKey: Keys.presetBrightnessLevel) as? Double ?? 0.60
        self.enableCreativeColorProfile = defaults.object(forKey: Keys.enableCreativeColorProfile) as? Bool ?? false
        self.creativeColorProfileName = defaults.string(forKey: Keys.creativeColorProfileName) ?? "Display P3"
        
        if let data = defaults.data(forKey: Keys.displayCalibrationProfiles),
           let dict = try? JSONDecoder().decode([String: String].self, from: data) {
            self.displayCalibrationProfiles = dict
        } else {
            self.displayCalibrationProfiles = [:]
        }
        
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
        LocalizationService.applyLanguage(self.appLanguage)
        save(self.monitoredApps, forKey: Keys.monitoredApps)
        
        // Apply initial color scheme
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.applyColorScheme(self.appColorScheme)
        }
    }
    
    // MARK: - Appearance Management
    
    @MainActor
    func applyColorScheme(_ scheme: AppColorScheme) {
        let appearance: NSAppearance?
        switch scheme {
        case .system:
            appearance = nil
        case .light:
            appearance = NSAppearance(named: .aqua)
        case .dark:
            appearance = NSAppearance(named: .darkAqua)
        }
        
        NSApp.appearance = appearance
        
        for window in NSApp.windows {
            window.appearance = appearance
            window.contentView?.needsDisplay = true
            window.contentView?.needsLayout = true
            window.displayIfNeeded()
            window.invalidateShadow()
        }
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
    
    func containsApp(_ app: MonitoredApp) -> Bool {
        monitoredApps.contains { $0.bundleIdentifier == app.bundleIdentifier }
    }
    
    func validateAndRepairApps() -> [MonitoredApp] {
        var invalid: [MonitoredApp] = []
        for i in 0..<monitoredApps.count {
            if !monitoredApps[i].isValid {
                invalid.append(monitoredApps[i])
            }
        }
        return invalid
    }
    
    // MARK: - Website Management
    
    func addWebsite(name: String, domain: String) {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .split(separator: "/").first.map(String.init) ?? domain
        
        let website = MonitoredWebsite(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            domain: cleanDomain,
            isPredefined: false
        )
        monitoredWebsites.append(website)
    }
    
    func removeWebsite(id: UUID) {
        monitoredWebsites.removeAll { $0.id == id }
    }
    
    func toggleWebsite(id: UUID) {
        if let index = monitoredWebsites.firstIndex(where: { $0.id == id }) {
            monitoredWebsites[index].isEnabled.toggle()
        }
    }

    func resetAppearance() {
        self.colorNormal   = .blue
        self.colorCreative = .orange
        self.colorError    = .red
        self.menuBarIconStyle = .sunMinFill
        self.accentColorMode = .system
        self.customAccentColor = .blue
        self.appColorScheme = .system
        self.popupMaterialStyle = .transparent
    }
}
