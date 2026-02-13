//
//  CanvasViewModel.swift
//  MusePro
//
//  Created by Omer Karisman on 28.12.23.
//

import SwiftUI
import Kingfisher
import PencilKit
import OpenAI
import UniformTypeIdentifiers

enum Mode {
    case brush
    case eraser
    case selection
    case lasso
}

enum Model: CaseIterable, Identifiable {
    case lcm
    case sdxl
//    case lightning
    var id: Self { self }
}

enum RenderMode {
    case fast
    case slow
}

class CanvasManager: ObservableObject, ActionObserver, DataObserver {
    weak var liveImage: LiveImage?
    let document: Document
    
    var defaultBrush: PCBrush?
    var brushes: [Brush] = [Brush]()
    var chartlets: [MLTexture] = [MLTexture]()
    
    var brush: Brush?
    var eraser: Eraser?
    
    @Published var isRightHanded: Bool {
        didSet {
            UserDefaults.standard.set(isRightHanded, forKey: "isRightHanded")
        }
    }
    
//    @Published var layers: [Layer] = [Layer]()
    
    init(liveImage: LiveImage, document: Document, canvas: MTKCanvas) {
//        print("init canvas manager")
        self.document = document
        self.liveImage = liveImage
        self.canvas = canvas
        do {
            renderer = try Renderer(with: canvas , bufferCompletedHandler: canvas.bufferCompletedHandler)
        } catch {
            print("Could not setup renderer!")
        }
        self.isRightHanded = UserDefaults.standard.boolOptional(forKey: "isRightHanded") ?? true
        self.data = CanvasData(canvas: canvas)
        InteractiveOverlayModel.shared.canvasManager = self
        
        self.canvas?.canvasManager = self
        self.canvas?.addObserver(self)
        
        if let brush = BrushManager.shared.defaultBrush {
            useTool(brush, for: .brush)
            useTool(brush, for: .eraser)
        }
    }    
   
    weak var canvas: MTKCanvas?
    var data: CanvasData
    var renderer: Renderer?
    
    @Published var overlayMode: Bool = false
    
    @Published var backgroundColor: UIColor = .white {
        didSet {
           setBackgroundColor()
        }
    }
    
    func setBackgroundColor() {
        if let canvas = canvas {
            data.background.color = backgroundColor.toMLColor()
            canvas.redraw()
        }
    }
    
    @Published var brushColor: UIColor = .black {
        didSet {
            document.brushColor = brushColor.toMLColor()
            brush?.color = brushColor
            data.finishCurrentElement()
        }
    }
    @Published var brushPointSize: CGFloat = 0.5 {
        didSet {
            document.brushSize = brushPointSize
            if currentMode == .brush {
                currentBrush?.pointSize = brushPointSize
            } else if currentMode == .eraser {
                currentBrush?.eraseSize = brushPointSize
            }
        }
    }
    @Published var brushOpacity: CGFloat = 0.95 {
        didSet {
            document.brushOpacity = brushOpacity
            if currentMode == .brush {
                currentBrush?.opacity = brushOpacity
            } else if currentMode == .eraser {
                currentBrush?.eraseOpacity = brushOpacity
            }
        }
    }
    @Published var brushHardness: CGFloat = 1
    
    @Published var currentBrush: Brush? {
        didSet {
            data.finishCurrentElement()
        }
    }
    
    @Published var currentEraser: Brush? {
        didSet {
            data.finishCurrentElement()
        }
    }
    
    @Published var currentMode: Mode = .brush {
        willSet {
            lastMode = currentMode
            if currentMode == .selection, let element = selectedElement {
                data.finishCurrentElement()
                selectedElement = nil
//                data.rasterizeElement(element: element) //TODO: Investigate
            }
            
            if currentMode == .lasso, newValue == .selection {
                
            } else {
                currentMask = nil
            }
            canvas?.redrawLayers()
        }
    }
    
    @Published var lastMode: Mode = .brush
    
    @Published var selectedElement: CanvasElement? {
        didSet {
            if let element = selectedElement as? Chartlet {
                InteractiveOverlayModel.shared.setInitial(position: element.center, size: element.size, rotation: -element.rotation)
            } else if let element = selectedElement as? MLShape {
                InteractiveOverlayModel.shared.setInitial(position: element.center, size: element.size, rotation: -element.rotation)
            }
        }
    }
    
    @Published var canUndo: Bool = false
    @Published var canRedo: Bool = false
    
    @State var inferenceTimer: Timer?
    
    var lastUpdateTime: TimeInterval = CACurrentMediaTime()
    var previousData: Data?
    let maxRenderFrames: Int = 30
    var currentRenderFrames: Int = 0
    var isLastRenderOfAction: Bool = false
    
    var dataImportFinished: Bool = false
    
    func importData() {
        guard let liveImage else { return }
        liveImage.currentImage = document.data
        backgroundColor = document.backgroundColor?.toUIColor() ?? .white
        if let brushName = document.brushName, let foundBrush = BrushManager.shared.findBrushByName(brushName) {
            canvas?.canvasManager?.useTool(foundBrush)
        }
        brushColor = document.brushColor?.toUIColor() ?? .black
        currentBrush?.color = brushColor
        
        if let brushOpacity = document.brushOpacity {
            self.brushOpacity = brushOpacity
        }
        if let brushPointSize = document.brushSize {
            self.brushPointSize = brushPointSize
        }
        
        if !document.layers.isEmpty {
            var layers: [Layer] = [Layer]()
                document.layers.forEach { layer in
                    if let texture = renderer?.makeEmptyMetalTexture(label: "Layer \(layer.index)") {
                        if let data = layer.data, data.count > 0 {
                            if let loadedTexture = try? renderer?.makeMetalTexture(with: data) {
                                // let _ = canvas?.renderer?.resizeTexture(texture: texture, to: emptyTexture, by: 1)
                                renderer?.draw(label: "Loaded Texture -> Empty Texture", texture: loadedTexture, on: texture, transparent: false)
                                renderer?.commitCommands(wait: true)
                            } else {
                                print("Can't make metal texture with layer data")
                            }
                        } else {
//                            print("Layer data nil")
                        }
                        
                        let importedLayer = Layer(index: layer.index, id: layer.id, blendMode: layer.blendMode ?? .add, opacity: layer.opacity ?? 1.0, hidden: layer.hidden ?? false, snapshot: layer.data, drawable: texture)
                        if let element = data.trimTextureToChartlet(texture: texture) {
                            importedLayer.elements.append(element)
                        }
                        layers.append(importedLayer)
                    }
      
                    
                }
            
            if layers.count > 0 {
                data.layers = layers
                data.currentLayer = layers.last!
            }
        }
        canvas?.redrawLayers()
        dataImportFinished = true
    }
    
    let drawingQueue = DispatchQueue(label: "DrawingQueue", qos: .userInitiated)
    
    @Published var nis: Float = 4 {
        didSet {
            liveImage?.lastNis = Int(nis)
            liveImage?.redraw()
        }
    }

    func draw(_ canvas: MTKCanvas, save: Bool = false, force: Bool = false) {
        guard let liveImage, liveImage.enabled else { return }
        
        inferenceTimer?.invalidate()
        //        return
        let currentTime = CACurrentMediaTime()
        let canPerformPro = UserManager.shared.canPerformPro(with: 1)
//        if !canPerformPro {
//            PaywallRequest.presentPaywall()
//        }
        let throttle = canPerformPro ? 1.0 / Double(((liveImage.model == .lcm ? 30 : 10) / nis)) : 1.0
//        let throttle = canPerformPro ? 1.0 / 6 : 1.0

        if !force, currentTime - lastUpdateTime < throttle {
            return
        }
        lastUpdateTime = currentTime
        drawingQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            var data: Data?
                        
            if liveImage.model == .lcm {
                data = strongSelf.renderer?.resizedTexture?.toJPEGData(context: strongSelf.renderer?.context)
            }
            
            if liveImage.model == .sdxl { //liveImage.model == .lightning ||
                data = strongSelf.renderer?.blurredTexture?.toJPEGData(context: strongSelf.renderer?.context)
            }
            
            if let data {
                if strongSelf.previousData != data || force {
                    strongSelf.previousData = data
//                    strongSelf.liveImage?.currentImage = data
                    strongSelf.liveImage?.generate(drawing: data, save: save, num_inference_steps: Int(strongSelf.nis))
                    //                self.draw(canvas)
                    //                if nis < 2 {
                    //                    inferenceTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { _ in
                    //                        self.draw(canvas, nis: nis * 2)
                    //                    }
                    //                }
                    
                } else {
                    if strongSelf.currentRenderFrames < strongSelf.maxRenderFrames {
                        strongSelf.currentRenderFrames += 1
                    } else {
                        strongSelf.currentRenderFrames = 0
                    }
                }
            }
        }
    }
    @Published var layerRefreshTrigger: UUID = UUID()

    func canvasDidRedraw(_ canvas: MTKCanvas, final: Bool) {
        guard let liveImage else { return }

        canUndo = data.canUndo
        canRedo = data.canRedo
        
        if final {
            isLastRenderOfAction = true
            liveImage.counter_alt += 1
        } else {
            isLastRenderOfAction = false
        }
        
        layerRefreshTrigger = UUID()
    }
    
    func canvasDidFinishRenderingChanges(_ canvas: MTKCanvas) {
        guard let liveImage else { return }

        if liveImage.renderMode == .fast || isLastRenderOfAction {
            draw(canvas, save: isLastRenderOfAction, force: isLastRenderOfAction)
            isLastRenderOfAction = false
        }
    }
    
    func undo() {
        currentMode = .brush
        canvas?.undo()
    }
    
    func redo() {
        currentMode = .brush
        canvas?.redo()
    }
    
    func enableSelectionMode() {
        guard self.currentMode != .selection else {
            return
        }
        
        self.currentMode = .selection

        if let canvas = canvas {
            if selectedElement == nil {
                if currentMask != nil {
                    cutLassoSelection()
                } else {
//                    if let e = data.currentLayer.elements.last as? Chartlet {
//                        print("Last element is chartlet but smart?", e.smartObject)
//                    }
                    if let e = data.currentLayer.elements.last as? Chartlet, e.smartObject {
                        selectedElement = e
                        data.currentElement = e
                        
                        canvas.redrawCurrentLayer()
                            
                    } else if let e = data.prepareForTransform(data.currentLayer) {
                        selectedElement = e
                        data.currentElement = e
                        
                        canvas.redrawCurrentLayer()
                        
                    }
                }
              
            } else {
                data.currentElement = selectedElement
                
                canvas.redrawCurrentLayer()
                
            }
        }
        
    }
    
//    func disableSelectionMode(to mode: Mode = .brush) {
//        guard self.currentMode == .selection else {
//            return
//        }
//
//        self.currentMode = mode
//    }
//    
//    func disableLassoMode(to mode: Mode = .brush) {
//        guard self.currentMode == .lasso else {
//            return
//        }
//     
//        self.currentMode = mode
//    }
//    
    var currentMask: CGImage? = nil
    
    func cutLassoSelection(newLayer: Bool = false) {
        if let canvas = canvas {
            if let currentMask, let e = data.prepareForTransformWithMaskAndCut(data.currentLayer, toNewLayer: newLayer, mask: UIImage(cgImage: currentMask)){
                selectedElement = e
                data.currentElement = e
                
                canvas.redrawCurrentLayer()
                enableSelectionMode()
            }
        }
    }
    
    func copyLassoSelection(newLayer: Bool = false) {
        if let canvas = canvas {
            if let currentMask, let e = data.prepareForTransformWithMask(data.currentLayer, toNewLayer: newLayer, mask: UIImage(cgImage: currentMask)){
                selectedElement = e
                data.currentElement = e
                
                canvas.redrawCurrentLayer()
                enableSelectionMode()
            }
        }
    }
    
    func registerTransformAction( initialPosition: CGPoint,
                                  initialSize: CGSize,
                                  initialRotation: CGFloat,
                                  position: CGPoint,
                                  size: CGSize,
                                  rotation: CGFloat) {
        if let canvas, let element = selectedElement {
            data.registerTransform( element: element,
                                           initialPosition: initialPosition,
                                           initialSize: initialSize,
                                           initialRotation: -initialRotation,
                                           position: position,
                                           size: size,
                                           rotation: -rotation)
        }
    }
    
    
    func updateElement(position: CGPoint, size: CGSize, rotation: CGFloat) {
        if let e = selectedElement as? Chartlet {
            e.center = position
            e.size = size
            e.rotation = -rotation
            e.vertex_buffer = nil
        } else if let e = selectedElement as? MLShape {
            e.center = position
            e.size = size
            e.rotation = -rotation
            e.vertex_buffer = nil
        }
        
        if let canvas = canvas {
            canvas.redraw()
        }
    }
    
    func registerBrush(with imageName: String) throws -> Brush? {
        if let canvas = canvas, let texture = try canvas.makeTexture(with: UIImage(named: imageName)!.pngData()!) {
            return try canvas.registerBrush(name: imageName, textureID: texture.id)
        } else {
            return nil
        }
    }
    
    func registerBrush(with image: UIImage, name: String) throws -> Brush? {
        if let canvas = canvas, let texture = try canvas.makeTexture(with: image.pngData()!) {
            return try canvas.registerBrush(name: name, textureID: texture.id)
        } else {
            return nil
        }
    }
    
    
    func useTool(_ pcBrush: PCBrush, for mode: Mode = .brush) {
        if let element = selectedElement {
            data.finishCurrentElement()
//            data.rasterizeElement(element: element)
        }
        
        selectedElement = nil
        canvas?.redrawLayers()
        
        if let brush = canvas?.findBrushBy(brush: pcBrush) {
            if pcBrush.shapeRotation == 1.0 {
                brush.rotation = .ahead
            } else {
                brush.rotation = .random(CGFloat(pcBrush.shapeRotation))
            }
            
            brush.shapeScatter = CGFloat(pcBrush.shapeScatter)
            brush.shapeRotation = CGFloat(pcBrush.shapeRotation)
            
            brush.plotSpacing = CGFloat(pcBrush.plotSpacing)
            brush.pointSize = CGFloat(pcBrush.paintSize)
            brush.maxPointSize = CGFloat(pcBrush.maxSize)
            brush.minPointSize = CGFloat(pcBrush.minSize)
            brush.eraseSize = CGFloat(pcBrush.eraseSize)
            brush.eraseOpacity = CGFloat(pcBrush.eraseOpacity)

            brush.opacity = CGFloat(pcBrush.paintOpacity)
            brush.maxOpacity = CGFloat(pcBrush.maxOpacity)
            brush.minOpacity = CGFloat(pcBrush.minOpacity)
            brush.jitter = CGFloat(pcBrush.plotJitter)
            
            brush.taperSize = CGFloat(pcBrush.taperSize)
            brush.taperStartLength = CGFloat(pcBrush.taperStartLength)
            brush.taperEndLength = CGFloat(pcBrush.taperEndLength)
            brush.fallOff = CGFloat(pcBrush.dynamicsFalloff)
            brush.pressureSize = CGFloat(pcBrush.dynamicsPressureSize)
            brush.pressureOpacity = CGFloat(pcBrush.dynamicsPressureOpacity)
            brush.pressureFlow = CGFloat(pcBrush.dynamicsPressureResponse)
            brush.pressureBleed = CGFloat(pcBrush.dynamicsPressureBleed)
            
            brush.grainDepth = CGFloat(pcBrush.grainDepth)
            brush.grainOrientation = pcBrush.grainOrientation
            brush.grainBlendMode = pcBrush.grainBlendMode
            brush.grainDepthJitter = CGFloat(pcBrush.grainDepthJitter)
            brush.grainDepthJitter = CGFloat(pcBrush.grainDepthJitter)
            brush.gradationTiltAngle = CGFloat(pcBrush.gradationTiltAngle)
            brush.textureMovement = CGFloat(pcBrush.textureMovement)
            brush.textureMovement = CGFloat(pcBrush.textureRotation)
            brush.textureZoom = CGFloat(pcBrush.textureZoom)
            brush.textureScale = CGFloat(pcBrush.textureScale)
            brush.textureFilter = pcBrush.textureFilter
            brush.textureContrast = CGFloat(pcBrush.textureContrast)
            brush.textureBrightness = CGFloat(pcBrush.textureBrightness)
            brush.textureApplication = pcBrush.textureApplication
            brush.textureInverted = pcBrush.textureInverted
            brush.textureOrientation = CGFloat(pcBrush.textureOrientation)
            brush.textureDepthTilt = pcBrush.textureDepthTilt
            brush.textureDepthTiltAngle = CGFloat(pcBrush.textureDepthTiltAngle)
            brush.textureFilterMode = CGFloat(pcBrush.textureFilterMode)
            brush.textureOffsetJitter = pcBrush.textureOffsetJitter
            brush.textureDepthTiltAngle = CGFloat(pcBrush.textureDepthTiltAngle)
            
            brush.use()
            
            if self.currentMode == .brush || mode == .brush  {
                currentBrush = brush
                withAnimation (.linear(duration: 0.1), {
                    document.brushName = brush.name
                    brushOpacity = brush.opacity
                    brushPointSize = brush.pointSize
                    brushColor = brush.color
                })
            }
            
            if self.currentMode == .eraser || mode == .eraser {
                currentEraser = brush
                withAnimation (.linear(duration: 0.1), {
                    brushOpacity = brush.eraseOpacity
                    brushPointSize = brush.eraseSize
                })
            }
            
        } else {
            print("Brush not found", pcBrush.name)
        }
    }
    
    func useLasso() {
        self.currentMode = .lasso
    }
    
    func useBrush() {
        currentMode = .brush
        if let currentBrush {
            withAnimation (.linear(duration: 0.1), {
                brushOpacity = currentBrush.opacity
                brushPointSize = currentBrush.pointSize
            })
            currentBrush.use()
            
        }
    }
    
    func useEraser() {
        currentMode = .eraser

        if let currentEraser {
            withAnimation (.linear(duration: 0.1), {
                brushOpacity = currentEraser.eraseOpacity
                brushPointSize = currentEraser.eraseSize
            })
            currentEraser.use()
        }
    }
    
    func usePreviousTool() {
        switch lastMode {
        case .brush:
            useBrush()
        case .eraser:
            useEraser()
        case .selection:
            usePointer()
        case .lasso:
            useLasso()
        }
    }
    
    func usePointer() {
        self.enableSelectionMode()
    }
    
    func addRectangle(color: MLColor) {
        currentMode = .brush
//        data.createEmptyLayer()

        if let canvas {
            let rectangle = canvas.renderRectangle(color: color)
            self.selectedElement = rectangle
            self.enableSelectionMode()
        }
    }
    
    func addTriangle(color: MLColor) {
        currentMode = .brush
//        data.createEmptyLayer()

        if let canvas {
            let triangle = canvas.renderTriangle(color: color)
            self.selectedElement = triangle
            self.enableSelectionMode()
        }
    }
    
    func addCircle(color: MLColor) {
        currentMode = .brush

        if let canvas {
            let circle = canvas.renderCircle(color: color)
            self.selectedElement = circle
            self.enableSelectionMode()
        }
    }
    
    
    func addImage(_ image: Data, select: Bool = true) {
        currentMode = .brush

        if let canvas {
            if let texture = try? canvas.makeTexture(with: image) {
//                data.createEmptyLayer()
                if let image = canvas.renderChartlet(textureID: texture.id) {
                    image.smartObject = true

                    let imageAspectRatio = CGFloat(texture.texture.width) / CGFloat(texture.texture.height)
                    
                    let canvasWidth = canvas.size.width
                    let canvasHeight = canvas.size.height
                    var newWidth: CGFloat
                    var newHeight: CGFloat
                    
                    if canvasWidth / canvasHeight > imageAspectRatio {
                        newHeight = canvasHeight
                        newWidth = canvasHeight * imageAspectRatio
                    } else {
                        newWidth = canvasWidth
                        newHeight = canvasWidth / imageAspectRatio
                    }
                    
                    //TODO: You can actually create the chartlets with a predetermined size to avoid redraw using buffer recreation or better yet just draw it manually on canvas somewhere, here?
                    image.size = CGSize(width: newWidth, height: newHeight)
                    image.center = CGPoint(x: canvasWidth / 2, y: canvasHeight / 2)
                    image.vertex_buffer = nil
                    
                    self.selectedElement = image
                    self.enableSelectionMode()
                }
            }
        }
    }
    
    func addImage(_ image: UIImage) {
        if let data = image.pngData() {
            addImage(data)
        }
    }
    
    func addTexture(texture: MLTexture) {
        currentMode = .brush
        if let canvas {
            if let image = canvas.renderChartlet(textureID: texture.id) {
                image.smartObject = true
                
                let imageAspectRatio = CGFloat(texture.texture.width) / CGFloat(texture.texture.height)
                
                let canvasWidth = canvas.size.width
                let canvasHeight = canvas.size.height
                var newWidth: CGFloat
                var newHeight: CGFloat
                
                if canvasWidth / canvasHeight > imageAspectRatio {
                    newHeight = canvasHeight
                    newWidth = canvasHeight * imageAspectRatio
                } else {
                    newWidth = canvasWidth
                    newHeight = canvasWidth / imageAspectRatio
                }
                
                //TODO: You can actually create the chartlets with a predetermined size to avoid redraw using buffer recreation or better yet just draw it manually on canvas somewhere, here?
                image.size = CGSize(width: newWidth, height: newHeight)
                image.center = CGPoint(x: canvasWidth / 2, y: canvasHeight / 2)
                image.vertex_buffer = nil
                
                self.selectedElement = image
                self.enableSelectionMode()
            }
        }
    }
    
    func copyAICanvas() {
        AnalyticsUtil.logEvent("musepro_copy_ai_image")

        guard let liveImage else { return }

        if let imageData = liveImage.currentImage {
            addImage(imageData)
        }
    }
    
    func saveImage() {
        AnalyticsUtil.logEvent("musepro_save_ai_image")

        guard let liveImage else { return }

        if let currentImage = liveImage.currentImage,
           let image = UIImage(data: currentImage) {
            let imageSaver = ImageSaver()
            imageSaver.writeToPhotoAlbum(image: image)
        }
    }
    
    func saveDrawing() {
        AnalyticsUtil.logEvent("musepro_save_drawing")

        if let currentImage = renderer?.currentTexture?.toData(context: renderer?.context),
           let image = UIImage(data: currentImage) {
            let imageSaver = ImageSaver()
            imageSaver.writeToPhotoAlbum(image: image)
        }
    }
    
    func saveLayerData(layer: Layer? = nil) {
        document.layers = data.layers.map({ layer in
            LayerData(id: layer.id, index: layer.index, blendMode: layer.blendMode, opacity: layer.opacity, hidden: layer.hidden, data: layer.snapshot)
        })
        
        document.saveLayerData(layer: layer)
    }
    
    func shuffleSeed() {
        guard let liveImage else { return }

        liveImage.shuffleSeed()
    }
}
