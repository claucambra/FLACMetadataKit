//
//  FLACBlockHeader.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

public struct FLACMetadataBlockHeader {
    public enum MetadataBlockType: UInt8 {
        case streamInfo
        case padding
        case application
        case seekTable
        case vorbisComment
        case cueSheet
        case picture
        case reserved
        case invalid
        case undefined

        init(byte: UInt8) {
            let type = byte & 0x7F  // Ignore largest bit of byte as that's last block flag
            if type == 127 {
                self = .invalid
            } else if type <= 126, type >= 7 {
                self = .reserved
            } else {
                self = MetadataBlockType(rawValue: type) ?? .undefined
            }
        }
    }

    static let size = 4  // Bytes
    public let isLastMetadataBlock: Bool
    public let metadataBlockType: MetadataBlockType
    public let metadataBlockDataSize: UInt32

    init(bytes: Data) throws {
        guard bytes.count == 4 else {
            throw FLACParser.ParseError.unexpectedEndError(
                "Cannot parse metadata block header, unexpected data size!"
            )
        }

        isLastMetadataBlock = (bytes[0] & 0x80) != 0  // Check largest bit of byte
        metadataBlockType = MetadataBlockType(byte: bytes[0])

        var usableMetadataBlockDataSize: UInt32 = 0
        for i in 1..<4 {
            usableMetadataBlockDataSize = (usableMetadataBlockDataSize << 8) | UInt32(bytes[i])
        } // big endian numbers
        metadataBlockDataSize = usableMetadataBlockDataSize
    }
}
