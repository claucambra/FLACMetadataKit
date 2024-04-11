//
//  FLACVorbisCommentsMetadataBlockTests.swift
//
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import TestCommon
@testable import FLACMetadataKit

class FLACVorbisCommentsMetadataBlockTests: XCTestCase {

    func testInitializationWithValidData() {
        let vendor = "TestVendor"
        let comments: [(FLACVorbisCommentsMetadataBlock.Field, String)] = [
            (.title, "Test Title"),
            (.album, "Test Album"),
            (.artist, "Test Artist")
        ]

        var data = Data()
        data.append(
            contentsOf: withUnsafeBytes(of: UInt32(vendor.utf8.count).littleEndian, Array.init)
        )
        data.append(vendor.data(using: .utf8)!)
        data.append(
            contentsOf: withUnsafeBytes(of: UInt32(comments.count).littleEndian, Array.init)
        )

        for (field, value) in comments {
            let comment = "\(field.rawValue)=\(value)"
            data.append(
                contentsOf: withUnsafeBytes(of: UInt32(comment.utf8.count).littleEndian, Array.init)
            )
            data.append(comment.data(using: .utf8)!)
        }

        do {
            let header = try mockHeader(
                isLast: false, type: .vorbisComment, dataSize: UInt32(data.count)
            )
            let block = try FLACVorbisCommentsMetadataBlock(bytes: data, header: header)
            XCTAssertEqual(block.vendor, vendor)
            XCTAssertEqual(block.metadata.count, comments.count)
            for (field, expectedValue) in comments {
                XCTAssertEqual(block.metadata[field], expectedValue)
            }
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }

    func testInitializationWithInvalidVendorLength() {
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: UInt32(5000).littleEndian, Array.init)) // Exaggerated length

        do {
            let header = try mockHeader(
                isLast: false, type: .vorbisComment, dataSize: UInt32(data.count)
            )
            XCTAssertThrowsError(
                try FLACVorbisCommentsMetadataBlock(bytes: data, header: header)
            )
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }

    func testInitializationWithInvalidCommentLength() {
        let vendor = "TestVendor"
        var data = Data()
        // Vendor string length and vendor string
        data.append(contentsOf: withUnsafeBytes(of: UInt32(vendor.utf8.count).littleEndian, Array.init))
        data.append(vendor.data(using: .utf8)!)
        // Number of comments
        data.append(contentsOf: withUnsafeBytes(of: UInt32(1).littleEndian, Array.init))
        // An exaggerated comment length that exceeds the actual data available
        data.append(contentsOf: withUnsafeBytes(of: UInt32(5000).littleEndian, Array.init))

        do {
            let header = try mockHeader(
                isLast: false, type: .vorbisComment, dataSize: UInt32(data.count)
            )

            XCTAssertThrowsError(
                try FLACVorbisCommentsMetadataBlock(bytes: data, header: header)
            )
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }

    // Test for malformed comment data (missing '=' separator)
    func testInitializationWithMalformedCommentData() {
        let vendor = "TestVendor"
        let malformedComment = "ThisIsNotAValidComment"
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: UInt32(vendor.utf8.count).littleEndian, Array.init))
        data.append(vendor.data(using: .utf8)!)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(1).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt32(malformedComment.utf8.count).littleEndian, Array.init))
        data.append(malformedComment.data(using: .utf8)!)

        do {
            let header = try mockHeader(
                isLast: false, type: .vorbisComment, dataSize: UInt32(data.count)
            )
            let block = try FLACVorbisCommentsMetadataBlock(bytes: data, header: header)
            XCTAssertTrue(block.metadata.isEmpty, "Metadata should be empty due to malformed comment data")
        } catch {
            XCTFail("Initialization should not fail even with malformed comment data: \(error)")
        }
    }

    // Test for an empty comments block
    func testInitializationWithEmptyCommentsBlock() {
        let vendor = "TestVendor"
        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: UInt32(vendor.utf8.count).littleEndian, Array.init))
        data.append(vendor.data(using: .utf8)!)
        // Indicate 0 comments
        data.append(contentsOf: withUnsafeBytes(of: UInt32(0).littleEndian, Array.init))

        do {
            let header = try mockHeader(
                isLast: false, type: .vorbisComment, dataSize: UInt32(data.count)
            )
            let block = try FLACVorbisCommentsMetadataBlock(bytes: data, header: header)
            XCTAssertEqual(block.vendor, vendor, "Vendor string should be parsed correctly")
            XCTAssertTrue(block.metadata.isEmpty, "Metadata should be empty for an empty comments block")
        } catch {
            XCTFail("Initialization failed with error: \(error)")
        }
    }

}
