//
//  LocalizationService.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import ObjectiveC

// MARK: - Bundle Override

private var kBundleKey: UInt8 = 0

/// Subclass of Bundle that intercepts localizedString lookups
/// and redirects them to a language-specific .lproj bundle.
private class OverriddenBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let overrideBundle = objc_getAssociatedObject(self, &kBundleKey) as? Bundle {
            return overrideBundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

// MARK: - LocalizationService

internal enum LocalizationService {
    
    /// Current resolved language code ("fr", "en", "it", etc.)
    private(set) static var currentResolvedLanguageCode: String = resolveSystemLanguageCode()
    
    /// One-time swizzle of Bundle.main to enable runtime language override
    private static let swizzleOnce: Void = {
        object_setClass(Bundle.main, OverriddenBundle.self)
    }()
    
    /// Resolves the actual macOS system preferred language code independently of any app-level overrides.
    /// Falls back strictly to English ("en") if the candidate languages are not supported.
    static func resolveSystemLanguageCode(candidates: [String]? = nil) -> String {
        let supported = ["fr", "en", "it", "de", "es", "pt", "zh-Hans", "ar"]
        
        let preferredList: [String]
        if let candidates = candidates {
            preferredList = candidates
        } else if let globalLangs = CFPreferencesCopyAppValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication) as? [String] {
            preferredList = globalLangs
        } else {
            preferredList = Locale.preferredLanguages
        }
        
        for lang in preferredList {
            if supported.contains(lang) { return lang }
            let base = lang.components(separatedBy: "-").first ?? lang
            if supported.contains(base) { return base }
            if base == "zh" { return "zh-Hans" }
        }
        
        // 3. Default fallback to English if system language is not supported by Noon
        return "en"
    }
    
    /// Apply a language override to Bundle.main so ALL string lookups
    /// (SwiftUI Text, NSLocalizedString, etc.) resolve in the target language.
    ///
    /// - Parameter language: The `AppLanguage` to apply. Pass `.system` to dynamically track macOS system language.
    static func applyLanguage(_ language: AppLanguage) {
        // Ensure swizzle has happened
        _ = swizzleOnce
        
        let targetCode: String
        if language == .system {
            targetCode = resolveSystemLanguageCode()
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            print("[Noon i18n] System language dynamically resolved to: \(targetCode)")
        } else {
            targetCode = language.rawValue
            UserDefaults.standard.set([targetCode], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            print("[Noon i18n] Explicit language selected: \(targetCode)")
        }
        
        currentResolvedLanguageCode = targetCode
        
        // Find the .lproj bundle for this language
        if let path = Bundle.main.path(forResource: targetCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(Bundle.main, &kBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            print("[Noon i18n] ✅ Applied language bundle: \(targetCode) from \(path)")
        } else {
            let baseCode = targetCode.components(separatedBy: "-").first ?? targetCode
            if let path = Bundle.main.path(forResource: baseCode, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                objc_setAssociatedObject(Bundle.main, &kBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                print("[Noon i18n] ✅ Applied fallback language bundle: \(baseCode) from \(path)")
            } else {
                objc_setAssociatedObject(Bundle.main, &kBundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                print("[Noon i18n] ⚠️ No .lproj found for '\(targetCode)' or '\(baseCode)'")
            }
        }
    }
}
