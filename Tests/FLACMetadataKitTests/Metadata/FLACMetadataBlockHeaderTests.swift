//
//  FLACMetadataBlockHeaderTests.swift
//  
//
//  Created by Claudio Cambra on 10/4/24.
//

import XCTest
@testable import FLACMetadataKit

class FLACMetadataBlockHeaderTests: XCTestCase {

    func testInitializationWithValidBytes() {
        // Last metadata block flag set, type is application, and a random data size
        let bytes: [UInt8] = [
            0x80 | FLACMetadataBlockHeader.MetadataBlockType.application.rawValue,
            0x00,
            0x00,
            0x03
        ]
        let header = try? FLACMetadataBlockHeader(bytes: Data(bytes))
        XCTAssertNotNil(header, "header should not be nil.")

        XCTAssertTrue(header!.isLastMetadataBlock, "isLastMetadataBlock should be true.")
        XCTAssertEqual(header!.metadataBlockType, .application, "block type should be application.")
        XCTAssertEqual(header!.metadataBlockDataSize, 3, "metadataBlockDataSize should be 3.")
    }

    func testInitializationWithInvalidType() {
        // Last metadata block flag not set, invalid type (127), and a random data size
        let bytes: [UInt8] = [127, 0x00, 0x00, 0x02]
        let header = try! FLACMetadataBlockHeader(bytes: Data(bytes))

        XCTAssertFalse(
            header.isLastMetadataBlock,
            "isLastMetadataBlock should be false for a non-last block."
        )
        XCTAssertEqual(
            header.metadataBlockType,
            .invalid,
            "metadataBlockType should be invalid for type 127."
        )
    }

    func testInitializationWithReservedType() {
        // Last metadata block flag not set, reserved type (>=7 && <=126), and a random data size
        let bytes: [UInt8] = [0x07, 0x00, 0x00, 0x01] // Using 7 as an example reserved type
        let header = try? FLACMetadataBlockHeader(bytes: Data(bytes))
        XCTAssertNotNil(header, "header should not be nil.")

        XCTAssertEqual(header!.metadataBlockType, .reserved, "metadataBlockType should be reserved for type 7.")
    }

    func testBigEndianDataSize() {
        // Testing correct big endian conversion for data size
        let dataSize: UInt32 = 0x01ABCD
        let bytes: [UInt8] = [
            FLACMetadataBlockHeader.MetadataBlockType.application.rawValue,
            UInt8((dataSize & 0xFF0000) >> 16),
            UInt8((dataSize & 0x00FF00) >> 8),
            UInt8(dataSize & 0x0000FF)
        ]
        let header = try! FLACMetadataBlockHeader(bytes: Data(bytes))

        XCTAssertEqual(
            header.metadataBlockDataSize,
            dataSize,
            "metadataBlockDataSize should correctly represent the big endian UInt32 value."
        )
    }

    func testIsLastMetadataBlockFlag() {
        // Testing the isLastMetadataBlock flag independently
        let bytesForLastBlock: [UInt8] = [0x80, 0x00, 0x00, 0x05]
        let headerForLastBlock = try! FLACMetadataBlockHeader(bytes: Data(bytesForLastBlock))
        XCTAssertTrue(
            headerForLastBlock.isLastMetadataBlock,
            "isLastMetadataBlock should be true when the highest bit is set."
        )

        let bytesForNotLastBlock: [UInt8] = [
            FLACMetadataBlockHeader.MetadataBlockType.streamInfo.rawValue, 0x00, 0x00, 0x05
        ]
        let headerForNotLastBlock = try! FLACMetadataBlockHeader(bytes: Data(bytesForNotLastBlock))
        XCTAssertFalse(
            headerForNotLastBlock.isLastMetadataBlock,
            "isLastMetadataBlock should be false when the highest bit is not set."
        )
    }

    func testInitializationWithInvalidInputLength() {
        // Testing with insufficient bytes for a valid header
        let insufficientBytes: [UInt8] = [0x80] // Only 1 byte, but at least 4 bytes are needed
        let excessiveBytes: [UInt8] = [0x80, 0x00, 0x00, 0x01, 0x02] // More than 4 bytes

        // Expecting an assertion failure or specific handling of invalid input lengths
        // For insufficient bytes
        XCTAssertThrowsError(
            try FLACMetadataBlockHeader(bytes: Data(insufficientBytes)),
            "Initialization with insufficient bytes should throw an error."
        )

        // For excessive bytes
        XCTAssertThrowsError(
            try FLACMetadataBlockHeader(bytes: Data(excessiveBytes)),
            "Initialization with excessive bytes should throw an error."
        )
    }

}

