import Foundation
import MetalKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct Pan {
    
    var point: CGPoint
    var force: CGFloat
    
    init(touch: UITouch, on view: UIView) {
        if #available(iOS 9.1, *) {
            point = touch.preciseLocation(in: view)
        } else {
            point = touch.location(in: view)
        }
        //        point = CGPoint(x: round(point.x), y: round(point.y))
        force = touch.force
        
        // force on devices not supporting from a finger is always 0, reset to 0.3
        if touch.type == .direct, force == 0 {
            force = 4
        }
    }
    
    init(point: CGPoint, force: CGFloat) {
        self.point = point
        //        point = CGPoint(x: round(point.x), y: round(point.y))
        self.force = force
    }
}

class Brush {
    
    var name: String
    
    var textureID: String?
    
    weak var target: MTKCanvas?
    
    var opacity: CGFloat = 0.3 {
        didSet {
            updateRenderingColor()
        }
    }
        
    var minOpacity: CGFloat = 0.01
    var maxOpacity: CGFloat = 1
    
    var pointSize: CGFloat = 0.5
    var textureSize: CGFloat = 1024 //TODO: Get it from brush texture
    var minPointSize: CGFloat = 0.01
    var maxPointSize: CGFloat = 1
    var preview: Data?
    
    var eraseSize: CGFloat = 0.5
    var eraseOpacity: CGFloat = 0.5
    
    
    var plotSpacing: CGFloat = 1
    var jitter: CGFloat = 0
    var fallOff: CGFloat = 0
    
    var pressureSize: CGFloat = 1
    var pressureOpacity: CGFloat = 1
    var pressureFlow: CGFloat = 1
    var pressureBleed: CGFloat = 1
    
    var grainDepth: CGFloat = 1
    var grainOrientation: Int = 1
    var grainBlendMode: Int = 1
    var grainDepthJitter: CGFloat = 1
    var gradationTiltAngle: CGFloat = 1
    
    var texturizedGrainFollowsCamera: Bool = false
    var textureMovement: CGFloat = 1
    var textureRotation: CGFloat = 1
    var textureZoom: CGFloat = 1
    var textureScale: CGFloat = 1
    var textureFilter: Bool = false
    var textureFilterMode: CGFloat = 1
    var textureContrast: CGFloat = 0
    var textureBrightness: CGFloat = 0
    var textureApplication: Int = 0
    var textureInverted: Bool = false
    var textureOrientation: CGFloat = 1
    var textureDepthTilt: Bool = false
    var textureDepthTiltAngle: CGFloat = 1
    var textureOffsetJitter: Bool = false
    
    
    var taperEndLength: CGFloat = 0.27
    var taperOpacity: CGFloat = 1
    var taperSize: CGFloat = 0.0
    var taperStartLength: CGFloat = 0.18
    
    var forceSensitive: CGFloat = 1
    
    var scaleWithCanvas = false
    
    var forceOnTap: CGFloat = 1
    
    var color: UIColor = .black {
        didSet {
            updateRenderingColor()
        }
    }
    
    enum Rotation {
        case fixed(CGFloat)
        case random(CGFloat)
        case ahead
    }
    
    var rotation = Rotation.fixed(0)
    var shapeScatter: CGFloat = 0
    var shapeRotation: CGFloat = 0
    
    var renderingColor: MLColor = MLColor(red: 0, green: 0, blue: 0, alpha: 1)
    
    func updateRenderingColor() {
        renderingColor = color.toMLColor(opacity: opacity)
    }
    
    required init(name: String?, textureID: String?, grainTextureID: String?, target: MTKCanvas) {
        self.name = name ?? UUID().uuidString
        self.target = target
        self.textureID = textureID
        if let id = textureID {
            texture = target.findTexture(by: id)?.texture
        }
        
        if let id = grainTextureID {
            grainTexture = target.findTexture(by: id)?.texture
        } else {
            grainTexture = try! target.makeTexture(with: .white)
        }
        
        self.preview = texture?.toData(context: target.canvasManager?.renderer?.context)
        
        updatePointPipeline()
    }
    
    func use() {
        target?.currentBrush = self
    }
    
    func makeLine(from: Pan, to: Pan) -> [MLLine] {
        let endForce = from.force * 0.95 + to.force * 0.05
        let forceRate = pow(endForce, forceSensitive)
        return makeLine(from: from.point, to: to.point, force: forceRate)
    }
    
    func makeLine(from: CGPoint, to: CGPoint, force: CGFloat? = nil, uniqueColor: Bool = false) -> [MLLine] {
        let force = (force != nil) ? force! / 4 : forceOnTap
        var size = pointSize
        var opacity = self.opacity
        var flow = 1.0
        
        if pressureSize > 0 {
            size = pointSize * force * pressureSize
        } else if pressureSize < 0 {
            size = pointSize / (force * abs(pressureSize))
        }
        
        if pressureOpacity > 0 {
            opacity = self.opacity * force * pressureOpacity
        } else if pressureOpacity < 0 {
            opacity = self.opacity / (force * abs(pressureOpacity))
        }
        
        if pressureFlow > 0 {
            flow = 1.0 * force * pressureFlow
        } else if pressureFlow < 0 {
            flow = 1.0 / (force * abs(pressureFlow))
        }
        
        size = min(size, maxPointSize)
        size = max(minPointSize, size)
        size = size * textureSize
        let line = MLLine(begin: from,
                          end: to,
                          pointSize: size,
                          color: uniqueColor ? renderingColor : nil,
                          opacity: opacity,
                          flow: flow)
        return [line]
    }
    
    func finishLineStrip(at end: Pan) -> [MLLine] {
        return []
    }
    
    // MARK: - Render tools
    weak var texture: MTLTexture?
    weak var grainTexture: MTLTexture?
    
    var pipelineState: MTLRenderPipelineState!
    var revealPipelineState: MTLRenderPipelineState!
    var revealPipelineStateTransparent: MTLRenderPipelineState!
    
    func makeShaderLibrary(from device: MTLDevice) -> MTLLibrary? {
        return device.library()
    }
    
    func makeShaderVertexFunction(from library: MTLLibrary) -> MTLFunction? {
        return library.makeFunction(name: "brush_vertex")
    }
    
    func makeShaderFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
        if texture == nil {
            return library.makeFunction(name: "brush_fragment_without_texture")
        }
        return library.makeFunction(name: "brush_fragment")
    }
    
    func makeRevealShaderVertexFunction(from library: MTLLibrary) -> MTLFunction? {
        return library.makeFunction(name: "grain_vertex")
    }
    
    func makeRevealShaderFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
        if texture == nil {
            return library.makeFunction(name: "grain_fragment_without_texture")
        }
        return library.makeFunction(name: "grain_fragment")
    }
    
    func setupBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        
        attachment.sourceRGBBlendFactor = .one
        attachment.sourceAlphaBlendFactor = .one
        
        attachment.destinationRGBBlendFactor = .one
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    func setupRevealBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        
        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.sourceAlphaBlendFactor = .one
        
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    func setupRevealTransparentBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        
        attachment.sourceRGBBlendFactor = .one
        attachment.sourceAlphaBlendFactor = .one
        
        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    // MARK: - Render Actions
    
    func updatePointPipeline() {
        
        guard let target = target, let device = sharedDevice, let library = makeShaderLibrary(from: device) else {
            return
        }
        
        let rpd = MTLRenderPipelineDescriptor()
        
        if let vertex_func = makeShaderVertexFunction(from: library) {
            rpd.vertexFunction = vertex_func
        }
        if let fragment_func = makeShaderFragmentFunction(from: library) {
            rpd.fragmentFunction = fragment_func
        }
        
        rpd.colorAttachments[0].pixelFormat = target.colorPixelFormat
        
        setupBlendOptions(for: rpd.colorAttachments[0]!)
        pipelineState = try! device.makeRenderPipelineState(descriptor: rpd)
        
        let reveal_rpd = MTLRenderPipelineDescriptor()
        
        if let vertex_func = makeRevealShaderVertexFunction(from: library) {
            reveal_rpd.vertexFunction = vertex_func
        }
        
        if let fragment_func = makeRevealShaderFragmentFunction(from: library) {
            reveal_rpd.fragmentFunction = fragment_func
        }
        
        reveal_rpd.colorAttachments[0].pixelFormat = target.colorPixelFormat
        
        setupRevealBlendOptions(for: reveal_rpd.colorAttachments[0]!)
        revealPipelineState = try! device.makeRenderPipelineState(descriptor: reveal_rpd)
        
        let reveal_temp_rpd = MTLRenderPipelineDescriptor()
        
        if let vertex_func = makeRevealShaderVertexFunction(from: library) {
            reveal_temp_rpd.vertexFunction = vertex_func
        }
        
        if let fragment_func = makeRevealShaderFragmentFunction(from: library) {
            reveal_temp_rpd.fragmentFunction = fragment_func
        }
        
        reveal_temp_rpd.colorAttachments[0].pixelFormat = target.colorPixelFormat
        
        setupRevealTransparentBlendOptions(for: reveal_temp_rpd.colorAttachments[0]!)
        revealPipelineStateTransparent = try! device.makeRenderPipelineState(descriptor: reveal_temp_rpd)
    }
    
    // MARK: - Bezier
    // optimize stroke with bezier path, defaults to true
    //    var enableBezierPath = true
    var bezierGenerator = BezierGenerator()
    
    // MARK: - Drawing Actions
    var lastRenderedPan: Pan?
    var lastRenderedLine: MLLine?
    var leftOverLength: CGFloat = 0
    
    func pushPoint(_ point: CGPoint, to bezier: BezierGenerator, force: CGFloat, isEnd: Bool = false, on canvas: MTKCanvas) {
        var lines: [MLLine] = [MLLine]()

        let vertices = bezier.pushPoint(point)
        guard vertices.count >= 2 else {
            return
        }
        var lastPan = lastRenderedPan ?? Pan(point: vertices[0], force: force)
        let deltaForce = (force - (lastRenderedPan?.force ?? force)) / CGFloat(vertices.count)
        let pointStep = 1 + (pointSize * textureSize * plotSpacing)
        for i in 1 ..< vertices.count {
            let p = vertices[i]
            if
                (isEnd && i == vertices.count - 1) ||
                    lastPan.point.distance(to: point) >= pointStep
            {
                let force = lastPan.force + deltaForce
                let pan = Pan(point: p, force: force)
                //                let pan = Pan(point: CGPoint(x: p.x, y: p.y), force: force)
                
                let line = makeLine(from: lastPan, to: pan)
                lines.append(contentsOf: line)
                lastPan = pan
                lastRenderedPan = pan
            }
        }
        render(lines: lines, on: canvas, isEnd: isEnd)
    }
    
    
    var brushSamplerState: MTLSamplerState?
    
    func getBrushSamplerState() -> MTLSamplerState? {
        if brushSamplerState == nil {
            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            brushSamplerState = sharedDevice?.makeSamplerState(descriptor: samplerDescriptor)
        }
        return brushSamplerState
    }
    
    var grainSamplerState: MTLSamplerState?
    
    func getGrainSamplerState() -> MTLSamplerState? {
        if grainSamplerState == nil {
            let samplerDescriptor = MTLSamplerDescriptor()
            samplerDescriptor.minFilter = .linear
            samplerDescriptor.magFilter = .linear
            samplerDescriptor.sAddressMode = .repeat
            samplerDescriptor.tAddressMode = .repeat
            grainSamplerState = sharedDevice?.makeSamplerState(descriptor: samplerDescriptor)
        }
        return grainSamplerState
    }
    
    func render(lines: [MLLine], on canvas: MTKCanvas, isEnd: Bool = false) {
        canvas.render(brush: self, lines: lines, isEnd: isEnd)
    }
    
    // MARK: - Touches
    
    func renderBegan(from pan: Pan, on canvas: MTKCanvas) -> Bool {
        lastRenderedPan = pan
        bezierGenerator.begin(with: pan.point)
        pushPoint(pan.point, to: bezierGenerator, force: pan.force, on: canvas)
        return true
    }
    
    func renderMoved(to pan: Pan, on canvas: MTKCanvas) -> Bool {
        guard bezierGenerator.points.count > 0 else { return false }
        guard pan.point != lastRenderedPan?.point else { return false }
        pushPoint(pan.point, to: bezierGenerator, force: pan.force, on: canvas)
        return true
    }
    
    func renderEnded(at pan: Pan, on canvas: MTKCanvas) {
        defer {
            bezierGenerator.finish()
            lastRenderedPan = nil
            lastRenderedLine = nil
            leftOverLength = 0
        }
        
        let count = bezierGenerator.points.count
        if count >= 3 {
            pushPoint(pan.point, to: bezierGenerator, force: pan.force, isEnd: true, on: canvas)
        } else if count > 0 {
            canvas.renderTap(brush: self, at: bezierGenerator.points.first!, to: CGPoint(x: bezierGenerator.points.first!.x + pointSize * textureSize * plotSpacing, y: bezierGenerator.points.first!.y))
        }
        
        //        let unfinishedLines = finishLineStrip(at: Pan(point: pan.point, force: pan.force))
        //        if unfinishedLines.count > 0 {
        //            print("Found Unfinished Lines", unfinishedLines.count)
        //            canvas.render(lines: unfinishedLines)
        //        }
    }
}
