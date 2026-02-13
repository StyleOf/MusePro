//
//  LayerManager.swift
//  MusePro
//
//  Created by Omer Karisman on 28.01.24.
//

import SwiftUI
import SwipeActions
import UniformTypeIdentifiers

struct LayersView: View {
    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var data: CanvasData

    @Environment(\.colorScheme) var colorScheme
    @State var contentSize: CGSize = .zero
    @State var refreshID: UUID = UUID()

    @State var draggedItem : Layer?

    var body: some View {
        ZStack {
            if !UIDevice.isIPhone {
                ShinyRect()
 
            }
            VStack {
                HStack {
                    Text("Layers")
                        .font(.title)
                        .foregroundStyle(Color.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    ControlButton(imageName: "plus") {
                        withAnimation {
                            canvasManager.data.createEmptyLayer()
                        }
                        refreshID = UUID()
                    }
                }
                    ScrollView (showsIndicators: false) {
                        LazyVStack {
                            ForEach((canvasManager.data.layers.reversed()), id: \.self) { layer in
//                                let layer = layers[index]
                                LayerView(canvasManager: canvasManager, refreshID: $refreshID, layer: layer)
                                .background {
                                    if canvasManager.data.currentLayerId == layer.id {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.canvasBackground.opacity(1.0))
                                    }
                                }
                                .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                                .hoverEffect()
                                .contentShape(Rectangle())
                                .onTapGesture(perform: {
                                    withAnimation {
                                        canvasManager.currentMode = .brush
                                        canvasManager.data.currentLayerId = layer.id
                                    }
                                    refreshID = UUID()
                                })
                               
                                .onDrag {
                                    self.draggedItem = layer
                                    return NSItemProvider(item: nil, typeIdentifier: layer.id.uuidString)
                                } preview: {
                                    LayerView(canvasManager: canvasManager, refreshID: $refreshID, layer: layer)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .onDrop(of: [UTType.layer], delegate: MyDropDelegate(item: layer, items: Binding(get: {
                                    canvasManager.data.layers
                                }, set: { newValue in
                                    canvasManager.data.layers = newValue
                                    canvasManager.canvas?.redrawLayers()
                                }), draggedItem: $draggedItem))
                                
                            }
                            BackgroundColorLayer(canvasManager: canvasManager)
                                .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                                .hoverEffect()
                        }
                        .overlay {
                            if !UIDevice.isIPhone {
                                GeometryReader { geo in
                                    Color.clear
                                        .onChange(of: refreshID, perform: { value in
                                            contentSize = geo.size
                                            
                                        })
                                        .onAppear {
                                            contentSize = geo.size
                                        }
                                    
                                }
                            }
                        }
                    }
                    .frame(maxHeight: UIDevice.isIPhone ? .infinity : contentSize.height)
                    .clipped()
                }
            
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
        .frame(maxHeight: UIDevice.isIPhone ? .infinity : contentSize.height + 100)
        .frame(minWidth: 200, idealWidth: 400, maxWidth: UIDevice.isIPhone ? .infinity : 400)
    }
}


struct MyDropDelegate : DropDelegate {

    let item : Layer
    @Binding var items : [Layer]
    @Binding var draggedItem : Layer?

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    func performDrop(info: DropInfo) -> Bool {
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = self.draggedItem else {
            return
        }

        if draggedItem != item {
            let from = items.firstIndex(of: draggedItem)!
            let to = items.firstIndex(of: item)!
            withAnimation() {
                self.items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

struct LayerView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var refreshID: UUID
    @State var state: SwipeState = .untouched
    @State var layer: Layer
    @State var opacity: Float = 1.0
    @State var oldOpacity: Float = 1.0
    @State var detailsExpanded: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.white.opacity(0.8))
//                        .stroke(Color.foreground, lineWidth: 1)
                        .frame(width: 80, height: 80)
                    if let image = layer.snapshotImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .id(canvasManager.layerRefreshTrigger)
                        
                    }
                    
                }
                .padding(.leading, 8)
                
                Text("Layer \(layer.index)")
                    .foregroundStyle(Color.controlForeground)
                Spacer()
                //            if layer.locked {
                //                Image(systemName: "lock")
                //                    .renderingMode(.template)
                //                    .foregroundColor(Color.foreground)
                //            } else {
                //                Image(systemName: "lock.open")
                //                    .renderingMode(.template)
                //                    .foregroundColor(Color.foreground)
                //            }
                if detailsExpanded {
                    Button {
                        withAnimation {
                            detailsExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.up")
     
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Color.foreground)
                    }
                    .transition(.push(from: .bottom))
                } else {
                    Button {
                        withAnimation {
                            detailsExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.down")
     
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(Color.foreground)
                    }
                    .transition(.push(from: .bottom))

                }
             
                if layer.hidden {
                    Button {
                        let changeLayerVisibilityCommand = ChangeLayerVisibilityCommand(layer: layer, oldVisibility: true, newVisibility: false)
                        CommandManager.shared.executeCommand(changeLayerVisibilityCommand)
                        canvasManager.canvas?.redraw(final: true)
                        canvasManager.saveLayerData(layer: layer)

                    } label: {
                        Image(systemName: "eye.slash")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color.foreground)
                            .padding()
                    }
                    
                } else {
                    Button {
                        let changeLayerVisibilityCommand = ChangeLayerVisibilityCommand(layer: layer, oldVisibility: false, newVisibility: true)
                        CommandManager.shared.executeCommand(changeLayerVisibilityCommand)
                        canvasManager.canvas?.redraw(final: true)
                        canvasManager.saveLayerData(layer: layer)

                    } label: {
                        Image(systemName: "eye")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Color.foreground)
                            .padding()
                    }
                }
            }
            .onAppear {
                opacity = layer.opacity
                oldOpacity = layer.opacity
            }
            .addSwipeAction(edge: .trailing, state: $state) {
                SwipeActionView(refreshID: $refreshID, canvasManager: canvasManager, layer: layer, state: $state)
            }
            if detailsExpanded {
                VStack {
                    HStack {
                        Text("Layer Opacity")
                            .foregroundStyle(Color.controlForeground)
                        Spacer()
                        Text(opacity, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(Color.controlForeground)
                    }
                    Slider(value: $opacity, in: 0.0...1.0) { editing in
                        if editing {
                            oldOpacity = opacity
                        } else {
                            let changeLayerOpacityCommand = ChangeLayerOpacityCommand(layer: layer, oldOpacity: oldOpacity, newOpacity: opacity)
                            CommandManager.shared.executeCommand(changeLayerOpacityCommand)
                            canvasManager.canvas?.redraw(final: true)
                            canvasManager.saveLayerData(layer: layer)
                        }
                    }
                    .onChange(of: opacity) { editing in
                        layer.opacity = opacity
                        canvasManager.canvas?.redraw()
                    }
                }
                .padding()

            }
        }
        .padding(.vertical, 8)
    }
}

struct SwipeActionView: View {
    @Binding var refreshID: UUID
    weak var canvasManager: CanvasManager?
    weak var layer: Layer?
    @Binding var state: SwipeState

    var body: some View {
//        Button {
//            layer.locked.toggle()
//            refreshID = UUID()
//            state = .swiped(UUID())
//        } label: {
//            if layer.locked {
//                Text("Unlock")
//            } else {
//                Text("Lock")
//            }
//        }
//        .tint(Color.foreground)
//        .padding()
//        .frame(maxHeight: .infinity)
//        .background {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.foreground.opacity(0.1))
//        }
//        .padding(.horizontal, 4)
        Button {
            if let canvasManager = canvasManager, let canvas = canvasManager.canvas, let layer {
                withAnimation {
                    let duplicateLayerCmd = DuplicateLayerCommand(canvasManager: canvasManager, originalLayer: layer)
                    CommandManager.shared.executeCommand(duplicateLayerCmd)
                    canvas.redrawLayers()
                }
            }
            refreshID = UUID()
            state = .swiped(UUID())
        } label: {
            Text("Duplicate")
        }
        .tint(Color.foreground)
        .padding()
        .frame(maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.foreground.opacity(0.1))
        }
        .padding(.horizontal, 4)

        Button {
            if let canvasManager, let layer {
                if canvasManager.data.layers.count < 2 {
                    let clearLayerCmd = ClearLayerCommand(layer: layer)
                    CommandManager.shared.executeCommand(clearLayerCmd)
                } else {
                    withAnimation {
                        let deleteLayerCmd = DeleteLayerCommand(canvasManager: canvasManager, layerToDelete: layer)
                        CommandManager.shared.executeCommand(deleteLayerCmd)
                    }
                }
                canvasManager.canvas?.redrawLayers()
            }
            refreshID = UUID()
            state = .swiped(UUID())
        } label: {
            if let canvasManager {
                if canvasManager.data.layers.count < 2 {
                    Text("Clear")
                    
                } else {
                    Text("Delete")
                    
                }
            }
        }
        .tint(Color.foreground)
        .padding()
        .frame(maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.opacity(0.8))
        }
    }
}

struct BackgroundColorLayer: View {
    weak var canvasManager: CanvasManager?
    weak var controlsViewModel = ControlsViewModel.shared
    @State var showColorPicker = false
    @State var colorTarget: ColorTarget = .background
    @State var pickedColor: Color = .foreground
    @State var previousColor: UIColor = .foreground

    var body: some View {
        Button {
            showColorPicker = true
            previousColor = canvasManager?.backgroundColor ?? .white
        } label: {
            HStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(canvasManager?.backgroundColor ?? .white))
                    .frame(width: 80, height: 60)
                Text("Background Color")
                    .foregroundStyle(Color.foreground)
                Spacer()
            }
        }
        .padding(8)
        .popover(isPresented: $showColorPicker, content: {
            MuseColors(onColorChanged: { color in
                canvasManager?.backgroundColor = UIColor(color)
            }, onEyedropperSelected: {
                controlsViewModel?.hideColorPicker()
                controlsViewModel?.hideLayerManager()
                controlsViewModel?.showEyeDropper(target: .backgroundColor)
            }, onClose: {
                showColorPicker = false
            }, primaryColor: Color(uiColor: canvasManager!.backgroundColor))
                .frame(minWidth: 320, minHeight: 550)
        })
        .onChange(of: showColorPicker) { _ in
            if !showColorPicker {
                guard let canvasManager else { return }
                if showColorPicker == false {
                    let changeBackgroundColorCommand = ChangeBackgroundColorCommand(canvasManager: canvasManager, oldBackgroundColor: previousColor, newBackgroundColor: UIColor(pickedColor))
                    CommandManager.shared.executeCommand(changeBackgroundColorCommand)
                    canvasManager.document.backgroundColor = UIColor(pickedColor).toMLColor()
                    canvasManager.document.saveMetadata()
                }
            }
        }
    }
}
