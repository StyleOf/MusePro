//
//  ContentView.swift
//  Huner
//
//  Created by Omer Karisman on 04.12.23.
//

import SwiftUI
import SplitView

import PencilKit

struct DrawingView: View {
    private var canvasView = PKCanvasView()

    var body: some View {
        MyCanvas(canvasView: canvasView)
    }
}

struct MyCanvas: UIViewRepresentable {
    var canvasView: PKCanvasView
    let picker = PKToolPicker.init()
    
    func makeUIView(context: Context) -> PKCanvasView {
        self.canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        self.canvasView.becomeFirstResponder()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        picker.addObserver(canvasView)
        picker.setVisible(true, forFirstResponder: uiView)
        DispatchQueue.main.async {
            uiView.becomeFirstResponder()
        }
    }
}

extension UIView {
//    func snapshot() -> UIImage {
//        let controller = UIHostingController(rootView: self)
//        let view = controller.view
//        let targetSize = controller.view.intrinsicContentSize
//        view?.bounds = CGRect(origin: .zero, size: targetSize)
//        view?.backgroundColor = .clear
//        let renderer = UIGraphicsImageRenderer(size: targetSize)
//        return renderer.image { _ in
//            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
//        }
//    }
    
    func setImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: self.bounds)
        return renderer.image { renderContext in
//            layer.render(in: renderContext.cgContext)
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }
    }
}


struct ContentView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.safeAreaInsets) var safeAreaInsets
    @EnvironmentObject var orientationInfo: OrientationInfo
    @Environment(\.colorScheme) var colorScheme
    
    
    @StateObject var canvasManager: CanvasManager
    @StateObject var liveImage: LiveImage
    @StateObject var enhanceManager: EnhanceManager

    @ObservedObject var controlsViewModel: ControlsViewModel = ControlsViewModel.shared
    @ObservedObject var userManager: UserManager = UserManager.shared

    var namespace: Namespace.ID
    var document: Document
    
    var imageViewContainer: ImageViewContainer?
    var interactiveCanvas: InteractiveCanvas?
    var interactiveOverlayCanvas: InteractiveOverlayCanvas?

    var onBack: () -> Void
    
    @State var zoomScale: CGFloat = 1
    @State var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    
    init(canvasManager: CanvasManager, liveImage: LiveImage, enhanceManager: EnhanceManager, namespace: Namespace.ID, document: Document, onBack: @escaping () -> Void) {
        self.namespace = namespace
        self.document = document
        
        self._liveImage = StateObject(wrappedValue: liveImage)

        self._canvasManager = StateObject(wrappedValue: canvasManager)
        
        self._enhanceManager = StateObject(wrappedValue: enhanceManager)
        
        self.onBack = onBack

        self.imageViewContainer = ImageViewContainer(liveImage: liveImage, size: document.size)
        self.interactiveCanvas = InteractiveCanvas(canvasManager: canvasManager, size: document.size)
        self.interactiveOverlayCanvas = InteractiveOverlayCanvas(canvasManager: canvasManager, liveImage: liveImage, size: document.size, opacity: 0.1)
    }
    
    var body: some View {
        MainContentView()
            .padding(0)
            .background(ImagePaint(image: Image(colorScheme == .dark ? "DarkPattern" : "LightPattern").resizable(
                resizingMode: .tile
            ))
            , ignoresSafeAreaEdges: .all)
//            .statusBar(hidden: true)
            .navigationBarTitle("")
            .navigationBarHidden(true)
//            .environmentObject(canvasManager)
//            .environmentObject(liveImage)
//            .environmentObject(enhanceManager)
            .onAppear {
                if userManager.subscription == .none {
                    liveImage.renderMode = .slow
                } else {
                    liveImage.renderMode = .fast
                }
            }
            .onChange(of: userManager.subscription) { _ in
                if userManager.subscription == .none {
                    liveImage.renderMode = .slow
                } else {
                    liveImage.renderMode = .fast
                }
            }
            .ignoresSafeArea(.all)
        
    }
    
    @State var snapshot: UIImage? = nil
    
    @ViewBuilder
    func MainContentView() -> some View {
        ZStack {
            Rectangle()
                .fill(.clear)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)
                .matchedGeometryEffect(id: document.id, in: namespace)
            if canvasManager.overlayMode {
                OverlayCanvas()
                    .background(.clear)
                    .zIndex(1)
            } else {
                MainCanvasArea()
                    .background(.clear)
                    .zIndex(1)
            }
              
            ControlsView(canvasManager: canvasManager, liveImage: liveImage, onBack: onBack)
                .zIndex(2)
            if controlsViewModel.showEnhanceViewModal {
//                VStack {
                    //TODO: resizedTexture / currentTexture
                    EnhanceView(canvasManager: canvasManager, liveImage: liveImage, enhanceManager: enhanceManager)
//                }
                .ignoresSafeArea(.keyboard)
                .zIndex(3)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .background(.controlForeground.opacity(0.5))
//                .ignoresSafeArea(.all)
            }
            
            if controlsViewModel.showingEyeDropper {
                if snapshot != nil {
                    EyeDropperView(snapshot: snapshot!) { color in
                        if let color = color {
                            if controlsViewModel.eyeDropperTarget == .brushColor {
                                canvasManager.brushColor = color
                            } else if controlsViewModel.eyeDropperTarget == .backgroundColor {
                                canvasManager.backgroundColor = color
                            }
                            controlsViewModel.hideEyeDropper()
                            snapshot = nil
                        } else {
                            controlsViewModel.hideEyeDropper()
                            snapshot = nil
                        }
                    }
                    .ignoresSafeArea(.all)
                    .zIndex(4)
                } else {
                    Color.clear
                        .onAppear {
//                            snapshot = ImageRenderer(content: self).uiImage
                            snapshot = UIApplication.shared.keyWindow?.rootViewController?.view.setImage()
                        }
                        .zIndex(4)
                }
            
            }
        }
        .sheet(isPresented: $controlsViewModel.showEnhanceViewSheet) {
            EnhanceView(canvasManager: canvasManager, liveImage: liveImage, enhanceManager: enhanceManager)
                .interactiveDismissDisabled(true)
        }
    }
    
    let hide = SideHolder()
    let styling = SplitStyling(visibleThickness: 10)
    @State var fraction = FractionHolder()
    @State var layout = LayoutHolder(UIDevice.isIPhone ? .vertical : .horizontal)
    
    @ViewBuilder
    func interactiveCanvasView() -> some View {
        ZStack {
            interactiveCanvas
            VStack {
                Spacer()
                canvasActionsView()
                    .padding(.bottom, 100)
            }
        }
    }
    
    @State var newLayer: Bool = false
    
    @ViewBuilder
    func canvasActionsView() -> some View {
        if canvasManager.currentMode == .selection {
            HStack {
                if let element = canvasManager.data.currentElement as? Chartlet {
                    Button {
                        guard UserManager.shared.canPerformPro(with: 20) else {
                            PaywallManager.shared.presentPaywall()
                            return }
                        
                        if let element = canvasManager.data.currentElement as? Chartlet, let texture = canvasManager.canvas?.findTexture(by: element.textureID), let data = texture.texture.toData(context: canvasManager.renderer?.context) {
                            //                    DispatchQueue.main.async {
                            //                        self.updater.toggle()
                            //                    }
                            canvasManager.liveImage?.removeBg(data: data) { removed in
                                //                        self.updater.toggle()
                                if let removed,  let newTexture = try? canvasManager.canvas?.makeTexture(with: removed) {
                                    let removeBackgroundCmd = RemoveBackgroundCommand(canvasManager: canvasManager, element: element, previousTexture: element.textureID, newTexture: newTexture.id)
                                    CommandManager.shared.executeCommand(removeBackgroundCmd)
                                    canvasManager.canvas?.redrawCurrentLayer()
                                    //                            self.updater.toggle()
                                }
                            }
                            //                    self.updater.toggle()
                        }
                    } label: {
                        if canvasManager.liveImage != nil, canvasManager.liveImage!.removing {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Removing Background")
                                    .foregroundStyle(Color.foreground)
                            }
                            
                        } else {
                            Label("Remove Background", systemImage: "person.and.background.dotted")
                                .foregroundStyle(Color.foreground)
                            
                        }
                    }
                    .buttonStyle(RoundedRectangleButtonStyleSM())
                    .disabled(canvasManager.liveImage?.removing ?? false)
                    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                    .hoverEffect()
                }
                Button {
                    canvasManager.currentMode = .brush
                } label: {
                    
                    Label("Done", systemImage: "person.and.background.dotted")
                        .labelStyle(.titleOnly)
                        .foregroundStyle(Color(.white))
                    
                }
                .buttonStyle(RoundedRectangleButtonStyleSMSystem())
                .disabled(canvasManager.liveImage?.removing ?? false)
                .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                .hoverEffect()
            }
            .padding(8)
            .background {
                ShinyRect()
            }
        } else if canvasManager.currentMode == .lasso {
            HStack {
              
                Button {
                    canvasManager.currentMode = .brush
                } label: {
                    
                    Label("Cancel", systemImage: "person.and.background.dotted")
                        .labelStyle(.titleOnly)
                        .foregroundStyle(Color.foreground)

                }
                .buttonStyle(RoundedRectangleButtonStyleSM())
                .disabled(canvasManager.liveImage?.removing ?? false)
                .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                .hoverEffect()
                
                Button {
                    canvasManager.cutLassoSelection(newLayer: newLayer)
                } label: {
                    
                    Label("Cut", systemImage: "scissors")
                        .foregroundStyle(Color.foreground)

                }
                .buttonStyle(RoundedRectangleButtonStyleSM())
                .disabled(canvasManager.liveImage?.removing ?? false)
                .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                .hoverEffect()
                
                Button {
                    canvasManager.copyLassoSelection(newLayer: newLayer)
                } label: {
                    
                    Label("Copy", systemImage: "plus.square.on.square")
                        .foregroundStyle(Color.foreground)

                }
                .buttonStyle(RoundedRectangleButtonStyleSM())
                .disabled(canvasManager.liveImage?.removing ?? false)
                .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                .hoverEffect()
                
                Toggle(isOn: $newLayer, label: {
                    Text("New Layer")
                })
                .fixedSize()
                
            }
            .padding(8)
            .background {
                ShinyCapsule()
            }
        }
    }

    @ViewBuilder
    func MainCanvasArea() -> some View {
        Split(primary: {
            if canvasManager.isRightHanded || orientationInfo.orientation == .portrait {
//                ImageViewContainer(liveImage: liveImage, size: document.size)
                imageViewContainer
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
//                InteractiveCanvas(canvasManager: canvasManager, size: document.size)
                interactiveCanvasView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }, secondary: {
            if canvasManager.isRightHanded || orientationInfo.orientation == .portrait {
//                InteractiveCanvas(canvasManager: canvasManager, size: document.size)
                interactiveCanvasView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
//                ImageViewContainer(liveImage: liveImage, size: document.size)
                imageViewContainer
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .matchedGeometryEffect(id: document.id, in: namespace)
            }
        })
        .splitter { CustomSplitter(layout: layout, hide: hide, styling: styling) }
        .layout(layout)
        .fraction(fraction)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, UIDevice.isIPhone ? 32 + safeAreaInsets.top: 0)
        .padding(.bottom, UIDevice.isIPhone ? (orientationInfo.orientation == .portrait ? 40 + safeAreaInsets.bottom : safeAreaInsets.bottom) : 0)
        .edgesIgnoringSafeArea(.all)
        .background(.clear)
        .onAppear {
            layout = LayoutHolder(orientationInfo.orientation == .portrait ? .vertical : .horizontal)
        }
        .onChange(of: orientationInfo.orientation) { orientation in
            layout = LayoutHolder(orientationInfo.orientation == .portrait ? .vertical : .horizontal)
        }
        //        .onChange(of: liveImage.enabled) { enabled in
        //            if enabled {
        //                hide.side = nil
        //            } else {
        //                hide.hide(.primary)
        //            }
        //        }
    }
    
    @ViewBuilder
    func OverlayCanvas() -> some View {
        ZStack {
            interactiveOverlayCanvas
            VStack {
                Spacer()
                canvasActionsView()
                    .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, UIDevice.isIPhone ? 32 + safeAreaInsets.top: 0)
        .padding(.bottom, UIDevice.isIPhone ? (orientationInfo.orientation == .portrait ? 40 + safeAreaInsets.bottom : safeAreaInsets.bottom) : 0)
        .edgesIgnoringSafeArea(.all)
        .background(.clear)
        //        .onChange(of: liveImage.enabled) { enabled in
        //            if enabled {
        //                hide.side = nil
        //            } else {
        //                hide.hide(.primary)
        //            }
        //        }
    }
}

struct BackgroundClearView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct CustomSplitter: SplitDivider {
    @ObservedObject var layout: LayoutHolder
    @ObservedObject var hide: SideHolder
    @ObservedObject var styling: SplitStyling
    /// The `hideButton` state tells whether the custom splitter hides the button that normally shows
    /// in the middle. If `styling.previewHide` is true, then we only want to show the button if
    /// `styling.hideSplitter` is also true.
    /// In general, people using a custom splitter need to handle the layout when `previewHide`
    /// is triggered and that layout may depend on whether `hideSplitter` is `true`.
    @State var hideButton: Bool = false
    let hideRight = Image(systemName: "arrowtriangle.right.square")
    let hideLeft = Image(systemName: "arrowtriangle.left.square")
    let hideDown = Image(systemName: "arrowtriangle.down.square")
    let hideUp = Image(systemName: "arrowtriangle.up.square")
    
    var body: some View {
        if layout.isHorizontal {
            ZStack {
                HStack(spacing: 0) {
                    Color.black
                        .frame(width: 12)
                        .padding(0)
                        .reverseMask {
                            
                            Rectangle()
                                .frame(width: 12)
                                .foregroundColor(.black)
                                .padding(.leading, 6)
                                .cornerRadius(6)
                                .padding(.leading, -6)
                            
                        }
                    Color.black
                        .frame(width: 10)
                        .padding(0)
                    
                    Color.black
                        .frame(width: 12)
                        .padding(0)
                        .reverseMask {
                            Rectangle()
                                .frame(width: 12)
                                .foregroundColor(.black)
                                .padding(.trailing, 6)
                                .cornerRadius(6)
                                .padding(.trailing, -6)
                        }
                }
                .zIndex(0)
                Capsule()
                    .foregroundStyle(Color.foreground.opacity(0.5))
                    .frame(width: 4, height: 64)
                    .zIndex(1)
                    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                    .hoverEffect(.automatic)
                
            }
            .contentShape(Rectangle())
        } else {
            ZStack {
                VStack(spacing: 0) {
                    Color.black
                        .frame(height: 12)
                        .padding(0)
                        .reverseMask {
                            Rectangle()
                                .frame(height: 12)
                                .foregroundColor(.black)
                                .padding(.top, 6)
                                .cornerRadius(6)
                                .padding(.top, -6)
                            
                        }
                    Color.black
                        .frame(height: 10)
                        .padding(0)
                    
                    Color.black
                        .frame(height: 12)
                        .padding(0)
                        .reverseMask {
                            
                            Rectangle()
                                .frame(height: 12)
                                .foregroundColor(.black)
                                .padding(.bottom, 6)
                                .cornerRadius(6)
                                .padding(.bottom, -6)
                            
                        }
                }
                .zIndex(0)
                Capsule()
                    .foregroundStyle(Color.foreground.opacity(0.5))
                    .frame(width: 64, height: 4)
                    .zIndex(1)
                    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                    .hoverEffect(.automatic)
            }
            .contentShape(Rectangle())
        }
    }}


final class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    
    @Published var orientation: Orientation = .portrait
    
    var _observer: NSObjectProtocol?
    
    init() {
        setInitialOrientation()
        observeOrientationChanges()
    }
    
    func setInitialOrientation() {
        if UIDevice.current.orientation.isLandscape {
            orientation = .landscape
        } else if UIDevice.current.orientation.isPortrait {
            orientation = .portrait
        } else {
            orientation = defaultOrientationBasedOnInterfaceOrientation()
        }
    }
    
    func observeOrientationChanges() {
        #if os(visionOS)


        #elseif os(iOS)
                _observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                    self?.setOrientationBasedOnCurrentState()
                }
        #endif
       
    }
    
    func setOrientationBasedOnCurrentState() {
        let currentOrientation = UIDevice.current.orientation
        if currentOrientation.isPortrait {
            orientation = .portrait
        } else if currentOrientation.isLandscape {
            orientation = .landscape
        } else {
            orientation = defaultOrientationBasedOnInterfaceOrientation()
        }
    }
    
    func defaultOrientationBasedOnInterfaceOrientation() -> Orientation {
        if let windowScene = UIApplication.shared.keyWindow?.windowScene {
            switch windowScene.interfaceOrientation {
            case .landscapeLeft, .landscapeRight:
                return .landscape
            case .portrait, .portraitUpsideDown:
                return .portrait
            case .unknown:
                return defaultOrientationBasedOnDeviceType()
            @unknown default:
                return defaultOrientationBasedOnDeviceType()
            }
        } else {
            return defaultOrientationBasedOnDeviceType()
        }
    }
    
    func defaultOrientationBasedOnDeviceType() -> Orientation {
        let isLandscapeDefault = UIDevice.isIPad || UIDevice.isVision || !UIDevice.isIPhone
        return isLandscapeDefault ? .landscape : .portrait
    }
    
    deinit {
        if let observer = _observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
