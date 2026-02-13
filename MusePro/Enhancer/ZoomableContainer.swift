//
//  ZoomableContainer.swift
//  Muse Pro
//
//  Created by Omer Karisman on 20.02.24.
//

//  ZoomableContainer.swift

import SwiftUI

fileprivate let maxAllowedScale = 4.0

struct ZoomableContainer<Content: View>: View {
    let content: Content

    @Binding private var currentScale: CGFloat
    @Binding private var currentOffset: CGPoint
    @State private var tapLocation: CGPoint = .zero
    
    var didScroll: (_ contentOffset: CGPoint) -> Void
    var didZoom: (_ zoomScale: CGFloat) -> Void

    init(@ViewBuilder content: () -> Content, didScroll: @escaping (_ contentOffset: CGPoint) -> Void, didZoom: @escaping (_ zoomScale: CGFloat) -> Void, scale: Binding<CGFloat>, offset: Binding<CGPoint>) {
        self.content = content()
        self.didScroll = didScroll
        self.didZoom = didZoom
        _currentScale = scale
        _currentOffset = offset
    }

    func doubleTapAction(location: CGPoint) {
        tapLocation = location
        currentScale = currentScale == 1.0 ? maxAllowedScale : 1.0
    }

    var body: some View {
        ZoomableScrollView(scale: $currentScale, offset: $currentOffset, tapLocation: $tapLocation) {
            content
        }
//        .onTapGesture(count: 2, perform: doubleTapAction)
    }

    fileprivate struct ZoomableScrollView<Content: View>: UIViewRepresentable {
        private var content: Content
        @Binding private var currentScale: CGFloat
        @Binding private var currentOffset: CGPoint

        @Binding private var tapLocation: CGPoint

        init(scale: Binding<CGFloat>, offset: Binding<CGPoint>, tapLocation: Binding<CGPoint>, @ViewBuilder content: () -> Content) {
            _currentScale = scale
            _currentOffset = offset
            _tapLocation = tapLocation
            self.content = content()
        }

        func makeUIView(context: Context) -> UIScrollView {
            // Setup the UIScrollView
            let scrollView = UIScrollView()
            scrollView.delegate = context.coordinator // for viewForZooming(in:)
            scrollView.maximumZoomScale = maxAllowedScale
            scrollView.minimumZoomScale = 1
            scrollView.bouncesZoom = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.delaysContentTouches = false
            scrollView.clipsToBounds = false

            // Create a UIHostingController to hold our SwiftUI content
            let hostedView = context.coordinator.hostingController.view!
            hostedView.translatesAutoresizingMaskIntoConstraints = true
            hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostedView.frame = scrollView.bounds
            scrollView.addSubview(hostedView)

            return scrollView
        }

        func makeCoordinator() -> Coordinator {
            return Coordinator(hostingController: UIHostingController(rootView: content), scale: $currentScale, offset: $currentOffset)
        }

        func updateUIView(_ scrollView: UIScrollView, context: Context) {
//            DispatchQueue.main.async {
                
                // Update the hosting controller's SwiftUI content
                context.coordinator.hostingController.rootView = content
                
                scrollView.zoomScale = currentScale
                scrollView.contentOffset = currentOffset
                
                //            if scrollView.zoomScale > uiView.minimumZoomScale { // Scale out
                //                scrollView.setZoomScale(currentScale, animated: true)
                //            } else if tapLocation != .zero { // Scale in to a specific point
                //                scrollView.zoom(to: zoomRect(for: scrollView, scale: scrollView.maximumZoomScale, center: tapLocation), animated: true)
                //                // Reset the location to prevent scaling to it in case of a negative scale (manual pinch)
                //                // Use the main thread to prevent unexpected behavior
                //                DispatchQueue.main.async { tapLocation = .zero }
                //            }
                
                assert(context.coordinator.hostingController.view.superview == scrollView)
//            }
        }

        // MARK: - Utils

        func zoomRect(for scrollView: UIScrollView, scale: CGFloat, center: CGPoint) -> CGRect {
            let scrollViewSize = scrollView.bounds.size

            let width = scrollViewSize.width / scale
            let height = scrollViewSize.height / scale
            let x = center.x - (width / 2.0)
            let y = center.y - (height / 2.0)

            return CGRect(x: x, y: y, width: width, height: height)
        }

        // MARK: - Coordinator

        class Coordinator: NSObject, UIScrollViewDelegate {
            var hostingController: UIHostingController<Content>
            @Binding var currentScale: CGFloat
            @Binding var currentOffset: CGPoint

            init(hostingController: UIHostingController<Content>, scale: Binding<CGFloat>, offset: Binding<CGPoint>) {
                self.hostingController = hostingController
                _currentScale = scale
                _currentOffset = offset
            }

            func viewForZooming(in scrollView: UIScrollView) -> UIView? {
                return hostingController.view
            }
            
            func scrollViewDidZoom(_ scrollView: UIScrollView) {
                currentScale = scrollView.zoomScale
            }
            func scrollViewDidScroll(_ scrollView: UIScrollView) {
                currentOffset = scrollView.contentOffset
            }

            func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//                currentScale = scale
            }
        }
    }
}
