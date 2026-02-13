import Metal
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

class CanvasData: ObservableObject {
    weak var canvas: MTKCanvas?
    
    var currentElement: CanvasElement?
    
    @Published var layers: [Layer] = [Layer]()
    {
        didSet {
            currentLayerId = currentLayerId
        }
    }
    @Published var currentLayerId: UUID? {
        didSet {
            if let currentLayer = layers.first(where: { $0.id == currentLayerId }) {
                self.currentLayer = currentLayer
            } else {
                if let layer = layers.last {
                    currentLayerId = layer.id
                    self.currentLayer = layer
                } else {
                    createEmptyLayer()
                    let layer = layers.first(where: { $0.id == currentLayerId })!
                    self.currentLayer = layer
                }
            }
        }
    }
    var currentLayer: Layer
    var clear: Clear
    var background: MLRectangle
    
    var commandManager: CommandManager!
    
    var registeredBrushes: [Brush] = [Brush]()

    var textures: [MLTexture] = [MLTexture]()
    
    //    var layerTarget: RenderTarget
    
    init(canvas: MTKCanvas) {
        self.canvas = canvas
        self.commandManager = CommandManager.shared
        self.commandManager.reset()
        
        self.clear = Clear()
        self.clear.printer = canvas.colorPrinter
        
        self.background = MLRectangle(color: .white)
        self.background.size = canvas.size
        self.background.center = CGPoint(x: canvas.size.width / 2, y: canvas.size.height / 2)
        self.background.printer = canvas.colorPrinter
        
        let emptyLayer = Layer(index: 0)
        let layers = [emptyLayer]
        self.layers = layers
        self.currentLayerId = emptyLayer.id
        self.currentLayer = emptyLayer
    }
    
    func createLayer(index: Int = 0) -> Layer {
        let newLayer = Layer(index: index)
        return newLayer
    }
    
    //TODO: New create layer func for existing layer
    func createEmptyLayer(index: Int? = nil) {
        if canvas?.canvasManager?.currentMode == .selection {
            canvas?.canvasManager?.currentMode = .brush
        }
        let lastIndex = layers.last?.index ?? 0
        let newLayer = createLayer(index: index ?? lastIndex + 1)
        let command = CreateLayerCommand(modifyLayers: { newLayers in
            if !newLayers.isEmpty {
                self.layers.append(contentsOf: newLayers)
            } else {
                self.layers.removeAll { $0.id == newLayer.id }
            }
        }, newLayer: newLayer)
        commandManager.executeCommand(command)
        currentLayerId = newLayer.id
    }
    
    var textureOffset: CGSize = CGSize(width: 0, height: 0)
    
    func append(lines: [MLLine], with brush: Brush) -> Bool {
        guard lines.count > 0 else {
            return false
        }
        // append lines to current line strip
        if let lineStrip = currentElement as? LineStrip, lineStrip.brush === brush {
            lineStrip.append(lines: lines)
            return false
        } else {
            
            finishCurrentElement()
            
            textureOffset = CGSize(width: CGFloat.random(in: 0...1), height: CGFloat.random(in: 0...1))
            let lineStrip = LineStrip(lines: lines, brush: brush, textureOffset: textureOffset)
            currentElement = lineStrip
            
            observers.lineStrip(lineStrip, didBeginOn: self)
            return true
        }
    }
    
    func append(element: CanvasElement) {
        currentElement = element
        let addElementCommand = AddElementCommand(layer: currentLayer, element: element)
        commandManager.executeCommand(addElementCommand)
    }
    
    func appendSilent(element: CanvasElement) {
        let addElementCommand = AddElementCommand(layer: currentLayer, element: element)
        commandManager.executeCommand(addElementCommand)
    }
    
    func finishCurrentElement() {
        guard let element = currentElement else {
            return
        }
//        if let e = currentElement as? Chartlet {
//            print("Finishing element", currentElement?.id)
//        }
        if let _ = element as? LineStrip, let texture = canvas?.canvasManager?.renderer?.temporaryTexture, let convertedElement = trimTextureToChartlet(texture: texture, subtractive: canvas?.canvasManager?.currentMode == .eraser, smart: false){
            //            print("Finish line strip")
            let addElementCommand = AddElementCommand(layer: currentLayer, element: convertedElement)
            commandManager.executeCommand(addElementCommand)
        }
                
        currentElement = nil
//        canvas?.renderer?.temporaryTexture = nil
        canvas?.redrawCurrentLayer()
        observers.element(element, didFinishOn: self)
    }
    
    //TODO: make this an undoable action
    func rasterizeElement(element: CanvasElement) {
        if let temporaryLayerDrawable = currentLayer.temporaryDrawable,
           let layerDrawable = currentLayer.drawable {
            canvas?.canvasManager?.renderer?.draw(label: "Clear", texture: nil, on: layerDrawable, clear: true)
//            canvas?.renderer?.commitCommands()
            
            canvas?.canvasManager?.renderer?.draw(label: "Layer Temp -> Layer Drawable", texture: temporaryLayerDrawable, on: layerDrawable)
            canvas?.canvasManager?.renderer?.commitCommands()
        }
        canvas?.redraw()
    }
    
    func prepareForTransform(_ layer: Layer) -> CanvasElement? {
        if let texture = layer.drawable, let element = trimTextureToChartlet(texture: texture, smart: true) {
            let transformCommand = PrepareElementForTransformCommand(layer: layer, transformedElement: element)
            commandManager.executeCommand(transformCommand)
            canvas?.redrawCurrentLayer()
            return element
        }
        return nil
    }
    
    func prepareForTransformWithMask(_ layer: Layer, toNewLayer: Bool = false, mask: UIImage) -> CanvasElement? {
        if let canvasManager = canvas?.canvasManager, let maskData = mask.pngData(), let maskTexture = try? canvas?.makeTexture(with: maskData), let texture = layer.drawable, let element = trimTextureToChartlet(texture: texture, mask: maskTexture.texture, smart: true) {
            let transformCommand = PrepareElementForTransformWithMaskCommand(canvasManager: canvasManager, layer: layer, toNewLayer: toNewLayer, transformedElement: element)
            commandManager.executeCommand(transformCommand)
            canvas?.redrawCurrentLayer()
            return element
        }
        return nil
    }
    
    func prepareForTransformWithMaskAndCut(_ layer: Layer, toNewLayer: Bool = false, mask: UIImage) -> CanvasElement? {
        if let canvasManager = canvas?.canvasManager, let maskData = mask.pngData(), let maskTexture = try? canvas?.makeTexture(with: maskData), let texture = layer.drawable, let transformedElement = trimTextureToChartlet(texture: texture, mask: maskTexture.texture, smart: true), let cutElement = cutMaskedToChartlet(texture: texture, mask: maskTexture.texture) {
            let transformCommand = PrepareElementForTransformWithMaskAndCutCommand(canvasManager: canvasManager, layer: layer, toNewLayer: toNewLayer, cutElement: cutElement, transformedElement: transformedElement)
            commandManager.executeCommand(transformCommand)
            canvas?.redrawLayers()
            return transformedElement
        }
        return nil
    }
    
    func trimTextureToChartlet(texture: MTLTexture, mask: MTLTexture? = nil, subtractive: Bool = false, smart: Bool = false) -> CanvasElement? {
        //        print("trim texture to chartlet")
        if let renderer = canvas?.canvasManager?.renderer,
           let bounds = texture.calculateFilledArea(renderer: renderer, mask: mask) {
            
            guard bounds.size.width >= 0, bounds.size.height >= 0 else {
                print("unexpectedly found and empty textute while temp to chart", bounds)
                return nil
            }
            
            var sourceTexture = texture
            
            if mask != nil {
                if let newTexture = canvas?.makeEmptyComputeTexture(with: CGSize(width: texture.width, height: texture.height)),
                   let commandBuffer = renderer.commandQueue.makeCommandBuffer(),
                   let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                    commandBuffer.label = "Copy Texture With Mask Buffer"
                    computeEncoder.label = "Copy Texture With Mask Encoder"

                    
                    computeEncoder.setComputePipelineState(renderer.copyTextureWithMaskPipelineState)
                    
                    var controlData = ControlData(useInverseMask: 0) // Set to 0 to use the mask directly, 1 to use its inverse
                    let controlDataBuffer = renderer.device.makeBuffer(bytes: &controlData, length: MemoryLayout<ControlData>.size, options: .storageModeShared)
                    computeEncoder.setBuffer(controlDataBuffer, offset: 0, index: 0)
                    
                    computeEncoder.setTexture(texture, index: 0)
                    computeEncoder.setTexture(mask, index: 1)
                    computeEncoder.setTexture(newTexture.texture, index: 2)

               
                    let threadExecutionWidth = renderer.copyTextureWithMaskPipelineState.threadExecutionWidth
                    let maxTotalThreadsPerThreadgroup = renderer.copyTextureWithMaskPipelineState.maxTotalThreadsPerThreadgroup
                    let threadsPerThreadgroup = MTLSize(width: threadExecutionWidth, height: maxTotalThreadsPerThreadgroup / threadExecutionWidth, depth: 1)
                    
                    let threadgroupsPerGrid = MTLSize(width: (texture.width + threadsPerThreadgroup.width + 1) / threadsPerThreadgroup.width,
                                                      height: (texture.height + threadsPerThreadgroup.height + 1) / threadsPerThreadgroup.height,
                                                      depth: 1)

                    computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                    computeEncoder.endEncoding()
                    
                    commandBuffer.commit()
                    commandBuffer.waitUntilCompleted()
                    
                    sourceTexture = newTexture.texture
                }
            }
            
            if let newTexture = canvas?.makeEmptyTexture(with: bounds.size),
               let blitCommandBuffer = canvas?.canvasManager?.renderer?.commandQueue.makeCommandBuffer() {
                blitCommandBuffer.label = "Crop Texture Buffer"
                
                let sourceRegion = MTLRegionMake2D(Int(bounds.origin.x), Int(bounds.origin.y), Int(bounds.size.width), Int(bounds.size.height))
                let destOrigin = MTLOrigin(x: 0, y: 0, z: 0)
                
                let blitEncoder = blitCommandBuffer.makeBlitCommandEncoder()
                blitEncoder?.label = "Crop Texture Encoder"
                blitEncoder?.copy(from: sourceTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: sourceRegion.origin, sourceSize: sourceRegion.size, to: newTexture.texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: destOrigin)
                blitEncoder?.endEncoding()
                blitCommandBuffer.commit()
                blitCommandBuffer.waitUntilCompleted()
                
                let mergedElement = Chartlet(textureID: newTexture.id)
                mergedElement.subtractive = subtractive
                mergedElement.printer = canvas?.printer
                mergedElement.smartObject = smart
                mergedElement.size = CGSize(width: newTexture.texture.width, height: newTexture.texture.height) / (canvas?.contentScaleFactor ?? 2.0)
                mergedElement.center = bounds.center / (canvas?.contentScaleFactor ?? 2.0)
                
                return mergedElement
            }
            
           
        }
        
//        print("Failed to trim texture")
        
        return nil
    }
    
    func cutMaskedToChartlet(texture: MTLTexture, mask: MTLTexture? = nil, subtractive: Bool = false, smart: Bool = false) -> CanvasElement? {
        //        print("trim texture to chartlet")
        if let renderer = canvas?.canvasManager?.renderer,
           let bounds = texture.calculateFilledArea(renderer: renderer, mask: nil) {
            
            guard bounds.size.width >= 0, bounds.size.height >= 0 else {
                print("unexpectedly found and empty textute while temp to chart", bounds)
                return nil
            }
            
            var sourceTexture = texture
            
            if mask != nil {
                if let newTexture = canvas?.makeEmptyComputeTexture(with: CGSize(width: texture.width, height: texture.height)),
                   let commandBuffer = renderer.commandQueue.makeCommandBuffer(),
                   let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
                    commandBuffer.label = "Copy Texture With Mask Buffer"
                    computeEncoder.label = "Copy Texture With Mask Encoder"

                    computeEncoder.setComputePipelineState(renderer.copyTextureWithMaskPipelineState)
                    var controlData = ControlData(useInverseMask: 1) // Set to 0 to use the mask directly, 1 to use its inverse

                    // Create a buffer for control data
                    let controlDataBuffer = renderer.device.makeBuffer(bytes: &controlData, length: MemoryLayout<ControlData>.size, options: .storageModeShared)

                    // Set the buffer before dispatching the compute command
                    computeEncoder.setBuffer(controlDataBuffer, offset: 0, index: 0)
                    computeEncoder.setTexture(texture, index: 0)
                    computeEncoder.setTexture(mask, index: 1)
                    computeEncoder.setTexture(newTexture.texture, index: 2)
               
                    let threadExecutionWidth = renderer.copyTextureWithMaskPipelineState.threadExecutionWidth
                    let maxTotalThreadsPerThreadgroup = renderer.copyTextureWithMaskPipelineState.maxTotalThreadsPerThreadgroup
                    let threadsPerThreadgroup = MTLSize(width: threadExecutionWidth, height: maxTotalThreadsPerThreadgroup / threadExecutionWidth, depth: 1)
                    
                    let threadgroupsPerGrid = MTLSize(width: (texture.width + threadsPerThreadgroup.width + 1) / threadsPerThreadgroup.width,
                                                      height: (texture.height + threadsPerThreadgroup.height + 1) / threadsPerThreadgroup.height,
                                                      depth: 1)

                    computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
                    computeEncoder.endEncoding()
                    
                    commandBuffer.commit()
                    commandBuffer.waitUntilCompleted()
                    
                    sourceTexture = newTexture.texture
                }
            }
            
            if let newTexture = canvas?.makeEmptyTexture(with: bounds.size),
               let blitCommandBuffer = canvas?.canvasManager?.renderer?.commandQueue.makeCommandBuffer() {
                blitCommandBuffer.label = "Crop Texture Buffer"
                
                let sourceRegion = MTLRegionMake2D(Int(bounds.origin.x), Int(bounds.origin.y), Int(bounds.size.width), Int(bounds.size.height))
                let destOrigin = MTLOrigin(x: 0, y: 0, z: 0)
                
                let blitEncoder = blitCommandBuffer.makeBlitCommandEncoder()
                blitEncoder?.label = "Crop Texture Encoder"
                blitEncoder?.copy(from: sourceTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: sourceRegion.origin, sourceSize: sourceRegion.size, to: newTexture.texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: destOrigin)
                blitEncoder?.endEncoding()
                blitCommandBuffer.commit()
                blitCommandBuffer.waitUntilCompleted()
                
                let mergedElement = Chartlet(textureID: newTexture.id)
                mergedElement.subtractive = subtractive
                mergedElement.printer = canvas?.printer
                mergedElement.smartObject = smart
                mergedElement.size = CGSize(width: newTexture.texture.width, height: newTexture.texture.height) / (canvas?.contentScaleFactor ?? 2.0)
                mergedElement.center = bounds.center / (canvas?.contentScaleFactor ?? 2.0)
                
                return mergedElement
            }
            
        }
        
//        print("Failed to trim texture")
        
        return nil
    }
    
    func registerTransform(element: CanvasElement,
                           initialPosition: CGPoint,
                           initialSize: CGSize,
                           initialRotation: CGFloat,
                           position: CGPoint,
                           size: CGSize,
                           rotation: CGFloat) {
        guard let canvas, let canvasManager = canvas.canvasManager else { return }

        let transformCommand = TransformElementCommand(canvasManager: canvasManager, element: element, newCenter: position, newSize: size, newRotation: rotation, currentCenter: initialPosition, currentSize: initialSize, currentRotation: initialRotation)
        commandManager.executeCommand(transformCommand)
        canvas.redraw(final: true)
    }
    
    var canRedo: Bool {
        return commandManager.canRedo
    }
    
    var canUndo: Bool {
        return commandManager.canUndo
    }
    
    func undo() {
        finishCurrentElement()
        
        commandManager.undo()
        
        canvas?.redrawLayers()
        
        observers.dataDidUndo(self)
    }
    
    func redo() {
        finishCurrentElement()
        
        commandManager.redo()
        
        canvas?.redrawLayers()
        
        observers.dataDidRedo(self)
    }
    
    // MARK: - Observers
    var observers = DataObserverPool()
    
    // add an observer to observe data changes, observers are not retained
    func addObserver(_ observer: DataObserver) {
        // pure nil objects
        observers.clean()
        observers.addObserver(observer)
    }
}
