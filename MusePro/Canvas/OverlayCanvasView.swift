//
//  MetalCanvasView.swift
//  MusePro
//
//  Created by Omer Karisman on 28.12.23.
//

import SwiftUI

struct OverlayCanvasView: UIViewRepresentable {
    @State var canvasManager: CanvasManager
    @Environment(\.safeAreaInsets) var safeAreaInsets
    var size: CGSize
    var opacity: Float
    var canvasFrame: CGRect
    
//    var imageFrame: CGRect
    var imageData: Data

    var interactiveOverlayView: UIHostingController<InteractiveOverlayView>
    var lassoOverlayView: UIHostingController<LassoView>

    //    weak var canvas: Canvas?
    
    init(canvasManager: CanvasManager, size: CGSize, canvasFrame: CGRect, opacity: Float, imageData: Data) {
        self.canvasManager = canvasManager
        self.size = size
        self.canvasFrame = canvasFrame
        self.interactiveOverlayView = UIHostingController(rootView: InteractiveOverlayView(canvasManager: canvasManager))
        self.lassoOverlayView = UIHostingController(rootView: LassoView(canvasManager: canvasManager))

        self.opacity = opacity
        self.imageData = imageData
        //        self.canvas = canvas
    }
    
    func makeUIView(context: Context) -> UIView {
        
        guard let canvas = canvasManager.canvas else { return UIView() }
        canvas.layer.opacity = opacity

        interactiveOverlayView.view.frame = canvas.frame
        interactiveOverlayView.view.backgroundColor = .clear
        
        lassoOverlayView.view.frame = canvas.frame
        lassoOverlayView.view.backgroundColor = .clear
        
        let containerView = PTUIView(frame: canvasFrame)
        containerView.frame = canvasFrame
        containerView.backgroundColor = .clear
        containerView.addSubview(canvas)

        let imageView = UIImageView(frame: canvasFrame)
        containerView.addSubview(imageView)
        
        let view = UIScrollView()
        view.delegate = context.coordinator
        view.minimumZoomScale = 0.25
        view.maximumZoomScale = 10
        view.contentSize = CGSize(width: canvasFrame.width, height: canvasFrame.height)
        
        view.delaysContentTouches = false
        view.panGestureRecognizer.minimumNumberOfTouches = 2
        view.panGestureRecognizer.delaysTouchesBegan = false
        view.panGestureRecognizer.isEnabled = false
        view.pinchGestureRecognizer?.isEnabled = true
        view.contentInsetAdjustmentBehavior = .never

        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(sender:)))
        doubleTapGestureRecognizer.numberOfTouchesRequired = 2
        
        view.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let tripleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTripleTap(sender:)))
        tripleTapGestureRecognizer.numberOfTouchesRequired = 3
        
        view.addGestureRecognizer(tripleTapGestureRecognizer)
        
        let quadrupleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleQuadrupleTap(sender:)))
        quadrupleTapGestureRecognizer.numberOfTouchesRequired = 4
        
        view.addGestureRecognizer(quadrupleTapGestureRecognizer)
        
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = .clear
        view.addSubview(containerView)
        
        let insets = UIEdgeInsets(
            top: max(0, (size.height - canvas.frame.height) / 2),
            left: max(0, (size.width - canvas.frame.width) / 2),
            bottom: 0,
            right: 0
        )
        view.contentInset = insets
        
        return view
    }
    
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = uiView as? UIScrollView, let container = scrollView.subviews.first, let canvas = container.subviews.first(where: { $0 is MTKCanvas }) as? MTKCanvas {
                
                canvas.layer.opacity = opacity

                //            if UIDevice.isIPhone {
                if !context.coordinator.setInitialZoomScale, scrollView.bounds.size.width > 0, scrollView.bounds.size.height > 0 {
                    context.coordinator.setInitialZoomScale = true
                    let zoomScale = min(min(scrollView.bounds.size.width / container.frame.size.width, scrollView.bounds.size.height / container.frame.size.height) * 0.9, 1);
                    scrollView.zoomScale = zoomScale
                }
                //            }
                
                if canvasManager.currentMode != context.coordinator.cachedMode {
                    context.coordinator.cachedMode = canvasManager.currentMode
                    
                    container.subviews.forEach { view in
                        if type(of: view) == _UIHostingView<InteractiveOverlayView>.self ||
                            type(of: view) == _UIHostingView<LassoView>.self
                        {
                            view.removeFromSuperview()
                        }
                    }
                    
                    if canvasManager.currentMode == .selection {
                        interactiveOverlayView.view.backgroundColor = .clear
                        if container.subviews.first(where: { type(of:$0) == _UIHostingView<InteractiveOverlayView>.self }) == nil {
                            container.addSubview(interactiveOverlayView.view)
                        }
                    } else if canvasManager.currentMode == .lasso {
                        lassoOverlayView.view.backgroundColor = .clear
                        if container.subviews.first(where: { type(of:$0) == _UIHostingView<LassoView>.self }) == nil {
                            container.addSubview(lassoOverlayView.view)
                        }
                    }
                }
                
                canvas.currentBrush.color = canvasManager.brushColor
                canvas.currentBrush.pointSize = canvasManager.brushPointSize
                canvas.currentBrush.opacity = canvasManager.brushOpacity
                
                var marginX = max(0, (size.width - container.frame.width) / 2)
                var marginY = max(0, (size.height - container.frame.height) / 2)
                var insets = UIEdgeInsets(
                    top: marginY,
                    left: marginX,
                    bottom: 0,
                    right: 0
                )
                scrollView.contentInset = insets
                marginX = marginX / scrollView.zoomScale
                marginY = marginY / scrollView.zoomScale
                insets = UIEdgeInsets(
                    top: marginY,
                    left: marginX,
                    bottom: 0,
                    right: 0
                )
                InteractiveOverlayModel.shared.inset = insets
                let width = scrollView.bounds.width/scrollView.zoomScale
                let height = scrollView.bounds.height/scrollView.zoomScale
                if let iov = container.subviews.first(where: { type(of:$0) != MTKCanvas.self && type(of:$0) != UIImageView.self }) {
                    iov.frame = CGRect(x: -marginX, y: -marginY, width: width, height: height)
                }
                
                if let imageView = container.subviews.first(where: { $0 is UIImageView }) as? UIImageView , let image = UIImage(data: imageData) {
                    imageView.image = image
                }
                
                if let lassoView = container.subviews.first(where: { type(of:$0) == _UIHostingView<LassoView>.self }) {
                    lassoView.frame = canvas.frame
                }
                
            }
        }
    }
    
    static func deleteSubviewsAndRemoveSelf(view: UIView) {
        for subview in view.subviews {
            if !subview.subviews.isEmpty {
                deleteSubviewsAndRemoveSelf(view: subview)
            }
            subview.removeFromSuperview()
        }
        view.removeFromSuperview()
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        deleteSubviewsAndRemoveSelf(view: uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: OverlayCanvasView?
        var cachedMode: Mode = .brush
        var setInitialZoomScale: Bool = false
        init(_ parent: OverlayCanvasView) {
            self.parent = parent
        }
        
        @objc func handleDoubleTap(sender: UITapGestureRecognizer)
        {
            self.parent?.canvasManager.undo()
        }
        
        @objc func handleTripleTap(sender: UITapGestureRecognizer)
        {
            self.parent?.canvasManager.redo()
        }
        
        @objc func handleQuadrupleTap(sender: UITapGestureRecognizer)
        {
            self.parent?.canvasManager.canvas?.clearLayer()
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.subviews.first
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            if let container = scrollView.subviews.first {
                var marginX = max(0, (scrollView.bounds.width - container.frame.width) / 2)
                var marginY = max(0, (scrollView.bounds.height - container.frame.height) / 2)
                let insets = UIEdgeInsets(
                    top: marginY,
                    left: marginX,
                    bottom: 0,
                    right: 0
                )
                scrollView.contentInset = insets
                
               
                if let iov = container.subviews.first(where: { type(of:$0) != MTKCanvas.self && type(of:$0) != UIImageView.self }) {
               
                    let width = scrollView.bounds.width/scrollView.zoomScale
                    let height = scrollView.bounds.height/scrollView.zoomScale
                    marginX = marginX / scrollView.zoomScale
                    marginY = marginY / scrollView.zoomScale
                    iov.frame = CGRect(x: -marginX, y: -marginY, width: width, height: height)
                    let insets = UIEdgeInsets(
                        top: marginY,
                        left: marginX,
                        bottom: 0,
                        right: 0
                    )
                    InteractiveOverlayModel.shared.inset = insets
                    
                }
            }
        }
    }
}


struct InteractiveOverlayCanvas: View {
    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var liveImage: LiveImage

    @State var size: CGSize
    @State var opacity: Float
    
    var body: some View {
        GeometryReader { geo in
            let image = liveImage.currentImage ?? UIImage(color: .white, size: size)?.pngData()
            OverlayCanvasView(canvasManager: canvasManager, size: geo.size, canvasFrame: CGRect(x: 0, y: 0, width: size.width, height: size.height), opacity: opacity, imageData: image!)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
