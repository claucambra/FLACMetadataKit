//
//  FLACPaddingMetadataBlockTests.swift
//
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import TestCommon
@testable import FLACMetadataKit

final class FLACPaddingMetadataBlockTests: XCTestCase {

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

