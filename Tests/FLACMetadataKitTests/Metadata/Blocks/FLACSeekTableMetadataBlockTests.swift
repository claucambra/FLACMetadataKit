//
//  FLACSeekTableMetadataBlockTests.swift
//  
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import FLACMetadataKit

final class FLACSeekTableMetadataBlockTests: XCTestCase {

    // Function adjusted to simulate throwing behavior for invalid inputs
    private func mockHeader(isLast: Bool, type: FLACMetadataBlockHeader.MetadataBlockType, dataSize: UInt32) throws -> FLACMetadataBlockHeader {
        var firstByte = type.rawValue
        if isLast {
            firstByte |= 0x80 // Set the last-metadata-block flag
        }

        // Creating a correctly sized Data object for the header
        var data = Data([firstByte])
        let dataSizeBytes: [UInt8] = [
            UInt8((dataSize >> 16) & 0xFF),
            UInt8((dataSize >> 8) & 0xFF),
            UInt8(dataSize & 0xFF)
        ]
        data.append(contentsOf: dataSizeBytes)

        return try FLACMetadataBlockHeader(bytes: data)
    }

    // Testing initialization with valid data
    func testInitializationWithValidData() {
        let sampleNumber: UInt64 = 1234567890
        let streamOffset: UInt64 = 9876543210
        let frameSamples: UInt16 = 1234

        // Constructing bytes for one seek point
        var bytes = Data()
        bytes.append(contentsOf: withUnsafeBytes(of: sampleNumber.bigEndian, Array.init))
        bytes.append(contentsOf: withUnsafeBytes(of: streamOffset.bigEndian, Array.init))
        bytes.append(contentsOf: withUnsafeBytes(of: frameSamples.bigEndian, Array.init))

        // Add an identical second for test
        bytes.append(contentsOf: withUnsafeBytes(of: sampleNumber.bigEndian, Array.init))
        bytes.append(contentsOf: withUnsafeBytes(of: streamOffset.bigEndian, Array.init))
        bytes.append(contentsOf: withUnsafeBytes(of: frameSamples.bigEndian, Array.init))

        // Assuming there's just one seek point for simplicity
        do {
            let header = try mockHeader(
                isLast: false, type: .seekTable, dataSize: UInt32(bytes.count)
            )
            let seekTableBlock = try FLACSeekTableMetadataBlock(bytes: bytes, header: header)

            XCTAssertEqual(seekTableBlock.points.count, 2)
            XCTAssertEqual(seekTableBlock.points.first?.sampleNumber, sampleNumber)
            XCTAssertEqual(seekTableBlock.points.first?.streamOffset, streamOffset)
            XCTAssertEqual(seekTableBlock.points.first?.frameSamples, frameSamples)
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }

    // Testing initialization with incomplete seek point data
    func testInitializationWithIncompleteSeekPointData() {
        // Constructing incomplete bytes for a seek point
        let incompleteSeekPointBytes = Data(
            repeating: 0, count: FLACSeekTableMetadataBlock.SeekPoint.size
        ) // Incomplete for any valid seek point
        let dataSize = UInt32(FLACSeekTableMetadataBlock.SeekPoint.size * 2)

        do {
            let header = try mockHeader(isLast: false, type: .seekTable, dataSize: dataSize)
            XCTAssertThrowsError(
                try FLACSeekTableMetadataBlock(bytes: incompleteSeekPointBytes, header: header)
            )
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }

}
