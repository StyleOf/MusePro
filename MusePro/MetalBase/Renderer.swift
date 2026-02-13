import Foundation
import MetalKit
import MetalPerformanceShaders

class Renderer: NSObject {
    
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var secondaryCommandQueue: MTLCommandQueue

    var currentTexture: MTLTexture?
    var blurredTexture: MTLTexture?
    var resizedTexture: MTLTexture?
    var temporaryTexture: MTLTexture?
    var offscreenTexture: MTLTexture?
    
    var context: CIContext?

    var scaleShader: MPSImageScale?
    
    weak var canvas: MTKCanvas?
    
    var contentScaleFactor: CGFloat {
        get {
            return canvas?.contentScaleFactor ?? 2.0
        }
    }
    
    init(with canvas: MTKCanvas, bufferCompletedHandler: @escaping (_ buffer: MTLCommandBuffer) -> Void) throws {
        guard let device = sharedDevice,
              let queue = device.makeCommandQueue(),
              let secondaryQueue = device.makeCommandQueue()
        else {
            throw MLError.initializationError
        }
        
        self.device = device
        self.commandQueue = queue
        self.secondaryCommandQueue = secondaryQueue
        self.canvas = canvas
        self.bufferCompletedHandler = bufferCompletedHandler
        
        self.computeBoundsFunction = device.makeDefaultLibrary()!.makeFunction(name: "computeBounds")!
        self.computeBoundsPipelineState = try device.makeComputePipelineState(function: self.computeBoundsFunction)

        self.computeBoundsWithMaskFunction = device.makeDefaultLibrary()!.makeFunction(name: "computeBoundsWithMask")!
        self.computeBoundsWithMaskPipelineState = try device.makeComputePipelineState(function: self.computeBoundsWithMaskFunction)

        self.copyTextureWithMaskFunction = device.makeDefaultLibrary()!.makeFunction(name: "copyTextureWithMask")!
        self.copyTextureWithMaskPipelineState = try device.makeComputePipelineState(function: self.copyTextureWithMaskFunction)
        
        
        self.scaleShader = MPSImageBilinearScale(device: device)

        self.context = CIContext(mtlDevice: device)

        super.init()
        
        setupTargetUniforms()
        
        do {
            try setupPiplineState()
            try setupSubtractivePiplineState()
            try setupTransparentPiplineState()
            try setupClearPiplineState()
        } catch {
            fatalError("Metal initialize failed: \(error.localizedDescription)")
        }
        
        self.currentTexture = makeEmptyMetalTexture(label: "Renderer Current Texture")
        self.temporaryTexture = makeEmptyMetalTexture(label: "Renderer Temporary Texture")
        self.offscreenTexture = makeEmptyMetalTexture(label: "Renderer Offscreen Texture")
        self.blurredTexture = makeEmptyMetalTexture(with: CGSize(width: canvas.drawableSize.width, height: canvas.drawableSize.height), label: "Blurred Texture")
        self.resizedTexture = makeEmptyMetalTexture(with: CGSize(width: canvas.drawableSize.width / canvas.contentScaleFactor, height: canvas.drawableSize.height / canvas.contentScaleFactor), label: "Renderer Resized Texture")
        

    }
    
    var computeBoundsFunction: MTLFunction
    var computeBoundsPipelineState: MTLComputePipelineState

    var computeBoundsWithMaskFunction: MTLFunction
    var computeBoundsWithMaskPipelineState: MTLComputePipelineState

    var copyTextureWithMaskFunction: MTLFunction
    var copyTextureWithMaskPipelineState: MTLComputePipelineState

    var bufferCompletedHandler: (_ buffer: MTLCommandBuffer) -> Void
    
    var pipelineState: MTLRenderPipelineState!
    var subtractivePipelineState: MTLRenderPipelineState!
    var transparentPipelineState: MTLRenderPipelineState!
    var clearPipelineState: MTLRenderPipelineState!

    func setupPiplineState() throws {
        guard let canvas else { return }
        let library = sharedDevice?.library()
        let vertex_func = library?.makeFunction(name: "vertex_render_target")
        let fragment_func = library?.makeFunction(name: "fragment_render_target")
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = canvas.colorPixelFormat
        
        if let attachment = rpd.colorAttachments[0] {
            attachment.isBlendingEnabled = true
            
            attachment.rgbBlendOperation = .add
            attachment.alphaBlendOperation = .add

            attachment.sourceRGBBlendFactor = .sourceAlpha
            attachment.sourceAlphaBlendFactor = .one

            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }
        
        pipelineState = try sharedDevice?.makeRenderPipelineState(descriptor: rpd)
    }
    
    func setupClearPiplineState() throws {
        guard let canvas else { return }
        let library = sharedDevice?.library()
        let vertex_func = library?.makeFunction(name: "vertex_render_target")
        let fragment_func = library?.makeFunction(name: "clear_fragment_render_target")
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = canvas.colorPixelFormat
        
        clearPipelineState = try sharedDevice?.makeRenderPipelineState(descriptor: rpd)
    }
    
    func setupTransparentPiplineState() throws {
        guard let canvas else { return }

        let library = sharedDevice?.library()
        let vertex_func = library?.makeFunction(name: "vertex_render_target")
        let fragment_func = library?.makeFunction(name: "fragment_render_target")
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = canvas.colorPixelFormat
        
        if let attachment = rpd.colorAttachments[0] {
            attachment.isBlendingEnabled = true
            
            attachment.rgbBlendOperation = .add
            attachment.alphaBlendOperation = .add

            attachment.sourceRGBBlendFactor = .one
            attachment.sourceAlphaBlendFactor = .one

            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }
        
        transparentPipelineState = try sharedDevice?.makeRenderPipelineState(descriptor: rpd)
    }
    
    func setupSubtractivePiplineState() throws {
        guard let canvas else { return }

        let library = sharedDevice?.library()
        let vertex_func = library?.makeFunction(name: "vertex_render_target")
        let fragment_func = library?.makeFunction(name: "fragment_render_target")
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = vertex_func
        rpd.fragmentFunction = fragment_func
        rpd.colorAttachments[0].pixelFormat = canvas.colorPixelFormat
        
        if let attachment = rpd.colorAttachments[0] {
            attachment.isBlendingEnabled = true
            
            attachment.rgbBlendOperation = .reverseSubtract
            attachment.alphaBlendOperation = .reverseSubtract

            attachment.sourceRGBBlendFactor = .zero
            attachment.sourceAlphaBlendFactor = .one

            attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
            attachment.destinationAlphaBlendFactor = .one
        }
        
        subtractivePipelineState = try sharedDevice?.makeRenderPipelineState(descriptor: rpd)
    }
    
//    var render_target_vertex: MTLBuffer!
//    var uniform_buffer: MTLBuffer!
//    var transform_buffer: MTLBuffer!
//    
//    
//    func setupTargetUniforms() {
//      
//        render_target_vertex = createVertexBuffer()
//        uniform_buffer = createUniformBuffer()
//        transform_buffer = createTransformBuffer()
//    }
//    
    
    var renderTargetVertices: [MTLBuffer?] = []
    var uniformBuffers: [MTLBuffer?] = []
    var transformBuffers: [MTLBuffer?] = [] // Assuming you'll implement this similarly

    var time: Float = 0.0 // Time variable
    var timeBuffer: MTLBuffer? // Time buffer

    // Function to update time and time buffer
    func updateTime() {
        // Update the time variable, e.g., incrementing by a delta time
        time += 0.01 // This is an example, adjust based on your animation speed requirements

        // Ensure the time buffer exists or create it
        if timeBuffer == nil {
            timeBuffer = device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
        }
        
        // Update the time buffer with the new time value
        let bufferPointer = timeBuffer?.contents().bindMemory(to: Float.self, capacity: 1)
        bufferPointer?[0] = time
    }
    
    func getTimeBuffer() -> MTLBuffer? {
        updateTime()
        return timeBuffer
    }
    
    func setupTargetUniforms() {
        // Initialize three copies of each buffer
        for _ in 0..<3 {
            renderTargetVertices.append(createVertexBuffer())
            uniformBuffers.append(createUniformBuffer())
            transformBuffers.append(createTransformBuffer())
        }
    }
    
    func createVertexBuffer() -> MTLBuffer? {
        guard let canvas else { return nil }

        let size = canvas.drawableSize
        let w = size.width, h = size.height
        let vertices = [
            Vertex(position: CGPoint(x: 0 , y: 0), textCoord: CGPoint(x: 0, y: 0)),
            Vertex(position: CGPoint(x: w , y: 0), textCoord: CGPoint(x: 1, y: 0)),
            Vertex(position: CGPoint(x: 0 , y: h), textCoord: CGPoint(x: 0, y: 1)),
            Vertex(position: CGPoint(x: w , y: h), textCoord: CGPoint(x: 1, y: 1)),
        ]
        return sharedDevice?.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: .cpuCacheModeWriteCombined)
    }
    
    func createUniformBuffer() -> MTLBuffer? {
        guard let canvas else { return nil }

        let size = canvas.drawableSize
        let matrix = Matrix.identity
        matrix.scaling(x: 2 / Float(size.width), y: -2 / Float(size.height), z: 1)
        matrix.translation(x: -1, y: 1, z: 0)
        return sharedDevice?.makeBuffer(bytes: matrix.m, length: MemoryLayout<Float>.size * 16, options: [])
    }
    
    func createTransformBuffer() -> MTLBuffer? {
        var transform = ScrollingTransform(offset: CGPoint(x: 0, y: 0), scale: 1)
        return sharedDevice?.makeBuffer(bytes: &transform, length: MemoryLayout<ScrollingTransform>.stride, options: [])
    }
    
//    var commandBuffer: MTLCommandBuffer?
//
//    func getCommandBuffer() -> MTLCommandBuffer? {
//        if commandBuffer == nil {
//            commandBuffer = commandQueue.makeCommandBuffer()
//            commandBuffer?.label = "Renderer Default Command Buffer"
//        }
//        return commandBuffer
//    }
//    
//    func makeCommandEncoder(descriptor: MTLRenderPassDescriptor) -> MTLRenderCommandEncoder? {
//        if let commandBuffer = getCommandBuffer() {
//            return commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
//        }
//        return nil
//    }
//    
//    func commitCommands(wait: Bool = true, present drawable: MTLDrawable? = nil) {
//
//        if let commandBuffer = getCommandBuffer() {
//            if let drawable {
//                commandBuffer.present(drawable)
//            }
//            commandBuffer.commit()
//            if wait {
//                commandBuffer.waitUntilCompleted()
//            }
//            self.commandBuffer = nil
//        }
//    }
    
    // Assuming you have access to the Metal device and command queue
    var commandBuffers: [MTLCommandBuffer?] = [nil, nil, nil]
    let semaphore = DispatchSemaphore(value: 3) // For triple buffering
    var currentBufferIndex = 0

    func getCommandBuffer() -> MTLCommandBuffer? {


        let bufferIndex = currentBufferIndex % 3
        if commandBuffers[bufferIndex] == nil {
            semaphore.wait() // Wait for a buffer to become available
//            print("Creating cmd buffer \(bufferIndex) : \(currentBufferIndex)")
            commandBuffers[bufferIndex] = commandQueue.makeCommandBuffer()
            commandBuffers[bufferIndex]?.label = "Renderer Command Buffer \(bufferIndex)"
//            commandBuffers[bufferIndex]?.enqueue()
        }
        return commandBuffers[bufferIndex]
    }
    
    func makeCommandEncoder(descriptor: MTLRenderPassDescriptor) -> MTLRenderCommandEncoder? {
        if let commandBuffer = getCommandBuffer() {
            return commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        }
        return nil
    }

    func commitCommands(wait: Bool = false, present drawable: MTLDrawable? = nil) {
//        print("committing buffer",currentBufferIndex % 3, currentBufferIndex )
        if let commandBuffer = commandBuffers[currentBufferIndex % 3] {

            if let drawable = drawable {
                commandBuffer.present(drawable)
            }
            
//            if !wait {
//                commandBuffer.addCompletedHandler { buffer in
//                  
//                }
//            }
            
            commandBuffer.commit()
           
            
            if wait {
//                print("waiting cmd buffer")
                commandBuffer.waitUntilCompleted()
            }
                        
            self.commandBuffers[self.currentBufferIndex % 3] = nil
            self.currentBufferIndex += 1
            self.semaphore.signal()

        }
    }
    
     func getNextRenderTargetVertex() -> MTLBuffer? {
         let buffer = renderTargetVertices[currentBufferIndex % 3]
//         rotateBuffers()
         return buffer
     }

     func getNextUniformBuffer() -> MTLBuffer? {
         let buffer = uniformBuffers[currentBufferIndex % 3]
         // No need to call rotateBuffers() here to avoid rotating more than once per frame
         return buffer
     }

      func getNextTransformBuffer() -> MTLBuffer? {
          let buffer = transformBuffers[currentBufferIndex % 3]
          // No call to rotateBuffers() here
          return buffer
      }

     private func rotateBuffers() {
         currentBufferIndex = (currentBufferIndex + 1) % 3 // Rotate index in a cyclic manner
     }
    
    //= "Renderer Draw Call"
    func draw(label: String, texture: MTLTexture?, on targetTexture: MTLTexture, subtractive: Bool = false, transparent: Bool = false, clear: Bool = false, opacity: Float = 1.0) {
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = targetTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .load
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
       
        if let commandEncoder = makeCommandEncoder(descriptor: renderPassDescriptor) {
            commandEncoder.label = label
            if subtractive {
                commandEncoder.setRenderPipelineState(subtractivePipelineState)
            } else if transparent {
                commandEncoder.setRenderPipelineState(transparentPipelineState)
            } else if clear {
                commandEncoder.setRenderPipelineState(clearPipelineState)
            } else {
                commandEncoder.setRenderPipelineState(pipelineState)
            }
            commandEncoder.setVertexBuffer(getNextRenderTargetVertex(), offset: 0, index: 0)
            commandEncoder.setVertexBuffer(getNextUniformBuffer(), offset: 0, index: 1)
            if let texture {
                commandEncoder.setFragmentTexture(texture, index: 0)
            }
            var layerRenderData = LayerRenderData(opacity: opacity) // Set to 0 to use the mask directly, 1 to use its inverse
            let layerRenderDataBuffer = device.makeBuffer(bytes: &layerRenderData, length: MemoryLayout<LayerRenderData>.size, options: .storageModeShared)
            commandEncoder.setFragmentBuffer(layerRenderDataBuffer, offset: 0, index: 0)

            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            commandEncoder.endEncoding()
        }
    }
    
    //Make texture with Data
    //Make texture with Size
    //Make texture with Color
    //Make texture with file URL
    //Make performance texture with Data
    //Discard?
    
    func makeTexture(with data: Data, id: String? = nil) throws -> MLTexture? {
        guard metalAvaliable else {
            throw MLError.simulatorUnsupported
        }
        
        if let device = sharedDevice {
            let textureLoader = MTKTextureLoader(device: device)
            do {
                let loadedTexture = try textureLoader.newTexture(data: data, options: [.SRGB : false])
            
                let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: loadedTexture.pixelFormat,
                                                                                 width: loadedTexture.width,
                                                                                 height: loadedTexture.height,
                                                                                 mipmapped: false)
                textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
                guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
                    throw MLError.textureCreationFailed
                }
                
                if let blitCommandBuffer = commandQueue.makeCommandBuffer() {
                    let blitEncoder = blitCommandBuffer.makeBlitCommandEncoder()
                    blitEncoder?.label = "Make Texture With Data"
                    blitEncoder?.copy(from: loadedTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(loadedTexture.width, loadedTexture.height, loadedTexture.depth), to: texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
                    blitEncoder?.endEncoding()
                    blitCommandBuffer.commit()
                    blitCommandBuffer.waitUntilCompleted()
                }

                return MLTexture(id: id ?? UUID().uuidString, texture: texture)
            } catch {
                print(error)
            }
        }

        return nil
    }
    
    func makeMetalTexture(with data: Data) throws -> MTLTexture? {
        guard metalAvaliable else {
            throw MLError.simulatorUnsupported
        }
        
        if let device = sharedDevice {
            let textureLoader = MTKTextureLoader(device: device)
            let loadedTexture = try textureLoader.newTexture(data: data, options: [.SRGB : false])
//            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: loadedTexture.pixelFormat,
//                                                                             width: loadedTexture.width,
//                                                                             height: loadedTexture.height,
//                                                                             mipmapped: false)
//            textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
//            guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
//                throw MLError.textureCreationFailed
//            }
//            
//            if let blitCommandBuffer = commandQueue.makeCommandBuffer() {
//                let blitEncoder = blitCommandBuffer.makeBlitCommandEncoder()
//                blitEncoder?.label = "Make Texture With Data"
//                blitEncoder?.copy(from: loadedTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(loadedTexture.width, loadedTexture.height, loadedTexture.depth), to: texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
//                blitEncoder?.endEncoding()
//                blitCommandBuffer.commit()
//                blitCommandBuffer.waitUntilCompleted()
//            }

            return loadedTexture
        }

        return nil
    }
    
    func makeEmptyMetalTexture(label: String? = nil) -> MTLTexture? {
        guard let canvas else { return nil }

        guard canvas.drawableSize.width * canvas.drawableSize.height > 0 else {
            return nil
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: canvas.colorPixelFormat,
                                                                         width: Int(canvas.drawableSize.width),
                                                                         height: Int(canvas.drawableSize.height),
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        textureDescriptor.storageMode = .private
        textureDescriptor.allowGPUOptimizedContents = true
        let texture = sharedDevice?.makeTexture(descriptor: textureDescriptor)
        if let label {
            texture?.label = label
        }
        
        draw(label: "Clear", texture: nil, on: texture!, clear: true)
        commitCommands()
        
        return texture
    }
    
    func makeEmptyMetalTexture(with size: CGSize, label: String? = nil) -> MTLTexture? {
        guard let canvas else { return nil }

        guard size.width * size.height > 0 else {
            return nil
        }
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: canvas.colorPixelFormat,
                                                                         width: Int(size.width),
                                                                         height: Int(size.height),
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
//        textureDescriptor.storageMode = .private
        let texture = sharedDevice?.makeTexture(descriptor: textureDescriptor)
        if let label {
            texture?.label = label
        }
        
        return texture
    }
    
    func makeEmptyTexture(with size: CGSize, id: String? = nil) -> MLTexture? {
        guard let canvas else { return nil }

        guard size.width * size.height > 0 else {
            return nil
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: canvas.colorPixelFormat,
                                                                         width: Int(size.width),
                                                                         height: Int(size.height),
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead]
        if let texture = sharedDevice?.makeTexture(descriptor: textureDescriptor) {
            return MLTexture(id: id ?? UUID().uuidString, texture: texture)
        }
        
        return nil
    }
    
    func makeEmptyComputeTexture(with size: CGSize, id: String? = nil) -> MLTexture? {
        guard let canvas else { return nil }

        guard size.width * size.height > 0 else {
            return nil
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: canvas.colorPixelFormat,
                                                                         width: Int(size.width),
                                                                         height: Int(size.height),
                                                                         mipmapped: false)
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        if let texture = sharedDevice?.makeTexture(descriptor: textureDescriptor) {
            return MLTexture(id: id ?? UUID().uuidString, texture: texture)
        }
        
        return nil
    }
    
    func makePerformanceTexture(with data: Data, id: String? = nil) throws -> MLTexture? {
        
        guard metalAvaliable else {
            throw MLError.simulatorUnsupported
        }
        
        if let device = sharedDevice {
            
            let textureLoader = MTKTextureLoader(device: device)
            let loadedTexture = try textureLoader.newTexture(data: data, options: [.SRGB : false])
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: loadedTexture.pixelFormat,
                                                                             width: loadedTexture.width,
                                                                             height: loadedTexture.height,
                                                                             mipmapped: false)
            textureDescriptor.allowGPUOptimizedContents = true
            textureDescriptor.storageMode = .private
            textureDescriptor.usage = [.shaderRead]
            guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
                throw MLError.textureCreationFailed
            }

            if let blitCommandBuffer = commandQueue.makeCommandBuffer() {
                let blitEncoder = blitCommandBuffer.makeBlitCommandEncoder()
                blitEncoder?.label = "Make Texture With Data"
                blitEncoder?.copy(from: loadedTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(loadedTexture.width, loadedTexture.height, loadedTexture.depth), to: texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
                blitEncoder?.optimizeContentsForGPUAccess(texture: texture)
                blitEncoder?.endEncoding()
                blitCommandBuffer.commit()
                blitCommandBuffer.waitUntilCompleted()

                return MLTexture(id: id ?? UUID().uuidString, texture: texture)
            }
        }

        return nil
    }
    
    func makeTexture(with file: URL, id: String? = nil) throws -> MLTexture? {
        let data = try Data(contentsOf: file)
        return try makeTexture(with: data, id: id)
    }
    
    func blurTexture(texture: MTLTexture, to targetTexture: MTLTexture, by sigma: Float = 0.5) {
        if let blurCommandBuffer = commandQueue.makeCommandBuffer() {
            blurCommandBuffer.label = "Blur Command Buffer"
            let blurShader = MPSImageGaussianBlur(device: device, sigma: sigma)

            blurShader.encode(commandBuffer: blurCommandBuffer, sourceTexture: texture, destinationTexture: targetTexture)
            blurCommandBuffer.addCompletedHandler(bufferCompletedHandler)
            blurCommandBuffer.commit()
        }
    }
    
    func resizeAndBlurTexture(texture: MTLTexture, to targetTexture: MTLTexture, by factor: Double = 0.5, sigma: Float = 0.5) {
        guard let blurredTexture else { return }
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            commandBuffer.label = "Scale and Blur Command Buffer"
            let scale = MPSScaleTransform(scaleX: factor, scaleY: factor, translateX: 0, translateY: 0)

            withUnsafePointer(to: scale, { scalePointer in
               self.scaleShader?.scaleTransform = scalePointer
            })
            
            
            let blurShader = MPSImageGaussianBlur(device: device, sigma: sigma)
            blurShader.encode(commandBuffer: commandBuffer, sourceTexture: texture, destinationTexture: blurredTexture)
            
            self.scaleShader?.encode(commandBuffer: commandBuffer, sourceTexture: blurredTexture, destinationTexture: targetTexture)
                        
            commandBuffer.addCompletedHandler(bufferCompletedHandler)
            commandBuffer.commit()
        }
    }
    
    func resizeTexture(texture: MTLTexture, to targetTexture: MTLTexture, by factor: Double = 0.5) {
        if let scaleCommandBuffer = commandQueue.makeCommandBuffer() {
            scaleCommandBuffer.label = "Scale Command Buffer"
            let scale = MPSScaleTransform(scaleX: factor, scaleY: factor, translateX: 0, translateY: 0)
            withUnsafePointer(to: scale, { scalePointer in
               self.scaleShader?.scaleTransform = scalePointer
            })
            self.scaleShader?.encode(commandBuffer: scaleCommandBuffer, sourceTexture: texture, destinationTexture: targetTexture)
            scaleCommandBuffer.addCompletedHandler(bufferCompletedHandler)
            scaleCommandBuffer.commit()
            
//            scaleCommandBuffer.waitUntilCompleted()
        }
    }
    
//    func cropTexture(_ texture: MTLTexture?, frame: CGRect) -> MTLTexture? {
//        if let texture {
//            updateBuffer(with: frame.size)
//            let newTexture = makeEmptyTexture()
//            prepareForDraw()
//            let sourceRegion = MTLRegionMake2D(Int(frame.origin.x), Int(frame.origin.y), Int(frame.size.width), Int(frame.size.height))
//            let destOrigin = MTLOrigin(x: 0, y: 0, z: 0)
//            let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
//            blitEncoder?.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: sourceRegion.origin, sourceSize: sourceRegion.size, to: newTexture!, destinationSlice: 0, destinationLevel: 0, destinationOrigin: destOrigin)
//            blitEncoder?.endEncoding()
//            commitCommands(wait: true)
//            return newTexture!
//        }
//        return nil
//    }
}
