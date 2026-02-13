import Foundation
import Metal

class Printer {

    weak var target: MTKCanvas?

    var pipelineState: MTLRenderPipelineState!
    var subtractivePipelineState: MTLRenderPipelineState!
    var transparentPipelineState: MTLRenderPipelineState!

    var isColor: Bool = false
    
    required init(target: MTKCanvas, isColor: Bool = false) {
        self.target = target
        self.isColor = isColor
        updatePointPipeline(isColor: isColor)
        updateSubtractivePointPipeline(isColor: isColor)
        updateTransparentPointPipeline(isColor: isColor)
    }
    
    func makeShaderLibrary(from device: MTLDevice) -> MTLLibrary? {
        return device.library()
    }
    
    func makeShaderVertexFunction(from library: MTLLibrary) -> MTLFunction? {
        return library.makeFunction(name: "printer_vertex")
    }

    func makeShaderFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
        return library.makeFunction(name: "printer_fragment")
    }
    
    func makeShaderColorFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
        return library.makeFunction(name: "color_printer_fragment")
    }
    
    func setupBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add

        attachment.sourceRGBBlendFactor = .sourceAlpha
        attachment.sourceAlphaBlendFactor = .one

        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    func setupSubtractiveBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .reverseSubtract
        attachment.alphaBlendOperation = .reverseSubtract

        attachment.sourceRGBBlendFactor = .zero
        attachment.sourceAlphaBlendFactor = .one

        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .one
    }
    
    func setupTransparentBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add

        attachment.sourceRGBBlendFactor = .one
        attachment.sourceAlphaBlendFactor = .one

        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
    func updatePointPipeline(isColor: Bool = false) {
        guard let target = target, let device = sharedDevice, let library = makeShaderLibrary(from: device) else {
            return
        }
        
        let rpd = MTLRenderPipelineDescriptor()
        
        if let vertex_func = makeShaderVertexFunction(from: library) {
            rpd.vertexFunction = vertex_func
        }
        
        if isColor {
            if let fragment_func = makeShaderColorFragmentFunction(from: library) {
                rpd.fragmentFunction = fragment_func
            }
        } else {
            if let fragment_func = makeShaderFragmentFunction(from: library) {
                rpd.fragmentFunction = fragment_func
            }
        }
        
        rpd.colorAttachments[0].pixelFormat = target.colorPixelFormat
        setupBlendOptions(for: rpd.colorAttachments[0]!)
        pipelineState = try! device.makeRenderPipelineState(descriptor: rpd)
    }
    
    func updateSubtractivePointPipeline(isColor: Bool = false) {
        guard let target = target, let device = sharedDevice, let library = makeShaderLibrary(from: device) else {
            return
        }
        
        let rpd = MTLRenderPipelineDescriptor()
        
        if let vertex_func = makeShaderVertexFunction(from: library) {
            rpd.vertexFunction = vertex_func
        }
        
        if isColor {
            if let fragment_func = makeShaderColorFragmentFunction(from: library) {
                rpd.fragmentFunction = fragment_func
            }
        } else {
            if let fragment_func = makeShaderFragmentFunction(from: library) {
                rpd.fragmentFunction = fragment_func
            }
        }
        
        rpd.colorAttachments[0].pixelFormat = target.colorPixelFormat
        setupSubtractiveBlendOptions(for: rpd.colorAttachments[0]!)
        subtractivePipelineState = try! device.makeRenderPipelineState(descriptor: rpd)
    }
    
    func updateTransparentPointPipeline(isColor: Bool = false) {
        guard let target = target, let device = sharedDevice, let library = makeShaderLibrary(from: device) else {
            return
        }
        
        let rpd = MTLRenderPipelineDescriptor()
        
        if let vertex_func = makeShaderVertexFunction(from: library) {
            rpd.vertexFunction = vertex_func
        }
        
        if isColor {
            if let fragment_func = makeShaderColorFragmentFunction(from: library) {
                rpd.fragmentFunction = fragment_func
            }
        } else {
            if let fragment_func = makeShaderFragmentFunction(from: library) {
                rpd.fragmentFunction = fragment_func
            }
        }
        
        rpd.colorAttachments[0].pixelFormat = target.colorPixelFormat
        setupTransparentBlendOptions(for: rpd.colorAttachments[0]!)
        transparentPipelineState = try! device.makeRenderPipelineState(descriptor: rpd)
    }

}
