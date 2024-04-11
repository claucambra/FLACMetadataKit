//
//  FLACPictureMetadataBlockTests.swift
//
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import TestCommon
@testable import FLACMetadataKit

final class FLACPictureMetadataBlockTests: XCTestCase {

    func testInitializationWithValidData() {
        let type = FLACPictureMetadataBlock.PictureType.frontCover.rawValue
        let mimeType = "image/jpeg"
        let description = "A description"
        let imageData = Data(repeating: 0xFF, count: 10) // Simulated image data

        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: type.bigEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt32(mimeType.utf8.count).bigEndian, Array.init))
        data.append(mimeType.data(using: .utf8)!)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(description.utf8.count).bigEndian, Array.init))
        data.append(description.data(using: .utf8)!)
        // Adding mock values for width, height, color depth, and colors used
        data.append(contentsOf: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 24, 0, 0, 0, 0])
        // Adding length of the image data and the image data itself
        data.append(contentsOf: withUnsafeBytes(of: UInt32(imageData.count).bigEndian, Array.init))
        data.append(imageData)

        do {
            let header = try mockHeader(isLast: false, type: .picture, dataSize: UInt32(data.count))
            let pictureBlock = try FLACPictureMetadataBlock(bytes: data, header: header)

            XCTAssertEqual(pictureBlock.type.rawValue, type)
            XCTAssertEqual(pictureBlock.mimeType, mimeType)
            XCTAssertEqual(pictureBlock.description, description)
            XCTAssertEqual(pictureBlock.data, imageData)
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testInitializationWithInvalidData() {
        // Simulating an attempt to initialize with insufficient data
        let data = Data([0x00, 0x01, 0x02]) // Insufficient for any valid picture metadata

        do {
            let header = try mockHeader(isLast: false, type: .picture, dataSize: UInt32(data.count))
            XCTAssertThrowsError(try FLACPictureMetadataBlock(bytes: data, header: header))
        } catch {
            XCTFail("Initialization should not succeed with invalid data.")
        }
    }

    func testInitializationWithInvalidPicData() {
        let type = FLACPictureMetadataBlock.PictureType.frontCover.rawValue
        let mimeType = "image/jpeg"
        let description = "A description"
        let imageData = Data(repeating: 0xFF, count: 7) // Invalid image data

        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: type.bigEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(
            of: UInt32(mimeType.utf8.count).bigEndian, Array.init)
        )
        data.append(mimeType.data(using: .utf8)!)
        data.append(contentsOf: withUnsafeBytes(
            of: UInt32(description.utf8.count).bigEndian, Array.init)
        )
        data.append(description.data(using: .utf8)!)
        // Adding mock values for width, height, color depth, and colors used
        data.append(contentsOf: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 24, 0, 0, 0, 0])
        // Adding incorrect length of the image data and the image data itself
        data.append(contentsOf: withUnsafeBytes(of: UInt32(10).bigEndian, Array.init))
        data.append(imageData)

        do {
            let header = try mockHeader(isLast: false, type: .picture, dataSize: UInt32(data.count))
            XCTAssertThrowsError(try FLACPictureMetadataBlock(bytes: data, header: header))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testInitializationWithInvalidDescription() {
        let type = FLACPictureMetadataBlock.PictureType.frontCover.rawValue
        let mimeType = "image/jpeg"
        let description = "A description"

        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: type.bigEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(
            of: UInt32(mimeType.utf8.count).bigEndian, Array.init)
        )
        data.append(mimeType.data(using: .utf8)!)
        data.append(contentsOf: withUnsafeBytes( // Bad description count
            of: UInt32(description.utf8.count - 1).bigEndian, Array.init)
        )
        data.append(description.data(using: .utf8)!)
        // Adding mock values for width, height, color depth, and colors used
        data.append(contentsOf: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 24, 0, 0, 0, 0])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(0).bigEndian, Array.init))

        do {
            let header = try mockHeader(isLast: false, type: .picture, dataSize: UInt32(data.count))
            XCTAssertThrowsError(try FLACPictureMetadataBlock(bytes: data, header: header))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }

    func testInitializationWithInvalidMimetype() {
        let type = FLACPictureMetadataBlock.PictureType.frontCover.rawValue
        let mimeType = "image/jpeg"

        var data = Data()
        data.append(contentsOf: withUnsafeBytes(of: type.bigEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes( // Bad mimetype count
            of: UInt32(mimeType.utf8.count - 1).bigEndian, Array.init)
        )
        data.append(mimeType.data(using: .utf8)!)
        data.append(contentsOf: withUnsafeBytes(of: UInt32(0).bigEndian, Array.init)) // Description
        data.append(description.data(using: .utf8)!)
        // Adding mock values for width, height, color depth, and colors used
        data.append(contentsOf: [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 24, 0, 0, 0, 0])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(0).bigEndian, Array.init))

        do {
            let header = try mockHeader(isLast: false, type: .picture, dataSize: UInt32(data.count))
            XCTAssertThrowsError(try FLACPictureMetadataBlock(bytes: data, header: header))
        } catch {
            XCTFail("Failed with error: \(error)")
        }
    }
}
