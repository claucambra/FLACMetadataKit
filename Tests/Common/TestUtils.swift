//
//  TestUtils.swift
//  
//
//  Created by Claudio Cambra on 11/4/24.
//

import Foundation
@testable import FLACMetadataKit

func mockHeader(isLast: Bool, type: FLACMetadataBlockHeader.MetadataBlockType, dataSize: UInt32) throws -> FLACMetadataBlockHeader {
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
