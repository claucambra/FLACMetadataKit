//
//  FLACPictureMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import CoreGraphics
import Foundation

public struct FLACPictureMetadataBlock {
    public enum PictureType: UInt32 {
        case other
        case fileIcon  // 32x32 pixels 'file icon' (PNG only)
        case otherFileIcon
        case frontCover
        case backCover
        case leafletPage
        case media  // Media (e.g. label side of CD)
        case leadArtist // Lead artist/lead performer/soloist
        case artist
        case conductor
        case band
        case composer
        case lyricist
        case recordingLocation
        case duringRecording
        case duringPerformance
        case videoScreenCapture
        case fish  // A bright coloured fish (??)
        case illustration
        case bandLogotype  // Band/artist logotype
        case publisherLogotype
        case undefined
    }

    // Pic type, MIME type string length, description length, width, height, color depth,
    // color used, data length
    static let picTypeSize = 4
    static let mimeTypeStringLengthSize = 4
    static let descriptionLengthSize = 4
    static let widthSize = 4
    static let heightSize = 4
    static let colorDepthSize = 4
    static let colorUsedSize = 4
    static let lengthSize = 4

    static public let minSize = picTypeSize + 
                                mimeTypeStringLengthSize +
                                descriptionLengthSize +
                                widthSize +
                                heightSize +
                                colorDepthSize +
                                colorUsedSize +
                                lengthSize
    public let header: FLACMetadataBlockHeader
    public let type: PictureType
    public let mimeType: String
    public let description: String?
    public let size: CGSize
    public let colorDepth: UInt32
    // For indexed-color pictures (e.g. GIF), number of colors used, or 0 for non-indexed pictures.
    public let colorUsed: UInt32
    public let length: UInt32
    public let data: Data

    init(bytes: Data, header: FLACMetadataBlockHeader) throws {
        guard bytes.count >= FLACPictureMetadataBlock.minSize else {
            throw FLACParser.ParseError.unexpectedEndError(
                "Cannot parse picture metadata block, unexpected data size!"
            )
        }
        self.header = header

        var advancedBytes = bytes.advanced(by: 0)
        let typeValue = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        type = PictureType(rawValue: typeValue) ?? .undefined
        advancedBytes = advancedBytes.advanced(by: 4)

        let mimeTypeLength = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        guard advancedBytes.count >= mimeTypeLength +
                                     FLACPictureMetadataBlock.descriptionLengthSize +
                                     FLACPictureMetadataBlock.widthSize +
                                     FLACPictureMetadataBlock.heightSize +
                                     FLACPictureMetadataBlock.colorDepthSize +
                                     FLACPictureMetadataBlock.colorUsedSize +
                                     FLACPictureMetadataBlock.lengthSize
        else {
            throw FLACParser.ParseError.unexpectedEndError(
                "Cannot parse picture metadata block, encountered missing mime type data!"
            )
        }

        mimeType = String(bytes: advancedBytes[0..<mimeTypeLength], encoding: .ascii) ?? ""
        advancedBytes = advancedBytes.advanced(by: mimeTypeLength)

        let descriptionLength = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        guard advancedBytes.count >= descriptionLength +
                                     FLACPictureMetadataBlock.widthSize +
                                     FLACPictureMetadataBlock.heightSize +
                                     FLACPictureMetadataBlock.colorDepthSize +
                                     FLACPictureMetadataBlock.colorUsedSize +
                                     FLACPictureMetadataBlock.lengthSize
        else {
            throw FLACParser.ParseError.unexpectedEndError(
                "Cannot parse picture metadata block, encountered missing description data!"
            )
        }

        if descriptionLength > 0 {
            description = String(bytes: advancedBytes[0..<descriptionLength], encoding: .utf8)
            advancedBytes = advancedBytes.advanced(by: Int(descriptionLength))
        } else {
            description = nil
        }

        let width = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        let height = Int(advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        })
        advancedBytes = advancedBytes.advanced(by: 4)

        size = CGSize(width: Double(width), height: Double(height))

        colorDepth = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        colorUsed = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        length = advancedBytes[0..<4].withUnsafeBytes {
            $0.load(as: UInt32.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 4)

        guard advancedBytes.count == length else {
            throw FLACParser.ParseError.unexpectedEndError(
                "Cannot parse picture metadata block, encountered missing picture data!"
            )
        }

        data = advancedBytes[0..<length]
    }
}
