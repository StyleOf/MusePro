//
//  Selection.swift
//  Muse Pro
//
//  Created by Omer Karisman on 22.03.24.
//

import SwiftUI

struct LassoView: View {
    @ObservedObject var canvasManager: CanvasManager
    
    @State private var path = Path()
    @State private var startPoint: CGPoint?
    
    @State private var phase: CGFloat = 0 // For the marching ants effect
    
    let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect() // Timer to animate the phase
    
    func getMask(path: Path, size: CGSize) -> CGImage? {
        let canvas =  VStack {
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
                context.fill(path, with: .color(.white))
                
            }
        }
        .frame(width: size.width, height: size.height)
        
        let imageRenderer = ImageRenderer(content: canvas)
        #if os(visionOS)
            imageRenderer.scale = 1
        #elseif os(iOS)
            imageRenderer.scale = UIScreen.main.scale
        #endif
        if let image = imageRenderer.cgImage {
            return image
        }
        
        return nil
    }
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                context.stroke(path, with: .color(.black.opacity(0.5)), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [5, 5], dashPhase: phase))
                context.stroke(path, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [5, 5], dashPhase: phase + 5))
            }
            .background(Color.white.opacity(0.001)) // Make sure the Canvas is hit-testable.
            .contentShape(Rectangle()) // Makes the entire area of the view participate in hit testing.
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ value in
                        if let startPoint = startPoint {
                            path.addLine(to: value.location)
                        } else {
                            path = Path()
                            self.startPoint = value.startLocation
                            path.move(to: value.startLocation)
                        }
                    })
                    .onEnded { _ in
                        path.closeSubpath()
                        self.startPoint = nil // Reset for the next gesture
                        canvasManager.currentMask = getMask(path: path, size: geo.size)
                    }
            )
            .onReceive(timer) { _ in
                phase -= 1 // Adjust the phase to animate the dash pattern
            }
        }
    }
}

struct ZebraPattern: View {
    var stripeWidth: CGFloat = 10.0
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let stripeWidth: CGFloat = 10
                var currentX: CGFloat = 0
                
                while currentX < geometry.size.width {
                    path.move(to: CGPoint(x: currentX, y: 0))
                    path.addLine(to: CGPoint(x: currentX, y: geometry.size.height))
                    currentX += stripeWidth * 2
                }
            }
            .stroke(style: StrokeStyle(lineWidth: stripeWidth, dash: [0], dashPhase: 0))
            .foregroundColor(Color.black.opacity(0.1))
        }
    }
}

struct MarchingAntsModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LassoOverlay(path: phase)
                    .animation(Animation.linear.repeatForever(autoreverses: false), value: phase)
                    .onAppear { phase -= 10 }
            )
    }
}

struct LassoOverlay: View {
    var path: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.addRect(geometry.frame(in: .local))
            }
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5], dashPhase: path))
            .foregroundColor(.black)
        }
    }
}

//struct SelectionView: View {
//    var body: some View {
//        LassoView()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .padding()// Adjust the frame as needed
//    }
//}
//
//#Preview {
//    SelectionView()
//}
