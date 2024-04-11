//
//  FLACCueSheetMetadataBlockTests.swift
//
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import FLACMetadataKit

final class FLACCueSheetMetadataBlockTests: XCTestCase {

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

    func testInitializationWithValidData() {
        // Example data preparation
        let mediaCatalogNumber = String(repeating: "a", count: 128) // Media catalog number
        let leadInSamples: UInt64 = 88200 // Lead-in sample count
        let isCD = true
        let tracks: [FLACCueSheetMetadataBlock.Track] = []
        let bytes = mediaCatalogNumber.data(using: .ascii)! +
                    withUnsafeBytes(of: leadInSamples.bigEndian) { Data($0) } +
                    Data([UInt8(isCD ? 0x80 : 0)]) +
                    Data(repeating: 0, count: 258) + // Reserved bits
                    Data([UInt8(tracks.count)]) // Number of tracks

        do {
            let header = try mockHeader(
                isLast: false, type: .cueSheet, dataSize: UInt32(bytes.count)
            )
            let cueSheetBlock = FLACCueSheetMetadataBlock(bytes: bytes, header: header)

            XCTAssertEqual(cueSheetBlock.mediaCatalogNumber, mediaCatalogNumber)
            XCTAssertEqual(cueSheetBlock.leadInSamples, leadInSamples)
            XCTAssertEqual(cueSheetBlock.isCD, isCD)
            XCTAssertTrue(cueSheetBlock.tracks.isEmpty)
        } catch {
            XCTFail("Failed to initialize FLACMetadataBlockHeader with error: \(error)")
        }
    }
}
