//
//  FLACStreamInfoMetadataBlockTests.swift
//  
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import TestCommon
@testable import FLACMetadataKit

final class FLACStreamInfoMetadataBlockTests: XCTestCase {

    func testInitializationWithValidData() {
        // Simulate valid FLAC stream info metadata block bytes
        let sampleRate: UInt32 = 44100
        let channels: UInt32 = 2
        let bitsPerSample: UInt32 = 16
        let totalSamples: UInt64 = 1_000_000

        var bytes = Data()
        bytes += withUnsafeBytes(of: UInt16(1).bigEndian, Array.init) // minimumBlockSize
        bytes += withUnsafeBytes(of: UInt16(4096).bigEndian, Array.init) // maximumBlockSize
        bytes += withUnsafeBytes(of: UInt32(123).bigEndian, Array.init)[1...] // minimumFrameSize, 3 bytes
        bytes += withUnsafeBytes(of: UInt32(456).bigEndian, Array.init)[1...] // maximumFrameSize, 3 bytes
        // Packing sampleRate, channels, and bitsPerSample into 4 bytes
        let sampleRateChannelsBits =
            (sampleRate << 12) | ((channels - 1) << 9) | ((bitsPerSample - 1) << 4)
        bytes += withUnsafeBytes(of: sampleRateChannelsBits.bigEndian, Array.init)[0..<4]
        // Packing totalSamples into 4 bytes
        bytes += withUnsafeBytes(of: totalSamples.bigEndian, Array.init)[4..<8]
        // MD5 signature placeholder
        bytes += Data(repeating: 0, count: 16) // MD5, simplified for example

        do {
            let header = try mockHeader(isLast: false, type: .streamInfo, dataSize: UInt32(bytes.count))
            let block = try FLACStreamInfoMetadataBlock(bytes: bytes, header: header)

            XCTAssertEqual(block.minimumBlockSize, 1)
            XCTAssertEqual(block.maximumBlockSize, 4096)
            XCTAssertEqual(block.minimumFrameSize, 123)
            XCTAssertEqual(block.maximumFrameSize, 456)
            XCTAssertEqual(block.sampleRate, sampleRate)
            XCTAssertEqual(block.channels, channels)
            XCTAssertEqual(block.bitsPerSample, bitsPerSample)
            XCTAssertEqual(block.totalSamples, totalSamples)
            XCTAssertEqual(block.md5, String(repeating: "00", count: 16))
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }

    func testInitializationWithInvalidDataLengths() {
        // Testing with an array shorter than needed for a complete FLACStreamInfoMetadataBlock
        let shortBytes = Data([0x00, 0x01]) // Insufficient data
        do {
            let header = try FLACMetadataBlockHeader(bytes: Data([0x00, 0x00, 0x00, 0x02])) // Type 0, not last, with incorrect size
            XCTAssertThrowsError(
                try FLACStreamInfoMetadataBlock(bytes: shortBytes, header: header)
            )
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }
}

