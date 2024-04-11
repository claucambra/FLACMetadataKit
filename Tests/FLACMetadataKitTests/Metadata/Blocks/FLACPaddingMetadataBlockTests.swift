//
//  FLACPaddingMetadataBlockTests.swift
//
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import FLACMetadataKit

final class FLACPaddingMetadataBlockTests: XCTestCase {

    private func mockHeader(
        isLast: Bool,
        type: FLACMetadataBlockHeader.MetadataBlockType,
        dataSize: UInt32
    ) throws -> FLACMetadataBlockHeader {
            var firstByte = type.rawValue
            if isLast {
                firstByte |= 0x80 // Set the last-metadata-block flag
            }
            var data = Data([firstByte])

            // Ensure dataSize is properly represented in the next three bytes
            data.append(contentsOf: [
                UInt8((dataSize >> 16) & 0xFF),
                UInt8((dataSize >> 8) & 0xFF),
                UInt8(dataSize & 0xFF)
            ])

            return try FLACMetadataBlockHeader(bytes: data)
        }

    func testInitializationWithValidHeader() {
        let dataSize: UInt32 = 1024
        do {
            let header = try mockHeader(isLast: false, type: .padding, dataSize: dataSize)
            let paddingBlock = FLACPaddingMetadataBlock(header: header)

            XCTAssertEqual(paddingBlock.length, dataSize, "Padding block length should match the header's data size.")
        } catch {
            XCTFail("Failed to initialize FLACMetadataBlockHeader with error: \(error)")
        }
    }

    func testInitializationWithInvalidTypeHeader() {
        let dataSize: UInt32 = 512
        do {
            let header = try mockHeader(isLast: false, type: .streamInfo, dataSize: dataSize)
            let paddingBlock = FLACPaddingMetadataBlock(header: header)

            XCTAssertEqual(paddingBlock.length, dataSize, "Even with an invalid type, length is set based on header's data size.")
        } catch {
            XCTFail("Header initialization failed with error: \(error)")
        }
    }

    func testInitializationWithZeroSize() {
        do {
            let header = try mockHeader(isLast: false, type: .padding, dataSize: 0)
            let paddingBlock = FLACPaddingMetadataBlock(header: header)

            XCTAssertEqual(paddingBlock.length, 0, "Padding block length should be zero when header's data size is zero.")
        } catch {
            XCTFail("Failed to initialize FLACMetadataBlockHeader with error: \(error)")
        }
    }
}

