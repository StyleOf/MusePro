import Foundation
import Metal
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// a line strip with lines and brush info
class LineStrip: CanvasElement {
    
    var id: UUID = UUID()
    var index: Int = 0

    var center: CGPoint = CGPoint(x: 0, y: 0)
    
    var size: CGSize = CGSize(width: 0, height: 0)
    
    var rotation: CGFloat = 0.0
    
    var textureOffset: CGSize = CGSize(width: 0, height: 0)
    
    func isEqual(to other: CanvasElement) -> Bool {
        return self.id == other.id
    }
        
    var brushName: String?
    
    var color: MLColor
    var opacity: CGFloat
    var brushSize: CGFloat
    
    var lines: [MLLine] = [MLLine]()
    
    weak var brush: Brush? {
        didSet {
            brushName = brush?.name
        }
    }
    
    var isEnd: Bool
    
    init(lines: [MLLine], brush: Brush, textureOffset: CGSize? = nil, isEnd: Bool = false) {
        self.lines = lines
        self.brush = brush
        self.brushName = brush.name
        self.color = brush.renderingColor
        self.opacity = brush.opacity
        self.brushSize = brush.pointSize
        self.textureOffset = textureOffset ?? CGSize(width: 0, height: 0)
        self.vertex_buffer = nil
        self.isEnd = isEnd
    }
    
    func append(lines: [MLLine]) {
        self.lines.append(contentsOf: lines)
        vertex_buffer = nil
    }
   
    var vertexCount: Int = 0
    
    var vertex_buffer: MTLBuffer?

    func filterEveryNthItem<T>(array: [T], n: Int) -> [T] {
        return array.enumerated().filter { index, _ in index % n == 0 }.map { $0.1 }
    }

    func retrieveBuffers(scaleFactor: CGFloat) -> MTLBuffer? {

        if vertex_buffer != nil {
            return vertex_buffer!
        }
                
        guard lines.count > 0 else {
            return nil
        }
        
        guard let brush = brush else { return nil }
        
        var vertices: [Point] = [Point]()
        
        let scale = scaleFactor

        let shapeRotation: CGFloat = brush.shapeRotation
        let shapeScatter: CGFloat = brush.shapeScatter
        
        var previousLine = brush.lastRenderedLine

        lines.forEach { (line) in
            var line = line

            line.begin = line.begin * scale
            line.end = line.end * scale
            
            let leftOverLength = brush.leftOverLength
            let length = line.length
            let pointStep = ( 1 + line.pointSize * brush.plotSpacing) * scaleFactor
            var phaseShift = pointStep - leftOverLength

            if leftOverLength == 0 {
                phaseShift = 0
            }
//            
//            if length == 0 {
//                length = pointStep
//            }
            
//            let renderLength = length - phaseShift
            let count: CGFloat = (length / pointStep)

            if length < phaseShift {
                brush.leftOverLength = leftOverLength + length
                return
            }
            
            var newLeftOverLength = length - phaseShift - ceil(count) * pointStep
            newLeftOverLength = newLeftOverLength > 0 ? newLeftOverLength : pointStep + newLeftOverLength

            var renderingColor = line.color ?? color
         
            
            let previousAngle: CGFloat? = previousLine?.angle
            let previousSize: CGFloat? = previousLine?.pointSize
            let previousOpacity: CGFloat? = previousLine?.opacity
            let previousFlow: CGFloat? = previousLine?.flow

            let startAngle = previousAngle ?? line.angle
            let startSize = previousSize ?? line.pointSize
            let startOpacity = previousOpacity ?? line.opacity
            let startFlow = previousFlow ?? line.flow
            
            let jitter = brush.jitter * line.pointSize

            let xOffset: CGFloat
            let yOffset: CGFloat

            xOffset = cos(line.angle) * phaseShift
            yOffset = sin(line.angle) * phaseShift
            
      
            for i in 0 ..< Int(ceil(count)) {
                let index = CGFloat(i)
                
                var x = line.begin.x + xOffset + index * (cos(line.angle) * pointStep)
                var y = line.begin.y - yOffset - index * (sin(line.angle) * pointStep)
                
                if jitter > 0 {
                    x += CGFloat.random(in: -jitter...jitter)
                    y += CGFloat.random(in: -jitter...jitter)
                }

                let progress: CGFloat = (CGFloat(i) + 1.0) / (CGFloat(Int(floor(count))) + 1.0)
                
                var size = line.pointSize
                
                let sizeDiff = size - startSize
                let sizeStep = sizeDiff * progress
                
                size = startSize + sizeStep
                
                var angle: CGFloat = line.angle

                let angleDiff = angle - startAngle
                let angleStep = angleDiff * progress
                
                angle = startAngle + angleStep
                
                var opacity = line.opacity
                
                let opacityDiff = opacity - startOpacity
                let opacityStep = opacityDiff * progress
                
                opacity = startOpacity + opacityStep
                
                var flow = line.flow
                
                let flowDiff = flow - startFlow
                let flowStep = flowDiff * progress
                
                flow = startFlow + flowStep
                
                renderingColor.alpha = Float(min(max(brush.minOpacity, opacity), brush.maxOpacity) * flow)

                if shapeScatter > 0 {
                    let maxScatter = CGFloat.pi * shapeScatter
                    let randomScatter = CGFloat.random(in: -maxScatter...maxScatter)
                    angle += randomScatter
                }
                
                angle = angle * shapeRotation
                
                let point = Point(x: x, y: y, color: renderingColor, size: size, angle: angle)

                vertices.append(point)

            }
            brush.leftOverLength = newLeftOverLength
            previousLine = line
        }
        brush.lastRenderedLine = previousLine
      
        
//        for (index, _) in vertices.enumerated() {
//            let progress = Float(index) / Float(vertices.count - 1) // Correct proportion
//
//            // FallOff adjustment: Alpha starts at zero and increases linearly
//            if brush.fallOff > 0 {
//                let falloffEffect = (1 - progress) * (1 - Float(brush.fallOff))
//                vertices[index]._color.alpha *= falloffEffect
//            }
//
//            // Taper at the start
//            if brush.taperStartLength > 0 {
//                let taperStartRegion = 0.2 * Float(brush.taperStartLength)
//                if progress <= taperStartRegion {
//                    let amount = (progress / taperStartRegion)
//                    vertices[index]._color.alpha *= amount * (1 - Float(brush.taperOpacity)) + Float(brush.taperOpacity)
//                    vertices[index].size *= amount * (1 - Float(brush.taperSize)) + Float(brush.taperSize)
//                }
//            }
//           // Taper at the end
//            if brush.taperEndLength > 0 {
//                let taperEndRegion = 1 - (0.2 * Float(brush.taperEndLength))
//                if progress >= taperEndRegion {
//                    let amount = (1 - progress ) / (1 - taperEndRegion)
//                    vertices[index]._color.alpha *= amount * (1 - Float(brush.taperOpacity)) + Float(brush.taperOpacity)
//                    vertices[index].size *= amount * (1 - Float(brush.taperSize)) + Float(brush.taperSize)
//                }
//            }
//        }
//
//        let spacing = Int(brush.spacing)
//        if spacing > 0 {
//            vertices = filterEveryNthItem(array: vertices, n: spacing)
//        }
 
        vertexCount = vertices.count
        if vertexCount > 0 {
            vertex_buffer = sharedDevice?.makeBuffer(bytes: vertices, length: MemoryLayout<Point>.stride * vertexCount, options: .cpuCacheModeWriteCombined)
        }
        return vertex_buffer
    }
    
    var size_buffer: MTLBuffer?
    
    func retrieveSizeBuffer() -> MTLBuffer? {
        //TODO: Update when brush size changes
        if let brush = brush {
            var sizes = Sizes(brushSize: CGSize(width: brushSize, height: brushSize), textureSize: CGSize(width: brush.grainTexture?.width ?? 256, height: brush.grainTexture?.height ?? 256), textureScale: Float(brush.textureScale), textureOffset: textureOffset , color: color)
            size_buffer = sharedDevice?.makeBuffer(bytes: &sizes, length: MemoryLayout<Sizes>.size, options: [])
        }
        return size_buffer
    }
    
//    func drawSelf(with canvas: Canvas, on texture: MTLTexture?, subtractive: Bool = false, transparent: Bool = false) {
//        drawSelf(with: canvas, on: texture, subtractive: subtractive, transparent: transparent, clear: false, temp: false)
//    }
    
    func drawSelf(with canvas: MTKCanvas, on texture: MTLTexture?, subtractive: Bool = false, transparent: Bool = false) {
        if let selectionBrush = brush as? Selection {
            drawSelfSelection(with: canvas, on: texture)
            return
        }
        
        guard let renderer = canvas.canvasManager?.renderer else { return }
        guard let texture else { return }
        guard lines.count > 0, let brush = brush else {
            return
        }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = renderer.offscreenTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        if let commandEncoder = renderer.makeCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.setRenderPipelineState(brush.pipelineState)
            commandEncoder.label = "Line Strip Stroke Draw Call"

            if let vertex_buffer = retrieveBuffers(scaleFactor: canvas.contentScaleFactor) {
                commandEncoder.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
                commandEncoder.setVertexBuffer(renderer.getNextUniformBuffer(), offset: 0, index: 1)
                commandEncoder.setVertexBuffer(renderer.getNextTransformBuffer(), offset: 0, index: 2)
                commandEncoder.setFragmentTexture(brush.texture, index: 0)
                commandEncoder.setFragmentSamplerState(brush.getBrushSamplerState(), index: 0)
                commandEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: self.vertexCount)
            }
            
            commandEncoder.endEncoding()
            renderer.commitCommands()
        }
        
        let renderSecondPassDescriptor = MTLRenderPassDescriptor()
        renderSecondPassDescriptor.colorAttachments[0].texture = texture
        renderSecondPassDescriptor.colorAttachments[0].loadAction = .load
        renderSecondPassDescriptor.colorAttachments[0].storeAction = .store
        renderSecondPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        if let commandEncoder = renderer.makeCommandEncoder(descriptor: renderSecondPassDescriptor) {
            commandEncoder.label = "Line Strip Grain Draw Call"
            if !transparent {
                commandEncoder.setRenderPipelineState(brush.revealPipelineState)
            } else {
                commandEncoder.setRenderPipelineState(brush.revealPipelineStateTransparent)
            }
            
            if let size_buffer = retrieveSizeBuffer() {
                commandEncoder.setVertexBuffer(size_buffer, offset: 0, index: 0)
                commandEncoder.setFragmentBuffer(size_buffer, offset: 0, index: 0)
                commandEncoder.setFragmentTexture(brush.grainTexture, index: 0)
                commandEncoder.setFragmentTexture(renderer.offscreenTexture, index: 1)
                commandEncoder.setFragmentSamplerState(brush.getGrainSamplerState(), index: 0)
                commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            }
            
            commandEncoder.endEncoding()
        }
    }
    
    func drawSelfSelection(with canvas: MTKCanvas, on texture: MTLTexture?) {
        print("draw selection")
        guard let renderer = canvas.canvasManager?.renderer else { return }
        guard let texture else { return }
        guard lines.count > 0, let brush = brush else {
            return
        }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        if let commandEncoder = renderer.makeCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.setRenderPipelineState(brush.pipelineState)
            commandEncoder.label = "Line Strip Selection Draw Call"

            if let vertex_buffer = retrieveBuffers(scaleFactor: canvas.contentScaleFactor) {
                commandEncoder.setVertexBuffer(vertex_buffer, offset: 0, index: 0)
                commandEncoder.setVertexBuffer(renderer.getNextUniformBuffer(), offset: 0, index: 1)
                commandEncoder.setVertexBuffer(renderer.getNextTransformBuffer(), offset: 0, index: 2)
                commandEncoder.setFragmentBuffer(renderer.getTimeBuffer(), offset: 0, index: 0)
                commandEncoder.setFragmentSamplerState(brush.getBrushSamplerState(), index: 0)
                commandEncoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: self.vertexCount)
            }
            
            commandEncoder.endEncoding()
        }
    }

    // MARK: - Coding

    enum CodingKeys: String, CodingKey {
        case index
        case brush
        case lines
        case color
        case opacity
        case brushSize
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        brushName = try container.decode(String.self, forKey: .brush)
        lines = try container.decode([MLLine].self, forKey: .lines)
        color = try container.decode(MLColor.self, forKey: .color)
        opacity = try container.decode(CGFloat.self, forKey: .opacity)
        brushSize = try container.decode(CGFloat.self, forKey: .brushSize)
        isEnd = false //TODO: decode
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(brushName, forKey: .brush)
        try container.encode(lines, forKey: .lines)
        try container.encode(color, forKey: .color)
        try container.encode(opacity, forKey: .opacity)
        try container.encode(brushSize, forKey: .brushSize)
//        isEnd = false //TODO: encode

    }
}
