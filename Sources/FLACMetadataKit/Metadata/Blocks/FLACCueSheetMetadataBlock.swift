//
//  FLACCueSheetMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

public struct FLACCueSheetMetadataBlock {
    public struct Track {
        public struct Index {
            public static let size = 8 + 1 + 3
            public let offset: UInt64
            public let number: UInt8
        }

        static let minSize = 8 + 1 + 12 + 14 + 1
        public let offset: UInt64
        public let number: UInt8
        public let isrc: String
        public let isAudio: Bool
        public let isPreEmphasis: Bool
        public let numberOfIndexPoints: UInt8
        public let indexPoints: [Index]
    }

    // Media catalog number + lead-in samples + isCD flag + reserved bits + number of tracks
    static let minSize = 128 + 8 + 1 + 258 + 1 + 1
    public let header: FLACMetadataBlockHeader
    public let mediaCatalogNumber: String
    public let leadInSamples: UInt64
    public let isCD: Bool
    public let tracks: [Track]

    init(bytes: Data, header: FLACMetadataBlockHeader) throws {
        guard bytes.count >= FLACCueSheetMetadataBlock.minSize else {
            throw FLACParser.ParseError.unexpectedEndError(
                "Cannot parse cuedata metadata block, unexpected data size!"
            )
        }
        self.header = header

        var advancedBytes = bytes.advanced(by: 0)
        mediaCatalogNumber = String(bytes: advancedBytes[0..<128], encoding: .ascii) ?? ""
        advancedBytes = advancedBytes.advanced(by: 128)

        leadInSamples = advancedBytes[0..<8].withUnsafeBytes {
            $0.load(as: UInt64.self).bigEndian
        }
        advancedBytes = advancedBytes.advanced(by: 8)

        isCD = (UInt32(advancedBytes[0]) & 0x80) != 0
        advancedBytes = advancedBytes.advanced(by: 1 + 258)  // Reserved bits, all 0

        let numberOfTracks = advancedBytes[0]
        advancedBytes = advancedBytes.advanced(by: 1)

        var processedTracks: [Track] = []
        for _ in 0..<numberOfTracks {
            guard advancedBytes.count >= Track.minSize else {
                throw FLACParser.ParseError.unexpectedEndError(
                    "Cannot parse cue data track data, unexpected end!"
                )
            }
            let trackOffsetInSamples = advancedBytes[0..<8].withUnsafeBytes {
                $0.load(as: UInt64.self).bigEndian
            }
            advancedBytes = advancedBytes.advanced(by: 8)

            let trackNumber = advancedBytes[0]
            advancedBytes = advancedBytes.advanced(by: 1)

            let isrc = String(data: advancedBytes[0 ..< 12], encoding: .ascii) ?? ""
            advancedBytes = advancedBytes.advanced(by: 12)

            let isAudio = UInt32(advancedBytes[0]) & 0x80 == 0
            let isPreEmphasis = UInt32(advancedBytes[0]) & 0x70 != 0
            // Skip the byte containing the 2 flag bits here + 6 reserved bytes, then 13 more...
            advancedBytes = advancedBytes.advanced(by: 1 + 13)  // ...reserved bits, all 0

            let numberOfIndexPoints = advancedBytes[0]
            advancedBytes = advancedBytes.advanced(by: 1)

            var indexPoints: [Track.Index] = []
            for _ in 0..<numberOfIndexPoints {
                guard advancedBytes.count == Track.Index.size else {
                    throw FLACParser.ParseError.unexpectedEndError(
                        "Cannot parse cue data track index point data, unexpected end!"
                    )
                }
                let indexPointData = advancedBytes[0..<Track.Index.size]
                advancedBytes = advancedBytes.advanced(by: Track.Index.size)

                let indexPointOffsetInSamples = indexPointData[0..<8].withUnsafeBytes {
                    $0.load(as: UInt64.self).bigEndian
                }
                let indexPointNumber = indexPointData[8]

                let index = Track.Index(offset: indexPointOffsetInSamples, number: indexPointNumber)
                indexPoints.append(index)
            }

            let track = Track(
                offset: trackOffsetInSamples,
                number: trackNumber,
                isrc: isrc,
                isAudio: isAudio,
                isPreEmphasis: isPreEmphasis,
                numberOfIndexPoints: numberOfIndexPoints,
                indexPoints: indexPoints
            )
            processedTracks.append(track)
        }
        tracks = processedTracks
    }
}
