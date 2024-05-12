//
//  FLACApplicationMetadataBlockTests.swift
//  
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import TestCommon
@testable import FLACMetadataKit

final class FLACApplicationMetadataBlockTests: XCTestCase {

    func testInitializationWithValidData() {
        let expectedAppId = "Test" // AppId of 4 bytes
        let additionalData = "test application data".data(using: .ascii)!
        var bytes = expectedAppId.data(using: .ascii)!
        bytes.append(additionalData)

        // Correctly setting the total data size in the header
        // The total data size is simply the length of additionalData in this setup,
        // as the appId size (4 bytes) is implicitly understood to be separate.
        let totalDataSize = UInt32(expectedAppId.count + additionalData.count)

        do {
            let header = try mockHeader(isLast: false, type: .application, dataSize: totalDataSize)
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
            // Intentionally incorrect size
            let header = try mockHeader(isLast: false, type: .application, dataSize: 10)
            XCTAssertThrowsError(
                try FLACApplicationMetadataBlock(bytes: bytes, header: header),
                "Initialization should throw an error due to incorrect data size."
            )
        } catch {
            XCTFail("Unexpected error during header creation: \(error)")
        }
    }

    func testInitializationWithInvalidAppId() {
        // Prepare
        let expectedAppId = "No"
        let bytes = expectedAppId.data(using: .ascii)!

        do {
            // Intentionally incorrect size
            let header = try mockHeader(isLast: false, type: .application, dataSize: 10)
            XCTAssertThrowsError(
                try FLACApplicationMetadataBlock(bytes: bytes, header: header),
                "Initialization should throw an error due to bad app ID."
            )
        } catch {
            XCTFail("Unexpected error during header creation: \(error)")
        }
    }
}
