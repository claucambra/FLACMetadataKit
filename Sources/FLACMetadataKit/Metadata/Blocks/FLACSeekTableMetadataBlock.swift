//
//  FLACSeekTableMetadataBlock.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

public struct FLACSeekTableMetadataBlock {
    public struct SeekPoint: Hashable {
        public static let size = 8 + 8 + 2
        public let sampleNumber: UInt64
        public let streamOffset: UInt64
        public let frameSamples: UInt16

        init(bytes: Data) {
            sampleNumber = bytes[0..<8].withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
            streamOffset = bytes[8..<16].withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
            frameSamples = bytes[16..<18].withUnsafeBytes { $0.load(as: UInt16.self).bigEndian }
        }
    }

    public let header: FLACMetadataBlockHeader
    public let points: [SeekPoint]

    init(bytes: Data, header: FLACMetadataBlockHeader) {
        self.header = header

        var advancedBytes = bytes.advanced(by: 0)
        let pointCount = Int(header.metadataBlockDataSize) / SeekPoint.size
        var pointTable: [SeekPoint] = []
        for _ in 0..<pointCount {
            let point = SeekPoint(bytes: bytes[0..<SeekPoint.size])
            advancedBytes = advancedBytes.advanced(by: SeekPoint.size)
            pointTable.append(point)
        }
        points = pointTable
    }
}
