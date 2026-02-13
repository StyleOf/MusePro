import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Metal

/// not implemented yet
class Chartlet: CanvasElement {
    var id: UUID = UUID()
    
    func isEqual(to other: CanvasElement) -> Bool {
        return self.id == other.id
    }
    
    var index: Int = 0
    
    var center: CGPoint = CGPoint(x: 0, y: 0)
    var size: CGSize = CGSize(width: 0, height: 0)
    var rotation: CGFloat = 0.0
    
    var textureID: String
    
    var subtractive: Bool = false
    
    var smartObject: Bool = false
     
    init(textureID: String) {
        self.textureID = textureID
    }
    
    weak var printer: Printer?
    
    var vertex_buffer: MTLBuffer?
    
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
        guard let printer = printer else { return }
        guard let renderer = canvas.canvasManager?.renderer else { return }
        guard let texture else { return }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        
        if let vertex_buffer = self.retrieveBuffers(scaleFactor: canvas.contentScaleFactor),
           let texture = canvas.findTexture(by: self.textureID)?.texture,
           let commandEncoder = renderer.makeCommandEncoder(descriptor: renderPassDescriptor)
        {
            commandEncoder.label = "Chartlet Draw Call"
            if subtractive || self.subtractive{
                commandEncoder.setRenderPipelineState(printer.subtractivePipelineState)
            } else if transparent {
                commandEncoder.setRenderPipelineState(printer.transparentPipelineState)
            } else {
                commandEncoder.setRenderPipelineState(printer.pipelineState)
            }
            commandEncoder.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
            commandEncoder.setVertexBuffer(renderer.getNextUniformBuffer(), offset: 0, index: 1)
            commandEncoder.setVertexBuffer(renderer.getNextTransformBuffer(), offset: 0, index: 2)
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            commandEncoder.endEncoding()
        }
    }
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case index
        case texture
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        textureID = try container.decode(String.self, forKey: .texture)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(textureID, forKey: .texture)
    }
}
