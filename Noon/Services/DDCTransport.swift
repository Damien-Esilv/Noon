//
//  DDCTransport.swift
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

import Foundation
import CoreGraphics
import IOKit

// MARK: - DDC Packet Protocol

public struct DDCPacket: Equatable, Sendable {
    public static let destinationAddress: UInt8 = 0x6E
    public static let sourceAddress: UInt8 = 0x51
    public static let setVCPCommand: UInt8 = 0x03
    public static let getVCPCommand: UInt8 = 0x01
    public static let getVCPReplyCommand: UInt8 = 0x02

    public let bytes: [UInt8]

    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    /// Computes the standard DDC/CI XOR checksum.
    /// The checksum includes the destination address (0x6E) XORed with all packet bytes.
    public static func computeChecksum(for bodyBytes: [UInt8], destination: UInt8 = destinationAddress) -> UInt8 {
        var checksum: UInt8 = destination
        for byte in bodyBytes {
            checksum ^= byte
        }
        return checksum
    }

    /// Encodes a Set VCP feature command packet
    public static func makeSetVCPPacket(opcode: UInt8, value: UInt16) -> DDCPacket {
        let lengthByte: UInt8 = 0x84 // 0x80 | 4 data bytes
        let highByte = UInt8((value >> 8) & 0xFF)
        let lowByte = UInt8(value & 0xFF)

        let body: [UInt8] = [
            sourceAddress,
            lengthByte,
            setVCPCommand,
            opcode,
            highByte,
            lowByte
        ]
        let checksum = computeChecksum(for: body)
        return DDCPacket(bytes: body + [checksum])
    }

    /// Encodes a Get VCP feature request packet
    public static func makeGetVCPPacket(opcode: UInt8) -> DDCPacket {
        let lengthByte: UInt8 = 0x82 // 0x80 | 2 data bytes
        let body: [UInt8] = [
            sourceAddress,
            lengthByte,
            getVCPCommand,
            opcode
        ]
        let checksum = computeChecksum(for: body)
        return DDCPacket(bytes: body + [checksum])
    }

    /// Validates the checksum of an incoming DDC/CI reply packet
    public static func validateReplyChecksum(_ replyBytes: [UInt8], destination: UInt8 = 0x50) -> Bool {
        guard replyBytes.count >= 3 else { return false }
        var sum: UInt8 = destination
        for i in 0..<(replyBytes.count - 1) {
            sum ^= replyBytes[i]
        }
        return sum == replyBytes.last
    }

    /// Parses a Get VCP reply packet: returns (currentValue, maxValue)
    public static func parseGetVCPReply(_ bytes: [UInt8]) -> (current: UInt16, max: UInt16)? {
        guard bytes.count >= 8 else { return nil }

        if let cmdIndex = bytes.firstIndex(of: getVCPReplyCommand), cmdIndex + 7 < bytes.count {
            let maxH = UInt16(bytes[cmdIndex + 4])
            let maxL = UInt16(bytes[cmdIndex + 5])
            let curH = UInt16(bytes[cmdIndex + 6])
            let curL = UInt16(bytes[cmdIndex + 7])
            let maxValue = (maxH << 8) | maxL
            let curValue = (curH << 8) | curL
            return (curValue, maxValue)
        }
        return nil
    }
}

// MARK: - DDC Transport Protocol

public protocol DDCTransportProtocol: Sendable {
    func writeVCP(displayID: CGDirectDisplayID, opcode: UInt8, value: UInt16) async throws
    func readVCP(displayID: CGDirectDisplayID, opcode: UInt8) async throws -> (current: UInt16, max: UInt16)
    func isSupported(displayID: CGDirectDisplayID) async -> Bool
}

// MARK: - Mock DDC Transport (For Unit Tests and In-Memory Simulation)

public actor MockDDCTransport: DDCTransportProtocol {
    private var registers: [CGDirectDisplayID: [UInt8: UInt16]] = [:]
    private var supportedDisplays: Set<CGDirectDisplayID> = []

    public init(supportedDisplays: Set<CGDirectDisplayID> = []) {
        self.supportedDisplays = supportedDisplays
    }

    public func setSupported(_ displayID: CGDirectDisplayID, supported: Bool) {
        if supported {
            supportedDisplays.insert(displayID)
        } else {
            supportedDisplays.remove(displayID)
        }
    }

    public func isSupported(displayID: CGDirectDisplayID) -> Bool {
        supportedDisplays.contains(displayID)
    }

    public func writeVCP(displayID: CGDirectDisplayID, opcode: UInt8, value: UInt16) throws {
        guard supportedDisplays.contains(displayID) else {
            throw DDCError.unsupportedDisplay(displayID)
        }
        var displayRegs = registers[displayID] ?? [:]
        displayRegs[opcode] = value
        registers[displayID] = displayRegs
    }

    public func readVCP(displayID: CGDirectDisplayID, opcode: UInt8) throws -> (current: UInt16, max: UInt16) {
        guard supportedDisplays.contains(displayID) else {
            throw DDCError.unsupportedDisplay(displayID)
        }
        let val = registers[displayID]?[opcode] ?? 100
        return (val, 100)
    }

    public func getRegisterValue(displayID: CGDirectDisplayID, opcode: UInt8) -> UInt16? {
        registers[displayID]?[opcode]
    }
}

// MARK: - Errors

public enum DDCError: Error, LocalizedError, Equatable {
    case unsupportedDisplay(CGDirectDisplayID)
    case writeFailed(String)
    case readFailed(String)
    case checksumMismatch
    case timeout

    public var errorDescription: String? {
        switch self {
        case .unsupportedDisplay(let id):
            return "Display \(id) does not support DDC/CI communication."
        case .writeFailed(let reason):
            return "Failed to send DDC/CI command: \(reason)"
        case .readFailed(let reason):
            return "Failed to read DDC/CI response: \(reason)"
        case .checksumMismatch:
            return "DDC/CI response checksum failed."
        case .timeout:
            return "DDC/CI communication timed out."
        }
    }
}

// MARK: - Native Apple Silicon / Intel DDC Transport

public final class NativeDDCTransport: DDCTransportProtocol, @unchecked Sendable {
    private typealias IOAVServiceCreateFunc = @convention(c) (CFAllocator?, CGDirectDisplayID) -> CFTypeRef?
    private typealias IOAVServiceWriteI2CFunc = @convention(c) (CFTypeRef, UInt32, UInt32, UnsafePointer<UInt8>, UInt32) -> Int32
    private typealias IOAVServiceReadI2CFunc = @convention(c) (CFTypeRef, UInt32, UInt32, UnsafeMutablePointer<UInt8>, UInt32) -> Int32

    private let ioavCreate: IOAVServiceCreateFunc?
    private let ioavWrite: IOAVServiceWriteI2CFunc?
    private let ioavRead: IOAVServiceReadI2CFunc?

    public init() {
        if let handle = dlopen(nil, RTLD_LAZY) {
            if let createSym = dlsym(handle, "IOAVServiceCreateWithServiceForDisplay") {
                self.ioavCreate = unsafeBitCast(createSym, to: IOAVServiceCreateFunc.self)
            } else {
                self.ioavCreate = nil
            }
            if let writeSym = dlsym(handle, "IOAVServiceWriteI2C") {
                self.ioavWrite = unsafeBitCast(writeSym, to: IOAVServiceWriteI2CFunc.self)
            } else {
                self.ioavWrite = nil
            }
            if let readSym = dlsym(handle, "IOAVServiceReadI2C") {
                self.ioavRead = unsafeBitCast(readSym, to: IOAVServiceReadI2CFunc.self)
            } else {
                self.ioavRead = nil
            }
        } else {
            self.ioavCreate = nil
            self.ioavWrite = nil
            self.ioavRead = nil
        }
    }

    public func isSupported(displayID: CGDirectDisplayID) async -> Bool {
        if CGDisplayIsBuiltin(displayID) != 0 {
            return false
        }
        guard let ioavCreate = ioavCreate else { return false }
        guard let _ = ioavCreate(kCFAllocatorDefault, displayID) else { return false }
        return true
    }

    public func writeVCP(displayID: CGDirectDisplayID, opcode: UInt8, value: UInt16) async throws {
        if CGDisplayIsBuiltin(displayID) != 0 {
            throw DDCError.unsupportedDisplay(displayID)
        }
        guard let ioavCreate = ioavCreate, let ioavWrite = ioavWrite else {
            throw DDCError.writeFailed("IOAVService functions unavailable on this architecture.")
        }

        guard let service = ioavCreate(kCFAllocatorDefault, displayID) else {
            throw DDCError.unsupportedDisplay(displayID)
        }

        let packet = DDCPacket.makeSetVCPPacket(opcode: opcode, value: value)
        var data = packet.bytes

        let chipAddress: UInt32 = 0x37
        let subAddress: UInt32 = 0x51

        let status = data.withUnsafeBufferPointer { ptr -> Int32 in
            guard let baseAddress = ptr.baseAddress else { return -1 }
            return ioavWrite(service, chipAddress, subAddress, baseAddress, UInt32(ptr.count))
        }

        if status != 0 {
            throw DDCError.writeFailed("Kernel returned I2C error status \(status)")
        }
    }

    public func readVCP(displayID: CGDirectDisplayID, opcode: UInt8) async throws -> (current: UInt16, max: UInt16) {
        if CGDisplayIsBuiltin(displayID) != 0 {
            throw DDCError.unsupportedDisplay(displayID)
        }
        guard let ioavCreate = ioavCreate, let ioavWrite = ioavWrite, let ioavRead = ioavRead else {
            throw DDCError.readFailed("IOAVService functions unavailable on this architecture.")
        }

        guard let service = ioavCreate(kCFAllocatorDefault, displayID) else {
            throw DDCError.unsupportedDisplay(displayID)
        }

        let req = DDCPacket.makeGetVCPPacket(opcode: opcode)
        var reqData = req.bytes
        let writeStatus = reqData.withUnsafeBufferPointer { ptr -> Int32 in
            guard let baseAddress = ptr.baseAddress else { return -1 }
            return ioavWrite(service, 0x37, 0x51, baseAddress, UInt32(ptr.count))
        }
        guard writeStatus == 0 else {
            throw DDCError.writeFailed("Get VCP write failed with status \(writeStatus)")
        }

        try await Task.sleep(nanoseconds: 40_000_000)

        var replyBuffer = [UInt8](repeating: 0, count: 12)
        let readStatus = replyBuffer.withUnsafeMutableBufferPointer { ptr -> Int32 in
            guard let baseAddress = ptr.baseAddress else { return -1 }
            return ioavRead(service, 0x37, 0x51, baseAddress, UInt32(ptr.count))
        }

        guard readStatus == 0 else {
            throw DDCError.readFailed("I2C read failed with status \(readStatus)")
        }

        guard let result = DDCPacket.parseGetVCPReply(replyBuffer) else {
            throw DDCError.readFailed("Invalid DDC reply format.")
        }
        return result
    }
}
