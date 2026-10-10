//
//  WebAppWatcher.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import AppKit
import ApplicationServices

// MARK: - Creative Web Applications

public struct WebCreativeTool: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let urlPattern: String
    public let titlePattern: String

    public init(id: String, name: String, urlPattern: String, titlePattern: String) {
        self.id = id
        self.name = name
        self.urlPattern = urlPattern
        self.titlePattern = titlePattern
    }

    public static let figma = WebCreativeTool(
        id: "figma",
        name: "Figma",
        urlPattern: "figma.com",
        titlePattern: ".*\\bFigma\\b.*"
    )

    public static let photopea = WebCreativeTool(
        id: "photopea",
        name: "Photopea",
        urlPattern: "photopea.com",
        titlePattern: ".*\\bPhotopea\\b.*"
    )

    public static let canva = WebCreativeTool(
        id: "canva",
        name: "Canva",
        urlPattern: "canva.com",
        titlePattern: ".*\\bCanva\\b.*"
    )

    public static let spline = WebCreativeTool(
        id: "spline",
        name: "Spline",
        urlPattern: "spline.design",
        titlePattern: ".*\\bSpline\\b.*"
    )

    public static let standardTools: [WebCreativeTool] = [
        .figma,
        .photopea,
        .canva,
        .spline
    ]
}

// MARK: - Web App Inspector Protocol

public protocol WebAppInspectorProtocol: Sendable {
    func isAccessibilityAuthorized() -> Bool
    func inspectFrontmostBrowser(pid: pid_t, bundleIdentifier: String) -> (tool: WebCreativeTool?, url: String?, windowTitle: String?)
}

// MARK: - Web App Watcher

public final class WebAppWatcher: WebAppInspectorProtocol, @unchecked Sendable {
    public static let shared = WebAppWatcher()

    /// Recognized browser bundle identifiers
    public static let recognizedBrowserIdentifiers: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "company.thebrowser.Browser", // Arc
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "org.mozilla.firefox",
        "com.operasoftware.Opera"
    ]

    private let registeredTools: [WebCreativeTool]

    public init(tools: [WebCreativeTool] = WebCreativeTool.standardTools) {
        self.registeredTools = tools
    }

    // MARK: - Permission Check

    public func isAccessibilityAuthorized() -> Bool {
        AXIsProcessTrusted()
    }

    public func promptForAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Browser Inspection

    public func inspectFrontmostBrowser(
        pid: pid_t,
        bundleIdentifier: String
    ) -> (tool: WebCreativeTool?, url: String?, windowTitle: String?) {
        guard Self.recognizedBrowserIdentifiers.contains(bundleIdentifier) else {
            return (nil, nil, nil)
        }

        let appRef = AXUIElementCreateApplication(pid)

        // 1. Inspect Focused Window Title
        var windowRef: CFTypeRef?
        let windowStatus = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowRef)

        var windowTitle: String? = nil
        var currentURL: String? = nil

        if windowStatus == .success, let window = windowRef {
            let windowElement = window as! AXUIElement
            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef) == .success,
               let titleString = titleRef as? String {
                windowTitle = titleString
            }

            // 2. Query AXURL directly (supported in Safari & some WebViews)
            var urlRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(windowElement, "AXURL" as CFString, &urlRef) == .success,
               let urlString = (urlRef as? URL)?.absoluteString ?? (urlRef as? String) {
                currentURL = urlString
            }

            // 3. Fallback: Search address bar UI elements if URL was not directly exposed
            if currentURL == nil {
                currentURL = searchAddressBarValue(in: windowElement)
            }
        }

        // 4. Match against registered creative web tools
        let matchedTool = matchTool(url: currentURL, title: windowTitle)
        return (matchedTool, currentURL, windowTitle)
    }

    public func matchTool(url: String?, title: String?) -> WebCreativeTool? {
        for tool in registeredTools {
            // Check URL pattern
            if let url = url, !url.isEmpty {
                if url.localizedCaseInsensitiveContains(tool.urlPattern) {
                    return tool
                }
            }

            // Check Title Regex
            if let title = title, !title.isEmpty {
                if let regex = try? NSRegularExpression(pattern: tool.titlePattern, options: .caseInsensitive) {
                    let range = NSRange(title.startIndex..<title.endIndex, in: title)
                    if regex.firstMatch(in: title, range: range) != nil {
                        return tool
                    }
                } else if title.localizedCaseInsensitiveContains(tool.name) {
                    return tool
                }
            }
        }
        return nil
    }

    public static func matchTool(from string: String) -> WebCreativeTool? {
        shared.matchTool(url: string, title: string)
    }

    // MARK: - Address Bar Traversal

    private func searchAddressBarValue(in element: AXUIElement) -> String? {
        var childrenRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
              let children = childrenRef as? [AXUIElement] else {
            return nil
        }

        for child in children {
            var roleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &roleRef) == .success,
               let role = roleRef as? String {
                if role == (kAXTextFieldRole as String) {
                    var valRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(child, kAXValueAttribute as CFString, &valRef) == .success,
                       let str = valRef as? String, !str.isEmpty {
                        return str
                    }
                }
            }
            if let nested = searchAddressBarValue(in: child) {
                return nested
            }
        }
        return nil
    }
}

// MARK: - Mock Web App Inspector (For Unit Testing)

public final class MockWebAppInspector: WebAppInspectorProtocol, @unchecked Sendable {
    public var authorized: Bool = true
    public var simulatedTool: WebCreativeTool?
    public var simulatedURL: String?
    public var simulatedTitle: String?

    public init(simulatedTool: WebCreativeTool? = nil) {
        self.simulatedTool = simulatedTool
    }

    public func isAccessibilityAuthorized() -> Bool {
        authorized
    }

    public func inspectFrontmostBrowser(
        pid: pid_t,
        bundleIdentifier: String
    ) -> (tool: WebCreativeTool?, url: String?, windowTitle: String?) {
        (simulatedTool, simulatedURL, simulatedTitle)
    }
}
