//
//  NoonCommandRouter.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import CoreGraphics

// MARK: - Noon Command

public enum NoonCommand: Equatable, Sendable {
    case toggleCreativeMode
    case enableCreativeMode(appName: String?)
    case disableCreativeMode
    case setPreset(AppleReferencePreset)
    case setCalibratedBrightness(CalibrationTarget)
    case setBrightness(Float)
    case statusQuery
}

// MARK: - Noon Command Router

public final class NoonCommandRouter: Sendable {
    public static let shared = NoonCommandRouter()

    public init() {}

    // MARK: - URL Parsing (noon://)

    public func parseURL(_ url: URL) -> NoonCommand? {
        guard let scheme = url.scheme?.lowercased(), scheme == "noon" else {
            return nil
        }

        let host = (url.host ?? "").lowercased()
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let action = host.isEmpty ? path : host

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        func queryValue(for name: String) -> String? {
            queryItems.first(where: { $0.name.lowercased() == name.lowercased() })?.value
        }

        switch action {
        case "toggle":
            return .toggleCreativeMode

        case "enable", "creative":
            let state = queryValue(for: "state")?.lowercased()
            if state == "off" || state == "false" || state == "0" {
                return .disableCreativeMode
            }
            let app = queryValue(for: "app")
            return .enableCreativeMode(appName: app)

        case "disable", "normal":
            return .disableCreativeMode

        case "preset":
            guard let name = queryValue(for: "name")?.lowercased() else { return nil }
            return resolvePresetCommand(named: name)

        case "calibrate", "calibration":
            let mode = queryValue(for: "mode")?.lowercased()
            if mode == "100nits" || mode == "100" {
                return .setCalibratedBrightness(.fixedNits(100.0))
            }
            return .setCalibratedBrightness(.appleRecommended)

        case "brightness":
            if let valStr = queryValue(for: "value"), let val = Float(valStr) {
                return .setBrightness(val)
            }
            return nil

        case "status":
            return .statusQuery

        default:
            return nil
        }
    }

    // MARK: - CLI Argument Parsing

    public func parseArguments(_ args: [String]) -> NoonCommand? {
        var iterator = args.makeIterator()
        // Skip executable name if present
        if let first = iterator.next(), first.hasSuffix("noon") || first.hasSuffix("noon-cli") {
            // consumed
        }

        while let arg = iterator.next() {
            switch arg {
            case "--status", "-s":
                return .statusQuery

            case "--toggle", "-t":
                return .toggleCreativeMode

            case "--enable", "-e":
                let nextArg = iterator.next()
                if let next = nextArg, !next.hasPrefix("-") {
                    return .enableCreativeMode(appName: next)
                }
                return .enableCreativeMode(appName: nil)

            case "--disable", "-d":
                return .disableCreativeMode

            case "--recommended-calibration", "-r":
                return .setCalibratedBrightness(.appleRecommended)

            case "--preset", "-p":
                if let next = iterator.next() {
                    return resolvePresetCommand(named: next)
                }

            case "--brightness", "-b":
                if let next = iterator.next(), let val = Float(next) {
                    return .setBrightness(val)
                }

            default:
                break
            }
        }
        return nil
    }

    // MARK: - Helper

    private func resolvePresetCommand(named name: String) -> NoonCommand? {
        let clean = name.lowercased()
        if clean.contains("photo") {
            return .setPreset(.photographyP3D65)
        } else if clean.contains("print") || clean.contains("design") {
            return .setPreset(.designPrintP3D50)
        } else if clean.contains("cinema") || clean.contains("dci") {
            return .setPreset(.digitalCinemaP3DCI)
        } else if clean.contains("video") || clean.contains("709") {
            return .setPreset(.hdtvVideoBT709)
        } else if clean.contains("srgb") || clean.contains("web") {
            return .setPreset(.internetWebSRGB)
        } else if clean.contains("apple") || clean.contains("xdr") {
            return .setPreset(.appleXDR)
        }
        return nil
    }
}
