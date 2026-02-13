//
//  CanvasLayer.swift
//  Muse Pro
//
//  Created by Omer Karisman on 26.02.24.
//

import Metal
import Foundation
import UniformTypeIdentifiers
import CoreTransferable
#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum BlendMode: Codable {
    case darken
    case overlay
    case lighten
    case normal
    case difference
    case linearBurn
    case multiply
    case screen
    case colorBurn
    case colorDodge
    case hardLight
    case hardMix
    case linearDodge
    case linearLight
    case dissolve
    case behind
    case add
    case subtract
}

class Layer: Equatable, Identifiable, Hashable, Transferable, Codable {
    
    var id: UUID
    var index: Int
    var blendMode: BlendMode = .add
    var opacity: Float = 1.0
    var elements: [CanvasElement] = []
    var snapshot: Data? = nil
    var drawable: MTLTexture?
    var temporaryDrawable: MTLTexture?
    
    var hidden: Bool = false
    var locked: Bool = false
    
    var snapshotImage: UIImage? {
        guard let snapshot else { return nil }
        return UIImage(data: snapshot)
    }
    
    init(index: Int) {
        self.id = UUID()
        self.index = index
    }
    
    init(index: Int, id: UUID) {
        self.id = id
        self.index = index
    }
    
    init(index: Int, id: UUID, blendMode: BlendMode? = .add, opacity: Float? = 1.0, hidden: Bool, snapshot: Data?, drawable: MTLTexture?) {
        self.id = id
        self.index = index
        self.blendMode = blendMode!
        self.opacity = opacity!
        self.hidden = hidden
        self.snapshot = snapshot
        self.drawable = drawable
    }
    
    static func == (lhs: Layer, rhs: Layer) -> Bool {
        return lhs.id == rhs.id
    }
    
    func isEqual(to other: Layer) -> Bool {
        return self.id == other.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .layer)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(index, forKey: .index)
        try container.encode(blendMode, forKey: .blendMode)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(snapshot, forKey: .snapshot)
        try container.encode(locked, forKey: .locked)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        index = try container.decode(Int.self, forKey: .index)
        blendMode = try container.decode(BlendMode.self, forKey: .blendMode)
        opacity = try container.decode(Float.self, forKey: .opacity)
        snapshot = try container.decodeIfPresent(Data.self, forKey: .snapshot)
        locked = try container.decode(Bool.self, forKey: .locked)
        drawable = nil // MTLTexture cannot be decoded; consider other strategies for restoring this state.
        temporaryDrawable = nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id, index, blendMode, opacity, snapshot, locked
    }
}

extension UTType {
    static let layer: UTType = UTType(exportedAs: "com.musepro.app.layer")
}
