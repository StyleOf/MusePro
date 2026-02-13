//
//  CanvasElement.swift
//  Muse Pro
//
//  Created by Omer Karisman on 26.02.24.
//

import Metal

protocol CanvasElement: Codable {
    
    var index: Int { get set }
    var id: UUID { get set }
    
    var center: CGPoint { get set }
    var size: CGSize { get set }
    var rotation: CGFloat { get set }
    
    func retrieveBuffers(scaleFactor: CGFloat) -> MTLBuffer?
    func drawSelf(with canvas: MTKCanvas, on texture: MTLTexture?, subtractive: Bool, transparent: Bool)
    func isEqual(to other: CanvasElement) -> Bool
}

