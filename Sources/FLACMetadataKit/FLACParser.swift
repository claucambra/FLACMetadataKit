//
//  FLACParser.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

public class FLACParser {
    public enum ParseError: Error {
        case dataNotFlac(String)
        case unexpectedEndError(String)
    }

    public let data: Data
    public var isFLAC: Bool {
        String(data: data[0..<4], encoding: .ascii) == FLACMetadata.streamMarker
    }

    public init(data: Data) {
        self.data = data
    }

    public func parse() throws -> FLACMetadata {
        guard isFLAC else { throw ParseError.dataNotFlac("Cannot parse data, is not a FLAC!") }
        
        var currentData = data.advanced(by: 4)
        var streamInfo: FLACStreamInfoMetadataBlock?
        var vorbisComments: FLACVorbisCommentsMetadataBlock?
        var picture: FLACPictureMetadataBlock?
        var application: FLACApplicationMetadataBlock?
        var seekTable: FLACSeekTableMetadataBlock?
        var cueSheet: FLACCueSheetMetadataBlock?
        var paddings: [FLACPaddingMetadataBlock] = []

        while currentData.count >= FLACMetadataBlockHeader.size {
            let headerBytes = currentData[0..<FLACMetadataBlockHeader.size]
            let header = try FLACMetadataBlockHeader(bytes: headerBytes)
            let blockEnd = FLACMetadataBlockHeader.size + Int(header.metadataBlockDataSize)

            guard currentData.count > blockEnd else {
                let errorString = "Currently parsed metadata block ends beyond the available data!"
                throw ParseError.unexpectedEndError(errorString)
            }
            
            currentData = currentData.advanced(by: FLACMetadataBlockHeader.size)
            let blockBytes = currentData[0..<header.metadataBlockDataSize]

            switch header.metadataBlockType {
            case .streamInfo:
                streamInfo = try FLACStreamInfoMetadataBlock(
                    bytes: blockBytes, header: header
                )
            case .padding:
                paddings.append(FLACPaddingMetadataBlock(header: header))
            case .application:
                application = try FLACApplicationMetadataBlock(
                    bytes: blockBytes, header: header
                )
            case .seekTable:
                seekTable = try FLACSeekTableMetadataBlock(bytes: blockBytes, header: header)
            case .vorbisComment:
                vorbisComments = try FLACVorbisCommentsMetadataBlock(
                    bytes: blockBytes, header: header
                )
            case .cueSheet:
                cueSheet = try FLACCueSheetMetadataBlock(bytes: blockBytes, header: header)
            case .picture:
                picture = try FLACPictureMetadataBlock(bytes: blockBytes, header: header)
            case .reserved, .invalid, .undefined:
                print("Nothing to do")
            }

            currentData = currentData.advanced(by: Int(header.metadataBlockDataSize))

            if header.isLastMetadataBlock {
                return FLACMetadata(
                    streamInfo: streamInfo!,
                    vorbisComments: vorbisComments,
                    picture: picture,
                    application: application,
                    seekTable: seekTable,
                    cueSheet: cueSheet
                )
            }
        }

        let errorString = "Currently parsed metadata block ends beyond the available data!"
        throw ParseError.unexpectedEndError(errorString)
    }
}

