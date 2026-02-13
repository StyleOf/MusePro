
import MetalKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import QuartzCore

internal let sharedDevice = MTLCreateSystemDefaultDevice()

class MTKCanvas: MTKView {
    
    weak var canvasManager: CanvasManager?
    
    var defaultBrush: Brush!
    
    var printer: Printer!
    
    var colorPrinter: Printer!
    
//    var renderer: Renderer?
    
    var isPencilMode = false
        
    var size: CGSize {
        return drawableSize / contentScaleFactor
    }
    
    var actionObservers = ActionObserverPool()
    
    var currentBrush: Brush!
    
    func addObserver(_ observer: ActionObserver) {
        actionObservers.clean()
        actionObservers.addObserver(observer)
    }
    
    // setup gestures
    var paintingGesture: PaintingGestureRecognizer?
    var tapGesture: UITapGestureRecognizer?

    // MARK: - Setup
    
    func setup() {
        guard metalAvaliable else {
            print("<== Attention ==>")
            print("You are running on a Simulator, whitch is not supported by Metal")
            print("<== Attention ==>")
            return
        }
        
        device = sharedDevice

        isOpaque = false

        depthStencilPixelFormat = .depth32Float_stencil8
       
        
        defaultBrush = Brush(name: "musepro.default", textureID: nil, grainTextureID: nil, target: self)
        currentBrush = defaultBrush
        
        printer = Printer(target: self)
        colorPrinter = Printer(target: self, isColor: true)
        
//        data = CanvasData(canvas: self)
        
    }
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        actionObservers.clean()

//        self.renderer = nil
//        self.data = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        canvasManager?.renderer?.setupTargetUniforms()
    }

    override var backgroundColor: UIColor? {
        didSet {
            clearColor = (backgroundColor ?? .black).toClearColor()
        }
    }
        

    @discardableResult func registerBrush<T: Brush>(name: String? = nil, from data: Data) throws -> T? {
        if let texture = try makeTexture(with: data) {
            let brush = T(name: name, textureID: texture.id, grainTextureID: nil, target: self)
            canvasManager?.data.registeredBrushes.append(brush)
            return brush
        } else {
            return nil
        }
    }
    
    @discardableResult func registerBrush<T: Brush>(name: String? = nil, from file: URL) throws -> T? {
        let data = try Data(contentsOf: file)
        return try registerBrush(name: name, from: data)
    }
    
    func registerBrush<T: Brush>(name: String? = nil, textureID: String? = nil, grainTextureID: String? = nil) throws -> T {
        let brush = T(name: name, textureID: textureID, grainTextureID: grainTextureID, target: self)
        canvasManager?.data.registeredBrushes.append(brush)
        return brush
    }
    
    func register<T: Brush>(brush: T) {
        brush.target = self
        canvasManager?.data.registeredBrushes.append(brush)
    }
    
  
    func resizeImage(_ image: UIImage, to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func findBrushBy(brush: PCBrush) -> Brush? {
        print("findBrushBy: starting for brush \(brush.name)")

        if let existing = canvasManager?.data.registeredBrushes.first(where: { $0.name == brush.name }) {
            return existing
        }

        guard let archiveURL = brush.archiveURL else {
            print("ERROR: archiveURL not set")
            return nil
        }

        // Shape
        guard let shapeURL = resolveAsset(
            name: "Shape.png",
            storedPath: brush.bundledShapePath,
            archiveURL: archiveURL
        ) else {
            print("ERROR: Could not resolve shape for brush \(brush.name)")
            return nil
        }

        guard let shapeTexture = loadTexture(from: shapeURL) else {
            print("ERROR: Shape texture failed for \(shapeURL.lastPathComponent)")
            return nil
        }

        // Grain (optional)
        var grainTextureID: String? = nil

        if let grainURL = resolveAsset(
            name: "Grain.png",
            storedPath: brush.bundledGrainPath,
            archiveURL: archiveURL
        ) {
            if let texture = loadTexture(from: grainURL) {
                grainTextureID = texture.id
            }
        }

        // Register brush
        return try? registerBrush(
            name: brush.name,
            textureID: shapeTexture.id,
            grainTextureID: grainTextureID
        )
    }
    
    private func loadTexture(from url: URL) -> MLTexture? {
        guard let img = UIImage(contentsOfFile: url.path),
              let data = img.pngData()
        else { return nil }

        return try? makePerformanceTexture(with: data)
    }
    
    private func resolveAsset(
        name: String,
        storedPath: String?,
        archiveURL: URL
    ) -> URL? {

        let fm = FileManager.default
        let fileName = (storedPath?.isEmpty ?? true) ? name : storedPath!

        // Try archive folder
        let primary = archiveURL.appendingPathComponent(fileName)
        if fm.fileExists(atPath: primary.path) {
            return primary
        }

        // Try fallback bundle path
        if let resources = Bundle.main.resourceURL?.appendingPathComponent("BrushResources") {
            let fallback = resources.appendingPathComponent(fileName)
            if fm.fileExists(atPath: fallback.path) {
                return fallback
            }
        }

        return nil
    }
    
    @discardableResult
    func makeTexture(with data: Data, id: String? = nil) throws -> MLTexture? {
        if let id = id, let exists = findTexture(by: id) {
            return exists
        }
        if let texture = try canvasManager?.renderer?.makeTexture(with: data, id: id) {
            canvasManager?.data.textures.append(texture)
            return texture
        } else {
            print("Error creating texture with data")
            return nil
        }
    }
    
    @discardableResult
    func makeEmptyTexture(with size: CGSize, id: String? = nil) -> MLTexture? {
        if let id = id, let exists = findTexture(by: id) {
            return exists
        }
        if let texture = canvasManager?.renderer?.makeEmptyTexture(with: size, id: id) {
            canvasManager?.data.textures.append(texture)
            return texture
        } else {
            print("Error creating empty texture")
            return nil
        }
    }
    
    @discardableResult
    func makeEmptyComputeTexture(with size: CGSize, id: String? = nil) -> MLTexture? {
        if let id = id, let exists = findTexture(by: id) {
            return exists
        }
        if let texture = canvasManager?.renderer?.makeEmptyComputeTexture(with: size, id: id) {
            canvasManager?.data.textures.append(texture)
            return texture
        } else {
            print("Error creating empty texture")
            return nil
        }
    }
    
    @discardableResult
    func makePerformanceTexture(with data: Data, id: String? = nil) throws -> MLTexture? {
        if let id = id, let exists = findTexture(by: id) {
            return exists
        }
        if let texture = try canvasManager?.renderer?.makePerformanceTexture(with: data, id: id) {
            canvasManager?.data.textures.append(texture)
            return texture
        } else {
            print("Error creating perfroamnce texture with data")
            return nil
        }
    }
    
    @discardableResult
    func makeTexture(with color: MLColor) throws -> MTLTexture {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 1, height: 1, mipmapped: false)
        guard let texture = super.device!.makeTexture(descriptor: textureDescriptor) else { throw MLError.textureCreationError }
        
        let redComponent = UInt8(color.red * 255)
        let greenComponent = UInt8(color.green * 255)
        let blueComponent = UInt8(color.blue * 255)
        let alphaComponent = UInt8(color.alpha * 255)
        let colorBytes: [UInt8] = [blueComponent, greenComponent, redComponent, alphaComponent] // BGRA
        
        texture.replace(region: MTLRegionMake2D(0, 0, 1, 1), mipmapLevel: 0, withBytes: colorBytes, bytesPerRow: 4)
        
        return texture
    }
    
    func findTexture(by id: String) -> MLTexture? {
        return canvasManager?.data.textures.first { $0.id == id }
    }
        
//    func resetData(redraw: Bool = true) {
//        let oldData = data!
//        let newData = CanvasData(canvas: self)
//        newcanvasManager?.data.observers = canvasManager?.data.observers
//        data = newData
//        if redraw {
//            self.redraw()
//        }
//        canvasManager?.data.observers.data(oldData, didResetTo: newData)
//    }
    
    func undo() {
        canvasManager?.data.undo()
    }
    
    func redo() {
        canvasManager?.data.redo()
    }
    
    func clearLayer() {
        guard let canvasManager else { return }
        let clearLayerCmd = ClearLayerCommand(layer: canvasManager.data.currentLayer)
        CommandManager.shared.executeCommand(clearLayerCmd)
        redrawCurrentLayer()
    }
    
    var markedForRedraw = false
    var finalRedraw = false
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard 
            markedForRedraw,
              metalAvaliable,
            let renderer = canvasManager?.renderer
        else {
            return
        }
        
        if let drawable = renderer.currentTexture {
//            canvasManager?.data.clear.drawSelf(with: self, on: drawable)
//            renderer.commitCommands()

//            renderer.draw(label: "Clear", texture: nil, on: (renderer.temporaryTexture)!, clear: true)
//            renderer.commitCommands()
            
            canvasManager?.data.background.drawSelf(with: self, on: drawable)
            //        print("////////////Draw Call")
//            renderer.commitCommands()

            canvasManager?.data.layers.forEach { layer in
                //            print("Layer \(layer.index):")
                guard !layer.hidden else { return }
                    
                if layer.temporaryDrawable == nil {
//                    print("Creating Empty Layer Temporary Drawable")
                    layer.temporaryDrawable = renderer.makeEmptyMetalTexture(label: "Layer \(layer.index) temporary drawable")
                } else {
                    renderer.draw(label: "Clear", texture: nil, on: layer.temporaryDrawable!, clear: true)
//                    renderer.commitCommands()
                }
                
                if layer.drawable == nil {
//                    print("Creating Empty Layer Drawable")
                    layer.drawable = renderer.makeEmptyMetalTexture(label: "Layer \(layer.index) drawable")
                } else {
                    //                    print("Draw Layer Drawable to Layer Temporary Drawable")
//                    renderer.draw(label: "Clear", texture: nil, on: layer.drawable!, clear: true)
//                    renderer.commitCommands()
                    
                    renderer.draw(label: "Layer Drawable -> Layer Temp", texture: layer.drawable!, on: layer.temporaryDrawable!, subtractive: false, transparent: true)
//                    renderer.commitCommands()

                }
                
                if layer.id == canvasManager?.data.currentLayer.id {
                    if let selectedElement = canvasManager?.selectedElement {
                        //                        print("Drawing Layer Element To Layer Drawable")
                        selectedElement.drawSelf(with: self, on: layer.temporaryDrawable, subtractive: false, transparent: true)
//                        renderer.commitCommands()

                    } else if let rendererTemporaryTexture = renderer.temporaryTexture {
                        //                        print("Drawing Renderer Temporary Texture To Layer Drawable")
                        renderer.draw(label: "Renderer Temp -> Layer Drawable", texture: rendererTemporaryTexture, on: layer.temporaryDrawable!, subtractive: canvasManager?.currentMode == .eraser, transparent: true)
//                        renderer.commitCommands()

                    }
                }
                
                renderer.draw(label: "Layer Temp -> Renderer Current", texture: layer.temporaryDrawable!, on: drawable, transparent: true, opacity: layer.opacity)
                //                print("Drawing Layer Temporary To Drawable")
                //                layer.temporaryDrawable = nil
//                renderer.commitCommands()

            }
            
        }
    

        if let currentTexture = renderer.currentTexture, let drawable = currentDrawable?.texture {
            renderer.draw(label: "Renderer Current -> Canvas Drawable", texture: currentTexture, on: drawable)
            renderer.commitCommands(present: currentDrawable)

        }
        
//        print("Draw End////////////////")

        if let texture = renderer.currentTexture,
           let targetTexture = renderer.resizedTexture {
            renderer.resizeTexture(texture: texture, to: targetTexture, by: 1 / contentScaleFactor)
//            renderer.resizeAndBlurTexture(texture: texture, to: targetTexture, by: 1 / contentScaleFactor, sigma: ((canvasManager?.liveImage?.strength ?? 0) - 0.5) * 20)
        }
        
        markedForRedraw = false
        
        actionObservers.canvasDidRedraw(self, final: finalRedraw)
        
        if finalRedraw {
            finalRedraw = false
        }
    }
    
    func updateResized() {
        guard
              metalAvaliable,
            let renderer = canvasManager?.renderer
        else {
            return
        }
        
        if let texture = renderer.currentTexture,
           let targetTexture = renderer.resizedTexture {
            renderer.resizeTexture(texture: texture, to: targetTexture, by: 1 / contentScaleFactor)
//            renderer.resizeAndBlurTexture(texture: texture, to: targetTexture, by: 1 / contentScaleFactor, sigma: ((canvasManager?.liveImage?.strength ?? 0) - 0.5) * 20)
        }
    }
    
    func redraw(final: Bool = false) {
        finalRedraw = final
        markedForRedraw = true
        setNeedsDisplay()
    }
    
    func redrawCurrentLayer() {
        redrawLayers(layer: canvasManager?.data.currentLayer)
    }
    
    let layerSavingQueue = DispatchQueue(label: "LayerSavingQueue", qos: .userInitiated)

    func redrawLayers(layer: Layer? = nil) {
        guard
            metalAvaliable,
            canvasManager?.dataImportFinished == true,
            let renderer = canvasManager?.renderer
        else {
            return
        }
        
        renderer.draw(label: "Clear", texture: nil, on: (renderer.temporaryTexture)!, clear: true)
//        renderer.commitCommands()
        
        if let layer {
//            print("Redrawing Single Layer \(layer.index)")
            if layer.drawable == nil {
//                print("Creating new layer drawable for index", layer.index)
                layer.drawable = renderer.makeEmptyMetalTexture(label: "Layer \(layer.index) drawable")
            } else {
                renderer.draw(label: "Clear", texture: nil, on: layer.drawable!, clear: true)
//                renderer.commitCommands()
            }
//            print("Drawing layer \(layer.index) with \(layer.elements.count)")

            layer.elements.forEach { element in
                if canvasManager?.data.currentElement == nil || canvasManager?.data.currentElement?.id != element.id {
                    element.drawSelf(with: self, on: layer.drawable, subtractive: false, transparent: true)
//                    renderer.commitCommands()
                } else {
//                    print("Skipping element", element.id)
                }
            }
            
//            renderer.commitCommands()
            
            layerSavingQueue.async { [weak self] in
                if let snapshot = layer.drawable?.toData(context: renderer.context) {
                    layer.snapshot = snapshot
                    guard let strongSelf = self else { return }
                    strongSelf.canvasManager?.saveLayerData(layer: layer)
                }
            }
        } else {
//            print("Redrawing all layers")
            canvasManager?.data.layers.forEach { layer in
                if layer.drawable == nil {
//                    print("Creating new layer drawable for index", layer.index)
                    layer.drawable = renderer.makeEmptyMetalTexture(label: "Layer \(layer.index) drawable")
                } else {
                    renderer.draw(label: "Clear", texture: nil, on: layer.drawable!, clear: true)
//                    renderer.commitCommands()
                }
//                print("Drawing layer \(layer.index) with \(layer.elements.count) elements")
                layer.elements.forEach { element in
                    if canvasManager?.data.currentElement == nil || canvasManager?.data.currentElement?.id != element.id {
                        element.drawSelf(with: self, on: layer.drawable, subtractive: false, transparent: true)
//                        print("Drawing element", element.id, element.center)
//                        renderer.commitCommands()
                    } else {
//                        print("Skipping element", element.id)
                    }
                    
                }
                
            }
//            renderer.commitCommands()
            canvasManager?.data.layers.forEach { layer in
                layerSavingQueue.async { [weak self] in
                    if let snapshot = layer.drawable?.toData(context: renderer.context) {
                        layer.snapshot = snapshot
                        guard let strongSelf = self else { return }
                        strongSelf.canvasManager?.saveLayerData(layer: layer)
                    }
                }
            }
        }
        renderer.commitCommands()
        redraw(final: true)
    }
    
    func bufferCompletedHandler(_ buffer: MTLCommandBuffer) {
        self.actionObservers.canvasDidFinishRenderingChanges(self)
    }
    
    // MARK: - Rendering
    func render(brush: Brush, lines: [MLLine], isEnd: Bool = false) {
        guard lines.count > 0 else { return }
        let clear = canvasManager?.data.append(lines: lines, with: currentBrush) ?? false
        
        canvasManager?.renderer?.draw(label: "Clear", texture: nil, on: (canvasManager?.renderer?.temporaryTexture)!, clear: true)
//        renderer?.commitCommands(wait: true)
        
        if clear {
            canvasManager?.renderer?.draw(label: "Clear", texture: nil, on: (canvasManager?.renderer?.offscreenTexture)!, clear: true)
//            renderer?.commitCommands(wait: true)
        }
        
        LineStrip(lines: lines, brush: brush, textureOffset: canvasManager?.data.textureOffset, isEnd: isEnd)
            .drawSelf(with: self, on: canvasManager?.renderer?.temporaryTexture)

        canvasManager?.renderer?.commitCommands(wait: true)

        if isEnd {
            canvasManager?.data.finishCurrentElement()
        }
        
        redraw(final: isEnd)
    }
    
    func renderTap(brush: Brush, at point: CGPoint, to: CGPoint? = nil) {
        let lines = brush.makeLine(from: point, to: to ?? point)
        render(brush: brush, lines: lines, isEnd: true)
    }
    
    func renderChartlet(
        textureID: String
    ) -> Chartlet? {
        
        let chartlet = Chartlet(textureID: textureID)
        chartlet.printer = printer
        chartlet.smartObject = true
        
        canvasManager?.data.append(element: chartlet)
        return chartlet
    }
    
    func renderRectangle(
        color: MLColor
    ) -> MLRectangle? {
        
        let rectangle = MLRectangle(color: color)
        rectangle.printer = colorPrinter
        
        canvasManager?.data.append(element: rectangle)
        return rectangle
    }
    
    func renderTriangle(
        color: MLColor
    ) -> MLTriangle? {
        
        
        let triangle = MLTriangle(color: color)
        triangle.printer = colorPrinter
        
        canvasManager?.data.append(element: triangle)
        return triangle
    }
    
    func renderCircle(
        color: MLColor
    ) -> MLCircle? {
        
        let circle = MLCircle(color: color)
        circle.printer = colorPrinter
        
        canvasManager?.data.append(element: circle)
        return circle
    }
    
    
    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let canvasManager else { return }
        guard canvasManager.currentMode != .selection else { return }
        guard touches.count == 1 else { return }
        guard !canvasManager.data.currentLayer.hidden && !canvasManager.data.currentLayer.locked else { return } //TODO: alert user

//        let panSource: Set<UITouch> = {
//            if let coalesced = event?.coalescedTouches(for: touches.first!) {
//                return Set(coalesced)
//            } else {
//                return touches
//            }
//        }()

        guard let pan = firstAvaliablePan(from: touches) else { return }
        _ = currentBrush.renderBegan(from: pan, on: self)
                
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let canvasManager else { return }

        guard touches.count == 1 else { return }
        guard !canvasManager.data.currentLayer.hidden && !canvasManager.data.currentLayer.locked else { return } //TODO: alert user

        let panSource: Set<UITouch> = {
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                return Set(coalesced)
            } else {
                return touches
            }
        }()
//        let pans = availablePans(from: panSource)
//
//        for pan in pans.dropLast() {
//            _ = currentBrush.renderMoved(to: pan, on: self)
//        }

//
        guard let pan = firstAvaliablePan(from: panSource) else { return }
//
        _ = currentBrush.renderMoved(to: pan, on: self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let canvasManager else { return }

        guard touches.count == 1 else { return }
        guard !canvasManager.data.currentLayer.hidden && !canvasManager.data.currentLayer.locked else { return } //TODO: alert user

//        let panSource: Set<UITouch> = {
//            if let coalesced = event?.coalescedTouches(for: touches.first!) {
//                return Set(coalesced)
//            } else {
//                return touches
//            }
//        }()

        guard let pan = firstAvaliablePan(from: touches) else { return }

        currentBrush.renderEnded(at: pan, on: self)
    }
    
    func firstAvaliablePan(from touches: Set<UITouch>) -> Pan? {

        var touch: UITouch?
        if #available(iOS 9.1, *), isPencilMode {
            touch = touches.first { (t) -> Bool in
                return t.type == .pencil
            }
        } else {
            touch = touches.first
        }
        guard let t = touch else {
            return nil
        }
        return Pan(touch: t, on: self)
    }
    
    func availablePans(from touches: Set<UITouch>) -> [Pan] {
        return touches.compactMap { touch -> Pan? in
            // For iOS 9.1 and above, in pencil mode, only consider pencil touches
            if #available(iOS 9.1, *), isPencilMode {
                guard touch.type == .pencil else { return nil }
            }
            return Pan(touch: touch, on: self)
        }
    }
}


var metalAvaliable: Bool = {
    #if targetEnvironment(simulator)
    if #available(iOS 13.0, *) {
        return true
    } else {
        return false
    }
    #else
    return true
    #endif
}()
