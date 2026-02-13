//
//  CommandManager.swift
//  MusePro
//
//  Created by Omer Karisman on 30.01.24.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

class CommandManager {
    static let shared = CommandManager()
    
    var undoStack: [CanvasCommand] = []
    var redoStack: [CanvasCommand] = []

    func executeCommand(_ command: CanvasCommand) {
//        print("Command:", command.name)
        command.execute()
        undoStack.append(command)
        redoStack.removeAll()
    }

    func undo() {
        if let command = undoStack.popLast() {
//            print("Undoing \(command.name)")
            ToastManager.shared.showMessage(message: "Undo: \(command.name)", image: "arrow.uturn.left")
            command.undo()
            redoStack.append(command)
        }
    }

    func redo() {
        if let command = redoStack.popLast() {
//            print("Redoing \(command.name)")
            ToastManager.shared.showMessage(message: "Redo: \(command.name)", image: "arrow.uturn.right")
            command.execute()
            undoStack.append(command)
        }
    }
    
    func reset() {
        undoStack = []
        redoStack = []
    }
    
    var canRedo: Bool {
        return !redoStack.isEmpty
    }
    
    var canUndo: Bool {
        return !undoStack.isEmpty
    }
    
}

protocol CanvasCommand {
    var name: String { get set }
    func execute()
    func undo()
}

class AddElementCommand: CanvasCommand {
    var name = "Add Element"

    var layer: Layer
    var element: CanvasElement

    init(layer: Layer, element: CanvasElement) {
        self.layer = layer
        self.element = element
    }

    func execute() {
        element.index = layer.elements.count
        layer.elements.append(element)
    }

    func undo() {
        layer.elements.removeAll { 
            return $0.id == element.id
        }
    }
}

class RemoveElementCommand: CanvasCommand {
    var name = "Remove Element"

    var layer: Layer
    var element: CanvasElement
    var index: Int?

    init(layer: Layer, element: CanvasElement) {
        self.layer = layer
        self.element = element
    }

    func execute() {
        layer.elements.removeAll {
            return $0.id == element.id
        }
    }

    func undo() {
        layer.elements.append(element)
    }
}

class PrepareElementForTransformCommand: CanvasCommand {
    var name = "Prepare For Transform"

    var layer: Layer
    var originalElements: [CanvasElement]
    var transformedElement: CanvasElement

    init(layer: Layer, transformedElement: CanvasElement) {
        self.layer = layer
        self.originalElements = layer.elements
        self.transformedElement = transformedElement
    }

    func execute() {
        layer.elements = [transformedElement]
    }

    func undo() {
        layer.elements = originalElements
    }
}
//
//class PrepareElementForTransformWithMaskCommand: CanvasCommand {
//    weak var canvasManager: CanvasManager?
//
//    var name = "Copy Lasso Selection"
//
//    var duplicateLayer: Layer
//    var originalElements: [CanvasElement]
//
//    init(canvasManager: CanvasManager, transformedElement: CanvasElement) {
//        self.canvasManager = canvasManager
//        self.duplicateLayer = Layer(index: canvasManager.data.layers.count) // Or any other method to duplicate
//        duplicateLayer.elements = [transformedElement]
//    }
//
//    func execute() {
//        canvasManager?.data.layers.append(duplicateLayer)
//        canvasManager?.data.currentLayerId = duplicateLayer.id
//    }
//
//    func undo() {
//        if let layers = canvasManager?.data.layers {
//            for i in 0..<layers.count {
//                if layers[i].id == duplicateLayer.id {
//                    canvasManager?.data.layers.remove(at: i)
//                }
//            }
//        }
//    }
//}

class PrepareElementForTransformWithMaskCommand: CanvasCommand {
    weak var canvasManager: CanvasManager?

    var name = "Copy Lasso Selection"

    var layer: Layer
    var newLayer: Layer?
//    var duplicateLayer: Layer
    var originalElements: [CanvasElement]
    var transformedElement: CanvasElement
    
    init(canvasManager: CanvasManager, layer: Layer, toNewLayer: Bool = false, transformedElement: CanvasElement) {
        self.canvasManager = canvasManager
        self.layer = layer
        self.newLayer = toNewLayer ? canvasManager.data.createLayer() : nil
        self.originalElements = layer.elements
//        self.duplicateLayer = Layer(index: canvasManager.data.layers.count)
        self.transformedElement = transformedElement
//        duplicateLayer.elements = [transformedElement]
    }

    func execute() {
        
        if let newLayer {
            newLayer.elements = [transformedElement]
            canvasManager?.data.layers.append(newLayer)
            canvasManager?.data.currentLayerId = newLayer.id
        } else {
            layer.elements.append(transformedElement)
        }
    }

    func undo() {
        layer.elements = originalElements
        if let newLayer {
            if let layers = canvasManager?.data.layers {
                for i in 0..<layers.count {
                    if layers[i].id == newLayer.id {
                        canvasManager?.data.layers.remove(at: i)
                    }
                }
            }
        }
    }
}

class PrepareElementForTransformWithMaskAndCutCommand: CanvasCommand {
    weak var canvasManager: CanvasManager?

    var name = "Cut Lasso Selection"

    var layer: Layer
    var newLayer: Layer?
//    var duplicateLayer: Layer
    var originalElements: [CanvasElement]
    var cutElement: CanvasElement
    var transformedElement: CanvasElement
    
    init(canvasManager: CanvasManager, layer: Layer, toNewLayer: Bool = false, cutElement: CanvasElement, transformedElement: CanvasElement) {
        self.canvasManager = canvasManager
        self.layer = layer
        self.newLayer = toNewLayer ? canvasManager.data.createLayer() : nil
        self.originalElements = layer.elements
//        self.duplicateLayer = Layer(index: canvasManager.data.layers.count)
        self.cutElement = cutElement
        self.transformedElement = transformedElement
//        duplicateLayer.elements = [transformedElement]
    }

    func execute() {
//        canvasManager?.data.layers.append(duplicateLayer)
//        canvasManager?.data.currentLayerId = duplicateLayer.id
        if let newLayer {
            layer.elements = [cutElement]
            newLayer.elements = [transformedElement]
            canvasManager?.data.layers.append(newLayer)
            canvasManager?.data.currentLayerId = newLayer.id
        } else {
            layer.elements = [cutElement, transformedElement]
        }
    }

    func undo() {
        layer.elements = originalElements
        if let newLayer {
            if let layers = canvasManager?.data.layers {
                for i in 0..<layers.count {
                    if layers[i].id == newLayer.id {
                        canvasManager?.data.layers.remove(at: i)
                    }
                }
            }
        }
    }
}

class TransformElementCommand: CanvasCommand {
    weak var canvasManager: CanvasManager?
    var name = "Transform"
    var element: CanvasElement
    var previousCenter: CGPoint
    var previousSize: CGSize
    var previousRotation: CGFloat
    var newCenter: CGPoint
    var newSize: CGSize
    var newRotation: CGFloat

    init(canvasManager: CanvasManager, element: CanvasElement,
         newCenter: CGPoint, newSize: CGSize, newRotation: CGFloat,
         currentCenter: CGPoint, currentSize: CGSize, currentRotation: CGFloat) {
        self.canvasManager = canvasManager
        self.element = element
        self.newCenter = newCenter
        self.newSize = newSize
        self.newRotation = newRotation
        self.previousCenter = currentCenter
        self.previousSize = currentSize
        self.previousRotation = currentRotation
    }

    func execute() {
        if let layers = canvasManager?.data.layers {
            for i in 0..<layers.count {
                for j in 0..<layers[i].elements.count {
                    if layers[i].elements[j].id == element.id {
                        layers[i].elements[j].center = newCenter
                        layers[i].elements[j].size = newSize
                        layers[i].elements[j].rotation = newRotation
                        if let e = layers[i].elements[j] as? Chartlet {
                            e.vertex_buffer = nil
                        } else if let e = layers[i].elements[j] as? MLShape {
                            e.vertex_buffer = nil
                        }

                        return
                    }
                }
            }
        }
    }

    func undo() {
        // Revert to previous state
        if let layers = canvasManager?.data.layers {
            for i in 0..<layers.count {
                for j in 0..<layers[i].elements.count {
                    if layers[i].elements[j].id == element.id {
                        layers[i].elements[j].center = previousCenter
                        layers[i].elements[j].size = previousSize
                        layers[i].elements[j].rotation = previousRotation
                        if let e = layers[i].elements[j] as? Chartlet {
                            e.vertex_buffer = nil
                        } else if let e = layers[i].elements[j] as? MLShape {
                            e.vertex_buffer = nil
                        }
                        return
                    }
                }
            }
        }
    }
}


class RemoveBackgroundCommand: CanvasCommand {
    weak var canvasManager: CanvasManager?
    var name = "Remove Background"
    var element: CanvasElement
    var previousTexture: String
    var newTexture: String

    init(canvasManager: CanvasManager, element: CanvasElement,
         previousTexture: String, newTexture: String) {
        self.canvasManager = canvasManager
        self.element = element
        self.previousTexture = previousTexture
        self.newTexture = newTexture
    }

    func execute() {
        if let layers = canvasManager?.data.layers {
            for i in 0..<layers.count {
                for j in 0..<layers[i].elements.count {
                    if layers[i].elements[j].id == element.id,let chartlet = layers[i].elements[j] as? Chartlet {
                        chartlet.textureID = newTexture
                    }
                }
            }
        }
    }

    func undo() {
        // Revert to previous state
        if let layers = canvasManager?.data.layers {
            for i in 0..<layers.count {
                for j in 0..<layers[i].elements.count {
                    if layers[i].elements[j].id == element.id,let chartlet = layers[i].elements[j] as? Chartlet {
                        chartlet.textureID = previousTexture
                    }
                }
            }
        }
    }
}


class CreateLayerCommand: CanvasCommand {
    var name = "New Layer"
    var modifyLayers: (([Layer]) -> Void)
    var newLayer: Layer
    var added: Bool = false

    init(modifyLayers: @escaping ([Layer]) -> Void, newLayer: Layer) {
        self.modifyLayers = modifyLayers
        self.newLayer = newLayer
    }

    func execute() {
        modifyLayers([newLayer])
        added = true
    }

    func undo() {
        if added {
            modifyLayers([])
            added = false
        }
    }
}


class DeleteLayerCommand: CanvasCommand {
    weak var canvasManager: CanvasManager?

    var name = "Delete Layer"
    var layerToDelete: Layer
    var deletedLayerIndex: Int?

    init(canvasManager: CanvasManager, layerToDelete: Layer) {
        self.canvasManager = canvasManager
        self.layerToDelete = layerToDelete
        self.deletedLayerIndex = canvasManager.data.layers.firstIndex(where: { $0.id == layerToDelete.id })
    }

    func execute() {
        if let layers = canvasManager?.data.layers {
            for i in 0..<layers.count {
                if layers[i].id == layerToDelete.id {
                    canvasManager?.data.layers.remove(at: i)
                }
            }
        }
    }

    func undo() {
        if let index = deletedLayerIndex {
            canvasManager?.data.layers.insert(layerToDelete, at: index)
        }
    }
}

class DuplicateLayerCommand: CanvasCommand {
    weak var canvasManager: CanvasManager?

    var name = "Duplicate Layer"
    var originalLayer: Layer
    var duplicateLayer: Layer

    init(canvasManager: CanvasManager, originalLayer: Layer) {
        self.canvasManager = canvasManager
        self.originalLayer = originalLayer
        self.duplicateLayer = Layer(index: canvasManager.data.layers.count) // Or any other method to duplicate
        duplicateLayer.elements = originalLayer.elements
    }

    func execute() {
        canvasManager?.data.layers.append(duplicateLayer)
        canvasManager?.data.currentLayerId = duplicateLayer.id
    }

    func undo() {
        if let layers = canvasManager?.data.layers {
            for i in 0..<layers.count {
                if layers[i].id == duplicateLayer.id {
                    canvasManager?.data.layers.remove(at: i)
                }
            }
        }
    }
}

class ClearLayerCommand: CanvasCommand {
    var name = "Clear Layer"

    weak var layer: Layer?
    var originalElements: [CanvasElement]

    init(layer: Layer) {
        self.layer = layer
        self.originalElements = layer.elements
    }

    func execute() {
        layer?.elements.removeAll()
    }

    func undo() {
        layer?.elements = originalElements
    }
}

class ChangeLayerOpacityCommand: CanvasCommand {
    var name = "Change Layer Opacity"
    weak var layer: Layer?
    var oldOpacity: Float
    var newOpacity: Float

    init(layer: Layer? = nil, oldOpacity: Float, newOpacity: Float) {
        self.layer = layer
        self.oldOpacity = oldOpacity
        self.newOpacity = newOpacity
    }
    
    func execute() {
        layer?.opacity = newOpacity
    }

    func undo() {
        layer?.opacity = oldOpacity
    }
}

class ChangeLayerVisibilityCommand: CanvasCommand {
    var name = "Change Layer Visibility"
    weak var layer: Layer?
    var oldVisibility: Bool
    var newVisibility: Bool

    init(layer: Layer? = nil, oldVisibility: Bool, newVisibility: Bool) {
        self.layer = layer
        self.oldVisibility = oldVisibility
        self.newVisibility = newVisibility
    }
    
    func execute() {
        layer?.hidden = newVisibility
    }

    func undo() {
        layer?.hidden = oldVisibility
    }
}

class UpdateSeedCommand: CanvasCommand {
    weak var liveImage: LiveImage?

    var name = "Change Seed"
    var oldSeed: Int
    var newSeed: Int

    init(liveImage: LiveImage, newSeed: Int) {
        self.liveImage = liveImage
        self.oldSeed = liveImage.seed
        self.newSeed = newSeed
    }

    func execute() {
        liveImage?.seed = newSeed
    }

    func undo() {
        liveImage?.seed = oldSeed
    }
}

class UpdatePromptCommand: CanvasCommand {
    weak var liveImage: LiveImage?

    var name = "Change Prompt"
    var oldPrompt: String
    var newPrompt: String

    init(liveImage: LiveImage, oldPrompt: String, newPrompt: String) {
        self.liveImage = liveImage
        self.oldPrompt = oldPrompt
        self.newPrompt = newPrompt
    }

    func execute() {
        liveImage?.prompt = newPrompt
    }

    func undo() {
        liveImage?.prompt = oldPrompt
    }
}

class UpdateStrengthCommand: CanvasCommand {
    weak var liveImage: LiveImage?

    var name = "Change AI Strength"
    var oldStrength: Float
    var newStrength: Float

    init(liveImage: LiveImage, oldStrength: Float, newStrength: Float) {
        self.liveImage = liveImage
        self.oldStrength = oldStrength
        self.newStrength = newStrength
    }

    func execute() {
        liveImage?.strength = newStrength
    }

    func undo() {
        liveImage?.strength = oldStrength
    }
}

class UpdateCfgCommand: CanvasCommand {
    weak var liveImage: LiveImage?

    var name = "Change CFG"
    var oldCfg: Float
    var newCfg: Float

    init(liveImage: LiveImage, newCfg: Float) {
        self.liveImage = liveImage
        self.oldCfg = liveImage.cfg
        self.newCfg = newCfg
    }

    func execute() {
        liveImage?.cfg = newCfg
    }

    func undo() {
        liveImage?.cfg = oldCfg
    }
}

class ChangeBackgroundColorCommand: CanvasCommand {
    weak var canvasManager: CanvasManager?

    var name = "Change Background Color"
    var oldBackgroundColor: UIColor
    var newBackgroundColor: UIColor
    
    init(canvasManager: CanvasManager, oldBackgroundColor: UIColor, newBackgroundColor: UIColor) {
        self.canvasManager = canvasManager
        self.oldBackgroundColor = oldBackgroundColor
        self.newBackgroundColor = newBackgroundColor
    }
    
    func execute() {
        canvasManager?.backgroundColor = newBackgroundColor
    }

    func undo() {
        canvasManager?.backgroundColor = oldBackgroundColor
    }
}
