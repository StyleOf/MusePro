//
//  Rectangle.swift
//  MusePro
//
//  Created by Omer Karisman on 17.01.24.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Metal

class MLShape: CanvasElement {
    var id: UUID = UUID()
    
    var index: Int
    
    func isEqual(to other: CanvasElement) -> Bool {
        return self.id == other.id
    }
    
    var color: MLColor {
        didSet {
            color_buffer = createColorBuffer()
        }
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
    
    var vertex_buffer: MTLBuffer?
    var color_buffer: MTLBuffer?

    var printer: Printer?

    init(color: MLColor) {
        self.color = color
        self.index = 0 //TODO: FIX
        self.color_buffer = createColorBuffer()
    }

    func retrieveBuffers(scaleFactor: CGFloat) -> MTLBuffer? {
        fatalError("This method should be overridden")
    }
    
    func createColorBuffer() -> MTLBuffer? {
        var color = FragmentColor(color: color)
        return sharedDevice?.makeBuffer(bytes: &color, length: MemoryLayout<FragmentColor>.size, options: [])
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
           let color_buffer = color_buffer,
           let commandEncoder = renderer.makeCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.label = "Shape Draw Call"

            let vertex_count = vertex_buffer.length / 32
            
            if subtractive {
                commandEncoder.setRenderPipelineState(printer.subtractivePipelineState)
            } else if transparent {
                commandEncoder.setRenderPipelineState(printer.transparentPipelineState)
            } else {
                commandEncoder.setRenderPipelineState(printer.pipelineState)
            }
            
            commandEncoder.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
            commandEncoder.setVertexBuffer(renderer.getNextUniformBuffer(), offset: 0, index: 1)
            commandEncoder.setVertexBuffer(renderer.getNextTransformBuffer(), offset: 0, index: 2)
            commandEncoder.setFragmentBuffer(color_buffer, offset: 0, index: 0)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertex_count)
            
            commandEncoder.endEncoding()
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case index
        case color
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        color = try container.decode(MLColor.self, forKey: .color)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(color, forKey: .color)
    }
}

class MLRectangle: MLShape {
    override func retrieveBuffers(scaleFactor: CGFloat) -> MTLBuffer? {
        if vertex_buffer == nil {
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
            
        }
        
        return vertex_buffer
    }
}

// Triangle subclass
class MLTriangle: MLShape {
    override func retrieveBuffers(scaleFactor: CGFloat) -> MTLBuffer? {
        
        if vertex_buffer == nil {
            
            let center = self.center * scaleFactor
            let halfSize = self.size * 0.5 * scaleFactor
            
            let vertices = [
                Vertex(position: CGPoint(x: center.x, y: center.y - halfSize.height).rotatedBy(self.rotation, anchor: center),
                       textCoord: CGPoint(x: 0.5, y: 0)), // Top vertex
                Vertex(position: CGPoint(x: center.x - halfSize.width, y: center.y + halfSize.height).rotatedBy(self.rotation, anchor: center),
                       textCoord: CGPoint(x: 0, y: 1)), // Bottom left vertex
                Vertex(position: CGPoint(x: center.x + halfSize.width, y: center.y + halfSize.height).rotatedBy(self.rotation, anchor: center),
                       textCoord: CGPoint(x: 1, y: 1)), // Bottom right vertex
            ]
            
            vertex_buffer = sharedDevice?.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * 3, options: .cpuCacheModeWriteCombined) ?? nil
            
        }
        return vertex_buffer
    }
}

// Circle subclass
class MLCircle: MLShape {
    override func retrieveBuffers(scaleFactor: CGFloat) -> MTLBuffer? {
        
        if vertex_buffer == nil {
            
            let center = self.center * scaleFactor
            let radiusX = self.size.width * 0.5 * scaleFactor
            let radiusY = self.size.height * 0.5 * scaleFactor
            
            let numberOfSegments = 720 // 360 degrees * 2 for smoothness
            let angleIncrement = CGFloat(2 * Double.pi) / CGFloat(numberOfSegments)
            
            var vertices = [Vertex]()
            
            for i in 0...numberOfSegments {
                let segmentAngle = CGFloat(i) / 2.0 * angleIncrement * 2
                let x = center.x + radiusX * cos(segmentAngle)
                let y = center.y + radiusY * sin(segmentAngle)
                vertices.append(Vertex(position: CGPoint(x: x, y: y).rotatedBy(self.rotation, anchor: center),
                                       textCoord: CGPoint(x: cos(segmentAngle), y: sin(segmentAngle))))
                
                if (i + 1) % 2 == 0 {
                    // Add the center point every alternate iteration
                    vertices.append(Vertex(position: CGPoint(x: center.x, y: center.y).rotatedBy(self.rotation, anchor: center),
                                           textCoord: CGPoint(x: 0.5, y: 0.5))) // Assuming center corresponds to (0.5, 0.5) in texture coordinates
                }
            }
            
            vertex_buffer = sharedDevice?.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: .cpuCacheModeWriteCombined) ?? nil
        }
        return vertex_buffer
    }
}
