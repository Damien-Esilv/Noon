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
    
    /// One-time swizzle of Bundle.main to enable runtime language override
    private static let swizzleOnce: Void = {
        object_setClass(Bundle.main, OverriddenBundle.self)
    }()
    
    /// Apply a language override to Bundle.main so ALL string lookups
    /// (SwiftUI Text, NSLocalizedString, etc.) resolve in the target language.
    ///
    /// - Parameter language: The `AppLanguage` to apply. Pass `.system` to clear the override.
    static func applyLanguage(_ language: AppLanguage) {
        // Ensure swizzle has happened
        _ = swizzleOnce
        
        if language == .system {
            // Remove override — use system default
            objc_setAssociatedObject(Bundle.main, &kBundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            print("[Noon i18n] Language reset to system")
        } else {
            let langCode = language.rawValue
            
            // Debug: list available .lproj directories
            if let resourcePath = Bundle.main.resourcePath {
                let contents = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath)) ?? []
                let lprojs = contents.filter { $0.hasSuffix(".lproj") }
                print("[Noon i18n] Available .lproj bundles: \(lprojs)")
            }
            
            // Find the .lproj bundle for this language
            if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                objc_setAssociatedObject(Bundle.main, &kBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                print("[Noon i18n] ✅ Applied language: \(langCode) from \(path)")
            } else {
                // Fallback: try the base language code (e.g., "zh-Hans" -> "zh")
                let baseCode = langCode.components(separatedBy: "-").first ?? langCode
                if let path = Bundle.main.path(forResource: baseCode, ofType: "lproj"),
                   let bundle = Bundle(path: path) {
                    objc_setAssociatedObject(Bundle.main, &kBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    print("[Noon i18n] ✅ Applied language (fallback): \(baseCode) from \(path)")
                } else {
                    // No .lproj found — clear override
                    objc_setAssociatedObject(Bundle.main, &kBundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    print("[Noon i18n] ⚠️ No .lproj found for '\(langCode)' or '\(baseCode)'")
                }
            }
            
            // Also hint the system for any system-level string lookups
            UserDefaults.standard.set([langCode], forKey: "AppleLanguages")
        }
    }
}
