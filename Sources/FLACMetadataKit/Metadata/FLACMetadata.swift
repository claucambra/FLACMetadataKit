//
//  FLACMetadata.swift
//  HarmonyKit
//
//  Created by Claudio Cambra on 22/2/24.
//

import Foundation

public struct FLACMetadata {
    static var streamMarker = "fLaC"
    public let streamInfo: FLACStreamInfoMetadataBlock
    public let vorbisComments: FLACVorbisCommentsMetadataBlock?
    public let picture: FLACPictureMetadataBlock?
    public let application: FLACApplicationMetadataBlock?
    public let seekTable: FLACSeekTableMetadataBlock?
    public let cueSheet: FLACCueSheetMetadataBlock?
    public let paddings: [FLACPaddingMetadataBlock] = []
}
