//
//  InteractiveOverlayView.swift
//  MusePro
//
//  Created by Omer Karisman on 29.12.23.
//
import SwiftUI

class InteractiveOverlayModel: ObservableObject {
    static let shared = InteractiveOverlayModel()
    weak var canvasManager: CanvasManager?
    
    @Published var position = CGPoint(x: 200, y: 200)
    @Published var size = CGSize(width: 150, height: 150)
    @Published var rotation: CGFloat = 0
    
    @Published var initialPosition = CGPoint(x: 200, y: 200)
    @Published var initialSize = CGSize(width: 150, height: 150)
    @Published var initialRotation: CGFloat = 0
    @Published var inset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    func setInitial(position: CGPoint, size: CGSize, rotation: CGFloat) {
        self.position = position
        self.initialPosition = position
        self.size = size
        self.initialSize = size
        
        self.rotation = rotation
        self.initialRotation = rotation
    }
    
    func setInitialToCurrent() {
        canvasManager?.registerTransformAction(
            initialPosition: self.initialPosition,
            initialSize: self.initialSize,
            initialRotation: self.initialRotation,
            position: self.position,
            size: self.size,
            rotation: self.rotation
        )
        self.initialPosition = self.position
        self.initialSize = self.size
        self.initialRotation = self.rotation
    }
    
    func angleBetweenPoints(centerPoint: CGPoint, movingPoint: CGPoint) -> CGFloat {
        let deltaX = movingPoint.x - centerPoint.x
        let deltaY = movingPoint.y - centerPoint.y
        let angle = atan2(deltaY, deltaX)
        return angle + 3/2 * .pi
    }
    
    func transformDelta(delta: CGSize) -> CGSize {
        let radians = -rotation
        let dx = delta.width * cos(radians) - delta.height * sin(radians)
        let dy = delta.width * sin(radians) + delta.height * cos(radians)
        return CGSize(width: dx, height: dy)
    }
    
    func updateSize(size: CGSize) {
        var newSize = size
        newSize.width = newSize.width > 20 ? newSize.width : 20
        newSize.height = newSize.height > 20 ? newSize.height : 20
        self.size = newSize
    }
    
    func updateSizeWithPinch(size: CGSize) {
        updateSize(size: size)
    }
    
    func update() {
        canvasManager?.updateElement(position: position, size: size, rotation: rotation)
    }
}
struct InteractiveOverlayView: View {
    @ObservedObject var model = InteractiveOverlayModel.shared
    @ObservedObject var canvasManager: CanvasManager
    @State var phase = 0.0

    var body: some View {
      
        ZStack {
//            if updater {
//                Rectangle()
//                    .fill(.clear)
//            }
            if canvasManager.currentMode == .selection {
             
                Rectangle()
                    .strokeBorder(.black.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5], dashPhase: phase))
                    .overlay(alignment: .topLeading) {
                        ZStack {
                            Rectangle()
                                .strokeBorder(.white.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5, 5], dashPhase: phase + 5))
                            Rectangle()
                                .fill(Color.controlBackground)
                                .frame(width: 1, height: 40)
                                .position(CGPoint(x: model.size.width / 2, y: model.size.height + 20))
                            SqControlPointView(iconName: "arrow.triangle.2.circlepath")
                                .position(CGPoint(x: model.size.width / 2, y: model.size.height + 40))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged ({ gesture in
                                            model.rotation = model.angleBetweenPoints(centerPoint: CGPoint(x: model.position.x , y: model.position.y ), movingPoint: gesture.location)
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                                
                                    
                            //Top-Left
                            ControlPointView(iconName: "arrow.up.left.and.arrow.down.right")
                                .position(CGPoint(x: 0, y: 0))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: -transformedDelta.width, height: -transformedDelta.height)
                                            let newSize = model.initialSize + delta
                                            model.position = model.initialPosition + gesture.translation / 2
                                            model.updateSize(size: newSize)
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                            //Top
                            ControlPointView(iconName: "arrow.up.left.and.arrow.down.right")
                                .position(CGPoint(x: model.size.width / 2, y: 0))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: 0, height: -transformedDelta.height)
                                            let newSize = model.initialSize + delta
                                            model.position = model.initialPosition + CGPoint(x: sin(-model.rotation) * transformedDelta.height, y: cos(-model.rotation) * transformedDelta.height) / 2
                                            model.updateSize(size: newSize)
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                            //Top-Right
                            ControlPointView(iconName: "arrow.down.left.and.arrow.up.right")
                                .position(CGPoint(x: model.size.width, y: 0))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: transformedDelta.width, height: -transformedDelta.height)
                                            let newSize = model.initialSize + delta
                                            model.position = model.initialPosition + gesture.translation / 2
                                            model.updateSize(size: newSize)
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                            //Right
                            ControlPointView(iconName: "arrow.up.left.and.arrow.down.right")
                                .position(CGPoint(x: model.size.width, y: model.size.height / 2))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: transformedDelta.width, height: 0)
                                            let newSize = model.initialSize + delta
                                            model.position = model.initialPosition + CGPoint(x: cos(model.rotation) * transformedDelta.width, y: sin(model.rotation) * transformedDelta.width) / 2
                                            model.updateSize(size: newSize)
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                            //Bottom-Right
                            ControlPointView(iconName: "arrow.up.left.and.arrow.down.right")
                                .position(CGPoint(x: model.size.width, y: model.size.height))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: transformedDelta.width, height: transformedDelta.height)
                                            let newSize = model.initialSize + delta
                                            model.updateSize(size: newSize)
                                            model.position = model.initialPosition + gesture.translation / 2
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                            //Bottom
                            ControlPointView(iconName: "arrow.up.left.and.arrow.down.right")
                                .position(CGPoint(x: model.size.width / 2, y: model.size.height))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: 0, height: transformedDelta.height)
                                            let newSize = model.initialSize + delta
                                            model.position = model.initialPosition + CGPoint(x: sin(-model.rotation) * transformedDelta.height, y: cos(-model.rotation) * transformedDelta.height) / 2
                                            model.updateSize(size: newSize)
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                            //Bottom-Left
                            ControlPointView(iconName: "arrow.down.left.and.arrow.up.right")
                                .position(CGPoint(x: 0, y: model.size.height))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: -transformedDelta.width, height: transformedDelta.height)
                                            let newSize = model.initialSize + delta
                                            model.updateSize(size: newSize)
                                            model.position = model.initialPosition + gesture.translation / 2
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                            //Left
                            ControlPointView(iconName: "arrow.up.left.and.arrow.down.right")
                                .position(CGPoint(x: 0, y: model.size.height / 2))
                                .gesture(
                                    DragGesture(coordinateSpace: .named("stack"))
                                        .onChanged({ gesture in
                                            let transformedDelta = model.transformDelta(delta: gesture.translation)
                                            let delta = CGSize(width: -transformedDelta.width, height: 0)
                                            let newSize = model.initialSize + delta
                                            model.position = model.initialPosition + CGPoint(x: cos(model.rotation) * transformedDelta.width, y: sin(model.rotation) * transformedDelta.width) / 2
                                            model.updateSize(size: newSize)
                                            model.update()
                                        })
                                        .onEnded({ gesture in
                                            model.setInitialToCurrent()
                                        })
                                )
                           
                        }
                        
                    }
                    .rotationEffect(Angle(radians: model.rotation))
                    .frame(width: model.size.width, height: model.size.height)
                    .position(x: model.position.x, y: model.position.y)
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            phase -= 10
                        }
                    }
//               
////                .background {
////                    RoundedRectangle(cornerRadius: 10)
////                        .fill(Color("ControlBackground"))
//                .position(x: (canvasManager.canvas?.size.width ?? 0) / 2 , y: (canvasManager.canvas?.size.height ?? 0) - 64)
            }
        }
        .coordinateSpace(name: "stack")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(x: model.inset.left, y: model.inset.top)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(coordinateSpace: .named("stack"))
                .onChanged({ gesture in
                    model.position = model.initialPosition + gesture.translation
                    model.update()
                })
                .onEnded({ gesture in
                    model.setInitialToCurrent()
                })
        )
        .simultaneousGesture(
            RotationGesture()
                .onChanged { value in
                    model.rotation = model.initialRotation + value.radians
                    model.update()
                }
                .onEnded { value in
                    model.setInitialToCurrent()
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    let newSize = CGSize(width: model.initialSize.width * value, height: model.initialSize.height * value)
                    model.updateSizeWithPinch(size: newSize)
                    model.update()
                }
                .onEnded { value in
                    model.setInitialToCurrent()
                }
        )
        .simultaneousGesture(
            SpatialTapGesture()
                .onEnded { value in
                    if let canvas = canvasManager.canvas {
                        var translatedPoint = value.location
                        translatedPoint.x = translatedPoint.x - model.inset.left
                        translatedPoint.y = translatedPoint.y - model.inset.top
                        if canvasManager.selectedElement != nil {
                            if translatedPoint.x > canvas.size.width || translatedPoint.y > canvas.size.height || translatedPoint.x < 0 || translatedPoint.y < 0 {
                                canvasManager.currentMode = .brush
                            } else {
                                return
                            }
                        }
//                        let collisionElement: CanvasElement? = canvas.data.element(at: translatedPoint)
//                        MetalCanvasViewModel.shared.selectedElement = collisionElement
                        canvasManager.currentMode = .brush
                    }
                }
        )
    }
}

//struct ControlPointView: View {
//    var body: some View {
//        Circle()
//            .frame(width: 20, height: 20)
//            .foregroundColor(Color.blue)
//    }
//}

struct ControlPointView: View {
    var iconName: String
    var body: some View {
        ZStack {
            Circle()
                .frame(width: 12, height: 12)
                .foregroundColor(Color.foreground)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2 )

            Circle()
                .frame(width: 8, height: 8)
                .foregroundColor(Color.controlBackground)
        }
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
        .hoverEffect()
    }
}

struct SqControlPointView: View {
    var iconName: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 12, height: 12)
                .foregroundColor(Color.foreground)
                .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1 )

            RoundedRectangle(cornerRadius: 2)
                .frame(width: 8, height: 8)
                .foregroundColor(Color.controlBackground)
        }
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
        .hoverEffect()

    }
}


struct InteractiveOverlayView_Previews: PreviewProvider {
    static var previews: some View {
//        InteractiveOverlayView()
        SqControlPointView(iconName: "")
    }
}
