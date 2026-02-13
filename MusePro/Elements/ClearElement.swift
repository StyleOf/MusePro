//
//  ClearElement.swift
//  Muse Pro
//
//  Created by Omer Karisman on 26.02.24.
//

import Foundation
import Metal

class Clear: CanvasElement {
    var id: UUID = UUID()
    
    var index: Int
    
    func isEqual(to other: CanvasElement) -> Bool {
        return self.id == other.id
    }
    
    var center: CGPoint = CGPoint(x: 256, y: 256) {
        didSet {
            vertex_buffer = nil
        }
    }
    
    var size: CGSize = CGSize(width: 256, height: 256) {
        didSet {
            vertex_buffer = nil
        }
    }
    
    var rotation: CGFloat = 0.0 {
        didSet {
            vertex_buffer = nil
        }
    }
    
    var printer: Printer?
    var vertex_buffer: MTLBuffer?
    
    init() {
        self.index = 0 //TODO: FIX
    }
    
    func createColorBuffer() -> MTLBuffer? {
        var color = FragmentColor(color: .clear)
        return sharedDevice?.makeBuffer(bytes: &color, length: MemoryLayout<FragmentColor>.size, options: [])
    }
    
    func retrieveBuffers(scaleFactor: CGFloat) -> MTLBuffer? {
        
        if vertex_buffer != nil {
            return vertex_buffer!
        }
        
        let center = self.center * scaleFactor
        let halfSize = self.size * 0.5 * scaleFactor
        
        let vertices = [
            Vertex(position: CGPoint(x: center.x - halfSize.width, y: center.y - halfSize.height).rotatedBy(self.rotation, anchor: center),
                   textCoord: CGPoint(x: 0, y: 0)),
            Vertex(position: CGPoint(x: center.x + halfSize.width , y: center.y - halfSize.height).rotatedBy(self.rotation, anchor: center),
                   textCoord: CGPoint(x: 1, y: 0)),
            Vertex(position: CGPoint(x: center.x - halfSize.width , y: center.y + halfSize.height).rotatedBy(self.rotation, anchor: center),
                   textCoord: CGPoint(x: 0, y: 1)),
            Vertex(position: CGPoint(x: center.x + halfSize.width , y: center.y + halfSize.height).rotatedBy(self.rotation, anchor: center),
                   textCoord: CGPoint(x: 1, y: 1)),
        ]
        
        vertex_buffer = sharedDevice?.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * 4, options: .cpuCacheModeWriteCombined) ?? nil
        
        return vertex_buffer!
    }
    
    func drawSelf(with canvas: MTKCanvas, on texture: MTLTexture?, subtractive: Bool = false, transparent: Bool = false) {
        guard let renderer = canvas.canvasManager?.renderer else { return }
        guard let texture else { return }
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        if let commandEncoder = renderer.makeCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.label = "Clear Draw Call"
            commandEncoder.endEncoding()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case index
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
    }
}
