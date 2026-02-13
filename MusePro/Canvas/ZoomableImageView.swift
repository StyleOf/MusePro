//
//  ZoomableImageView.swift
//  MusePro
//
//  Created by Omer Karisman on 12.01.24.
//

import SwiftUI

struct ZoomableImageView: UIViewRepresentable {
    var size: CGSize
    var imageFrame: CGRect
    var imageData: Data
    
    func makeUIView(context: Context) -> UIView {
        let imageView = UIImageView(frame: imageFrame)
        let view = UIScrollView()
        view.delegate = context.coordinator
        view.minimumZoomScale = 0.25
        view.maximumZoomScale = 3
        view.contentSize = CGSize(width: imageFrame.width, height: imageFrame.height)
        view.backgroundColor = .clear
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.setZoomScale(0.5, animated: true)
        view.contentInsetAdjustmentBehavior = .never
//        imageView.dropShadow()
        view.addSubview(imageView)
        
        let insets = UIEdgeInsets(
            top: max(0, (size.height - imageFrame.height) / 2),
            left: max(0, (size.width - imageFrame.width) / 2),
            bottom: 0,
            right: 0
        )

        view.contentInset = insets
        
        return view
    }
    
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            
            if let scrollView = uiView as? UIScrollView, let imageView = scrollView.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
                //            if UIDevice.isIPhone {
                
                if !context.coordinator.setInitialZoomScale, size.width > 0, size.height > 0 {
                    context.coordinator.setInitialZoomScale = true
                    let zoomScale = min(min(size.width / imageView.frame.size.width, size.height / imageView.frame.size.height) * 0.9, 1);
                    scrollView.zoomScale = zoomScale
                }
                //            }
                
                let insets = UIEdgeInsets(
                    top: max(0, (size.height - imageView.frame.height) / 2),
                    left: max(0, (size.width - imageView.frame.width) / 2),
                    bottom: 0,
                    right: 0
                )
                scrollView.contentInset = insets
                if let image = UIImage(data: imageData) {
                    imageView.image = image
                    let scale = image.size.width / imageView.bounds.size.width + 2
                    scrollView.maximumZoomScale = scale
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableImageView
        var setInitialZoomScale: Bool = false

        init(_ parent: ZoomableImageView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.subviews.first(where: { $0 is UIImageView })
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            if let imageView = scrollView.subviews.first(where: { $0 is UIImageView }) as? UIImageView {
                let insets = UIEdgeInsets(
                    top: max(0, (scrollView.bounds.height - imageView.frame.height) / 2),
                    left: max(0, (scrollView.bounds.width - imageView.frame.width) / 2),
                    bottom: 0,
                    right: 0
                )
                scrollView.contentInset = insets
            }
        }
    }
}

struct ImageViewContainer: View {
    @ObservedObject var liveImage: LiveImage
    @State var size: CGSize
    var body: some View {
        VStack {
            GeometryReader { geo in
                let image = liveImage.currentImage ?? UIImage(color: .white, size: size)?.pngData()
                ZoomableImageView(size: geo.size, imageFrame: CGRect(x: 0, y: 0, width: size.width, height: size.height), imageData: image!)
                    
            }
        }
        .background(.clear)
    }
}

//
//
//#Preview {
//    ZoomableImageView()
//}
