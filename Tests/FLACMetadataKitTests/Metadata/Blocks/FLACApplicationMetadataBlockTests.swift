//
//  FLACApplicationMetadataBlockTests.swift
//  
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import FLACMetadataKit

final class FLACApplicationMetadataBlockTests: XCTestCase {

    // Helper method to create a FLACMetadataBlockHeader safely
    func createHeader(
        isLast: Bool = false,
        type: FLACMetadataBlockHeader.MetadataBlockType = .application,
        dataSize: UInt32
    ) throws -> FLACMetadataBlockHeader {
        // First byte combines the isLast flag and the type.
        let firstByte: UInt8 = (isLast ? 0x80 : 0x00) | type.rawValue
        // Next three bytes represent the dataSize in big endian format.
        let sizeBytes: [UInt8] = [
            UInt8((dataSize >> 16) & 0xFF),
            UInt8((dataSize >> 8) & 0xFF),
            UInt8(dataSize & 0xFF)
        ]
        // Combine to form the header bytes.
        var headerBytes = Data([firstByte])
        headerBytes.append(contentsOf: sizeBytes)

        // Attempt to create a FLACMetadataBlockHeader with the assembled bytes.
        return try FLACMetadataBlockHeader(bytes: headerBytes)
    }


    func testInitializationWithValidData() {
        let expectedAppId = "Test" // AppId of 4 bytes
        let additionalData = "test application data".data(using: .ascii)!
        var bytes = expectedAppId.data(using: .ascii)!
        bytes.append(additionalData)

        // Correctly setting the total data size in the header
        // The total data size is simply the length of additionalData in this setup,
        // as the appId size (4 bytes) is implicitly understood to be separate.
        let totalDataSize = UInt32(additionalData.count)

        do {
            let header = try createHeader(isLast: false, type: .application, dataSize: totalDataSize)
            let block = try FLACApplicationMetadataBlock(bytes: bytes, header: header)
            XCTAssertEqual(block.appId, expectedAppId, "AppId should match the expected value.")
            XCTAssertEqual(block.data, additionalData, "Data should match the additional data provided.")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInitializationWithInvalidDataLength() {
        // Prepare
        let expectedAppId = "Fail"
        let additionalData = Data([0x05, 0x06, 0x07, 0x08])
        var bytes = expectedAppId.data(using: .ascii)!
        bytes.append(additionalData) // This makes bytes.count = 8

        do {
            let header = try createHeader(dataSize: 10) // Intentionally incorrect size
            XCTAssertThrowsError(
                try FLACApplicationMetadataBlock(bytes: bytes, header: header),
                "Initialization should throw an error due to incorrect data size."
            )
        } catch {
            XCTFail("Unexpected error during header creation: \(error)")
        }
    }
}
