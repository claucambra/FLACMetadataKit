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

    func testInitializationWithValidDataAndTrack() {
        let mediaCatalogNumber = String(repeating: "a", count: 128) // Media catalog number
        let leadInSamples: UInt64 = 88200 // Lead-in sample count
        let isCD = true

        // Mock Track data
        let trackOffset: UInt64 = 123456789
        let trackNumber: UInt8 = 1
        let trackISRC = "123456789012" // 12 characters
        let isAudio = true
        let isPreEmphasis = true
        let numberOfIndexPoints: UInt8 = 1
        let indexOffset: UInt64 = 987654321
        let indexNumber: UInt8 = 1

        // Constructing track and index point bytes
        let trackBytes = withUnsafeBytes(of: trackOffset.bigEndian) { Data($0) } +
                         Data([trackNumber]) +
                         trackISRC.data(using: .ascii)! +
                         Data([UInt8(isAudio ? 0 : 0x80) | UInt8(isPreEmphasis ? 0x40 : 0)]) +
                         Data(repeating: 0, count: 13) + // 14 reserved bytes - including flags
                         Data([numberOfIndexPoints]) +
                         withUnsafeBytes(of: indexOffset.bigEndian) { Data($0) } +
                         Data([indexNumber]) +
                         Data(repeating: 0, count: 3) // Reserved bytes for index

        let bytes = mediaCatalogNumber.data(using: .ascii)! +
                    withUnsafeBytes(of: leadInSamples.bigEndian) { Data($0) } +
                    Data([UInt8(isCD ? 0x80 : 0)]) +
                    Data(repeating: 0, count: 258) + // Reserved bits
                    Data([UInt8(1)]) + // Number of tracks
                    trackBytes

        do {
            let header = try mockHeader(
                isLast: false, type: .cueSheet, dataSize: UInt32(bytes.count)
            )
            let cueSheetBlock = try FLACCueSheetMetadataBlock(bytes: bytes, header: header)

            XCTAssertEqual(cueSheetBlock.mediaCatalogNumber, mediaCatalogNumber)
            XCTAssertEqual(cueSheetBlock.leadInSamples, leadInSamples)
            XCTAssertEqual(cueSheetBlock.isCD, isCD)
            XCTAssertEqual(cueSheetBlock.tracks.count, 1) // Verify track count

            // Verify details of the first track
            let track = cueSheetBlock.tracks.first!
            XCTAssertEqual(track.offset, trackOffset)
            XCTAssertEqual(track.number, trackNumber)
            XCTAssertEqual(track.isrc, trackISRC)
            XCTAssertEqual(track.isAudio, isAudio)
            XCTAssertEqual(track.isPreEmphasis, isPreEmphasis)
            XCTAssertEqual(track.numberOfIndexPoints, numberOfIndexPoints)

            // Verify the index point
            let index = track.indexPoints.first!
            XCTAssertEqual(index.offset, indexOffset)
            XCTAssertEqual(index.number, indexNumber)

        } catch {
            XCTFail("Failed to initialize FLACMetadataBlockHeader with error: \(error)")
        }
    }
}
