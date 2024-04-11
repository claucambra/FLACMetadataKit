//
//  FLACParserTests.swift
//  
//
//  Created by Claudio Cambra on 11/4/24.
//

import XCTest
@testable import FLACMetadataKit

final class FLACParserTests: XCTestCase {

    func testParsingValidFLACData() {
        guard let sampleFileUrl = Bundle.module.url(forResource: "sample-3", withExtension: "flac")
        else {
            XCTFail("Could not get sample file url!")
            return
        }

        do {
            let data = try Data(contentsOf: sampleFileUrl)
            let parser = FLACParser(data: data)

            XCTAssertNoThrow(try {
                let metadata = try parser.parse()
                XCTAssertNotNil(metadata.vorbisComments, "Comments metadata block should be parsed")
            }(), "Parsing valid FLAC data should not throw")
        } catch {
            XCTFail("Failed to read sample file: \(error)")
        }
    }

    func testParsingNonFLACData() {
        let nonFLACData = Data("NotFLAC".utf8)
        let parser = FLACParser(data: nonFLACData)

        XCTAssertThrowsError(try parser.parse()) { error in
            guard let _ = error as? FLACParser.ParseError else {
                XCTFail("Unexpected error type: \(error)")
                return
            }
        }
    }

    // Test for FLAC data with unexpected end (incomplete block)
    func testParsingFLACDataWithUnexpectedEnd() {
        let flacMarker = "fLaC".data(using: .ascii)!
        // Data ends unexpectedly, simulating incomplete metadata block
        let incompleteData = flacMarker + Data([0x00] + Data(repeating: 0, count: 10))
        let parser = FLACParser(data: incompleteData)

        XCTAssertThrowsError(try parser.parse()) { error in
            guard let _ = error as? FLACParser.ParseError else {
                XCTFail("Unexpected error type: \(error)")
                return
            }
        }
    }
}

