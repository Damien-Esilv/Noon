//
//  AmbientLightMonitor.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import IOKit
import Observation

// MARK: - Ambient Light Sensor Protocol

public protocol AmbientLightSensorProtocol: Sendable {
    func readAmbientLight() async -> AmbientLightReading?
    func isSensorAvailable() async -> Bool
}

// MARK: - Ambient Light Monitor

@Observable
@MainActor
public final class AmbientLightMonitor {
    public static let shared = AmbientLightMonitor()

    // MARK: - Observable State

    public private(set) var currentReading: AmbientLightReading?
    public private(set) var baselineReading: AmbientLightReading?
    public private(set) var isLightingDriftExceeded: Bool = false
    public private(set) var driftPercentage: Double = 0.0
    public private(set) var isMonitoring: Bool = false

    // MARK: - Threshold Configuration

    /// Drift percentage threshold (e.g. 0.30 = 30% drift from baseline triggers warning)
    public var driftThresholdRatio: Double = 0.30

    /// Absolute lux change threshold (e.g. 50.0 Lux)
    public var absoluteLuxThreshold: Double = 50.0

    // MARK: - Dependencies

    private let sensor: AmbientLightSensorProtocol
    private var pollingTimer: Timer?

    public init(sensor: AmbientLightSensorProtocol = NativeAppleLMUSensor()) {
        self.sensor = sensor
    }

    // MARK: - Session Lifecycle

    public func startMonitoring(interval: TimeInterval = 5.0) {
        guard !isMonitoring else { return }
        isMonitoring = true
        isLightingDriftExceeded = false
        driftPercentage = 0.0

        Task {
            // Establish baseline reading
            if let reading = await sensor.readAmbientLight() {
                self.baselineReading = reading
                self.currentReading = reading
            }

            self.pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.pollSensor()
                }
            }
        }
    }

    public func stopMonitoring() {
        isMonitoring = false
        pollingTimer?.invalidate()
        pollingTimer = nil
        baselineReading = nil
        isLightingDriftExceeded = false
        driftPercentage = 0.0
    }

    // MARK: - Polling & Drift Detection

    public func pollSensor() async {
        guard let reading = await sensor.readAmbientLight() else {
            return
        }
        self.currentReading = reading

        guard let baseline = baselineReading else {
            self.baselineReading = reading
            return
        }

        let deltaLux = abs(reading.lux - baseline.lux)
        let ratio = deltaLux / max(baseline.lux, 1.0)
        self.driftPercentage = ratio * 100.0

        if ratio >= driftThresholdRatio || deltaLux >= absoluteLuxThreshold {
            self.isLightingDriftExceeded = true
        } else {
            self.isLightingDriftExceeded = false
        }
    }

    public func resetBaseline() {
        if let current = currentReading {
            baselineReading = current
            isLightingDriftExceeded = false
            driftPercentage = 0.0
        }
    }
}

// MARK: - Native AppleLMU IOKit Sensor

public final class NativeAppleLMUSensor: AmbientLightSensorProtocol, @unchecked Sendable {
    public init() {}

    public func isSensorAvailable() async -> Bool {
        let matching = IOServiceMatching("AppleLMUController")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        if service != 0 {
            IOObjectRelease(service)
            return true
        }
        return false
    }

    public func readAmbientLight() async -> AmbientLightReading? {
        let matching = IOServiceMatching("AppleLMUController")
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else {
            return nil
        }
        defer { IOObjectRelease(service) }

        // Read sensor properties
        var leftVal: Double = 0
        var rightVal: Double = 0

        if let leftProp = IORegistryEntryCreateCFProperty(service, "LeftSensor" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber {
            leftVal = leftProp.doubleValue
        }
        if let rightProp = IORegistryEntryCreateCFProperty(service, "RightSensor" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? NSNumber {
            rightVal = rightProp.doubleValue
        }

        // Nominal lux calculation: average sensor reading divided by sensitivity constant
        let avgRaw = (leftVal + rightVal) / 2.0
        let lux = avgRaw > 0 ? avgRaw : 120.0 // Default nominal studio ambient lux

        return AmbientLightReading(
            lux: lux,
            timestamp: Date(),
            rawLeft: leftVal,
            rawRight: rightVal
        )
    }
}

// MARK: - Mock Ambient Light Sensor (For Unit Testing)

public actor MockAmbientLightSensor: AmbientLightSensorProtocol {
    private var simulatedReading: AmbientLightReading?
    private var available: Bool

    public init(initialLux: Double = 100.0, available: Bool = true) {
        self.simulatedReading = AmbientLightReading(lux: initialLux)
        self.available = available
    }

    public func setSimulatedLux(_ lux: Double) {
        simulatedReading = AmbientLightReading(lux: lux)
    }

    public func setAvailable(_ isAvailable: Bool) {
        self.available = isAvailable
    }

    public func isSensorAvailable() -> Bool {
        available
    }

    public func readAmbientLight() -> AmbientLightReading? {
        guard available else { return nil }
        return simulatedReading
    }
}
