//
//  ControlsView.swift
//  MusePro
//
//  Created by Omer Karisman on 12.01.24.
//

import SwiftUI
import PhotosUI

class ControlsViewModel: ObservableObject {
    static let shared = ControlsViewModel()
    
    @Environment(\.openWindow) private var openWindow
    
    @Published var adjusting: Bool = false
    @Published var adjustingColor: UIColor?
        
    var showingBrushLibrary: Bool {
        return showBrushLibrarySheet || showBrushLibraryInline
    }
    
    var showingLayerManager: Bool {
        return showLayerManagerSheet || showLayerManagerInline
    }
    
    var showingEnhanceView: Bool {
        return showEnhanceViewModal || showEnhanceViewSheet
    }
    
    var showingTextEditor: Bool {
        return showTextEditorSheet || showTextEditorInline
    }
    
    var showingAIControls: Bool {
        return showAIControlsSheet || showAIControlsInline
    }
    
    var showingPromptView: Bool {
        return showPromptViewSheet || showPromptViewInline
    }
    
    var showingColorPicker: Bool {
        return showColorPickerSheet || showColorPickerInline
    }
    
    
    @Published var showEnhanceViewModal: Bool = false
    @Published var showEnhanceViewSheet: Bool = false
    
    @Published var showBrushLibraryInline: Bool = false
    @Published var showBrushLibrarySheet: Bool = false
    
    @Published var showLayerManagerInline: Bool = false
    @Published var showLayerManagerSheet: Bool = false
    
    @Published var showTextEditorInline: Bool = false
    @Published var showTextEditorSheet: Bool = false
    
    @Published var showAIControlsInline: Bool = false
    @Published var showAIControlsSheet: Bool = false
    
    @Published var showPromptViewInline: Bool = false
    @Published var showPromptViewSheet: Bool = false
    
    @Published var showColorPickerInline: Bool = false
    @Published var showColorPickerSheet: Bool = false
    
    enum EyeDropperTarget {
        case brushColor
        case backgroundColor
    }
    
    @Published var showingEyeDropper: Bool = false
    var eyeDropperTarget: EyeDropperTarget = .brushColor
    
    func showEnhanceView() {
        if UIDevice.isIPhone {
            showEnhanceViewSheet = true
        } else {
            showEnhanceViewModal = true
        }
    }
    
    func hideEnhanceView() {
        if UIDevice.isIPhone {
            showEnhanceViewSheet = false
        } else {
            showEnhanceViewModal = false
        }
    }
    
    
    func startAdjusting(with color: UIColor) {
        if !adjusting {
            adjustingColor = color
            adjusting = true
        }
    }
    
    func stopAdjusting() {
        adjusting = false
    }
    
    func hidePanels() {
        showBrushLibraryInline = false
        showLayerManagerInline = false
        showPromptViewInline = false
        showColorPickerInline = false
        showTextEditorInline = false
    }
    
    func showBrushLibrary() {
        if UIDevice.isIPhone {
            showBrushLibrarySheet = true
        } else {
            showBrushLibraryInline = true
        }
    }
    
    func hideBrushLibrary() {
        if UIDevice.isIPhone {
            showBrushLibrarySheet = false
        } else {
            showBrushLibraryInline = false
        }
    }
    
    func showLayerManager() {
        if UIDevice.isIPhone {
            showLayerManagerSheet = true
        } else {
            showLayerManagerInline = true
        }
    }
    
    func hideLayerManager() {
        if UIDevice.isIPhone {
            showLayerManagerSheet = false
        } else {
            showLayerManagerInline = false
        }
    }
    
    func showTextEditor() {
        if UIDevice.isIPhone {
            showTextEditorSheet = true
        } else {
            showTextEditorInline = true
        }
    }
    
    func hideTextEditor() {
        if UIDevice.isIPhone {
            showTextEditorSheet = false
        } else {
            showTextEditorInline = false
        }
    }
    
    func showAIControls() {
        if UIDevice.isIPhone {
            showAIControlsSheet = true
        } else {
            showAIControlsInline = true
        }
    }
    
    func hideAIControls() {
        if UIDevice.isIPhone {
            showAIControlsSheet = false
        } else {
            showAIControlsInline = false
        }
    }
    
    func showPromptView() {
        if UIDevice.isIPhone {
            showPromptViewSheet = true
        } else {
            showPromptViewInline = true
        }
    }
    
    func hidePromptView() {
        if UIDevice.isIPhone {
            showPromptViewSheet = false
        } else {
            showPromptViewInline = false
        }
    }
    
    func showColorPicker() {
        if UIDevice.isIPhone {
            showColorPickerSheet = true
        } else {
            showColorPickerInline = true
        }
    }
    
    func hideColorPicker() {
        if UIDevice.isIPhone {
            showColorPickerSheet = false
        } else {
            showColorPickerInline = false
        }
    }
    
    func showEyeDropper(target: EyeDropperTarget) {
        eyeDropperTarget = target
        showingEyeDropper = true
    }
    
    func hideEyeDropper() {
        showingEyeDropper = false
    }
}

enum ColorTarget {
    case brush
    case background
}

struct ControlsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var liveImage: LiveImage
    @ObservedObject var userManager = UserManager.shared
    
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    @ObservedObject var controlsViewModel = ControlsViewModel.shared
    
    @FocusState var promptFocused: Bool
    
    var brushManager = BrushManager.shared
    
    @State var contentSize: CGSize = .zero
    
    @State var showImagePicker: Bool = false
    
    @State var showUpgradeBanner: Bool = true
    
    @State var detentHeight: CGFloat = 0
    
    
    //    @State var promptViewExpanded: Bool = false
    
    @State var timeNow = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    var dateFormatter: DateFormatter {
        let fmtr = DateFormatter()
        fmtr.dateFormat = "LLLL dd, hh:mm:ss a"
        return fmtr
    }
    
    var onBack: () -> Void?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if promptFocused {
                    Rectangle()
                        .fill(.black.opacity(0.1))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            self.hideKeyboard()
                        }
                }
                if controlsViewModel.showPromptViewInline {
                    Rectangle()
                        .fill(.black.opacity(0.1))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            withAnimation {
                                controlsViewModel.hidePromptView()
                            }
                        }
                }
                if UIDevice.isIPhone {
                    if orientationInfo.orientation == .portrait {
                        VStack {
                            HStack (alignment: .bottom, spacing: 0) {
                                ControlButton(imageName: "arrow.left", action: {
                                    canvasManager.canvas?.isPaused = true
                                    onBack()
                                })
                                CanvasControls(canvasManager: canvasManager, liveImage: liveImage)
                                
                                ControlButton(imageName: "text.viewfinder", action: {
                                    controlsViewModel.showPromptView()
                                })
                                ControlButton(imageName: "dial.high") {
                                    if controlsViewModel.showingAIControls {
                                        controlsViewModel.hideAIControls()
                                    } else {
                                        controlsViewModel.showAIControls()
                                    }
                                }
                                CanvasMenu(canvasManager: canvasManager, liveImage: liveImage)
                                
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: safeAreaInsets.top + 24)
                            .padding(.bottom, 8)
                            .background {
                                MatteRect()
                            }
                            Spacer()
                            upgradeBanner()
                            HStack (alignment: .top, spacing: 0) {
                                ToolBar(canvasManager: canvasManager, showImagePicker: $showImagePicker)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: safeAreaInsets.bottom + 24)
                            .padding(.top, 16)
                            .background {
                                ShinyRect()
                            }
                        }
                        //                        .padding(.bottom, safeAreaInsets.bottom)
                        //                        .padding(.top, safeAreaInsets.top)
                    } else {
                        VStack {
                            HStack (alignment: .top) {
                                HStack(spacing: 0) {
                                    ControlButton(imageName: "arrow.left", action: {
                                        //                                        presentationMode.wrappedValue.dismiss()
                                        canvasManager.canvas?.isPaused = true
                                        onBack()
                                    })
                                    CanvasControls(canvasManager: canvasManager, liveImage: liveImage)
                                    
                                    
                                    CanvasMenu(canvasManager: canvasManager, liveImage: liveImage)
                                }
                                .background {
                                    ShinyRect()
                                    
                                }
                                HStack(spacing: 0) {
                                    ControlButton(imageName: "character.bubble", action: {
                                        controlsViewModel.showPromptView()
                                    })
                                    ControlButton(imageName: "dial.high") {
                                        if controlsViewModel.showingAIControls {
                                            controlsViewModel.hideAIControls()
                                        } else {
                                            controlsViewModel.showAIControls()
                                        }
                                    }
                                }
                                .background {
                                    ShinyRect()
                                    
                                }
                                
                                
                                //                                PromptView(liveImage: liveImage, canvasManager: canvasManager, focused: $promptFocused, expanded: $controlsViewModel.showPromptViewInline)
                                
                                HStack(spacing: 0) {
                                    ToolBar(canvasManager: canvasManager, showImagePicker: $showImagePicker)
                                }
                                .background {
                                    ShinyRect()
                                    
                                }
                            }
                            
                            
                            Spacer()
                            HStack {
                                Spacer()
                                upgradeBanner()
                            }
                        }
                        .padding(8)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .padding(.leading, canvasManager.isRightHanded ? safeAreaInsets.leading : 0)
                    }
                } else {
                    VStack {
                        HStack (alignment: .top) {
                            HStack(spacing: 0) {
                                ControlButton(imageName: "arrow.left", action: {
                                    //                                    presentationMode.wrappedValue.dismiss()
                                    onBack()
                                    
                                })
                                CanvasMenu(canvasManager: canvasManager, liveImage: liveImage)
                            }
                            .background {
                                ShinyRect()
                            }
                            HStack(spacing: 0) {
                                CanvasControls(canvasManager: canvasManager, liveImage: liveImage)
                            }
                            .background {
                                ShinyRect()
                            }
                            Spacer()
                            PromptView(liveImage: liveImage, controlsViewModel: controlsViewModel, canvasManager: canvasManager, focused: $promptFocused, expanded: $controlsViewModel.showPromptViewInline)
                            Spacer()
                            HStack(spacing: 0) {
                                ToolBar(canvasManager: canvasManager, showImagePicker: $showImagePicker)
                            }
                            .background {
                                ShinyRect()
                            }
                        }
                        Spacer()
                        HStack (alignment: .bottom) {
                            HStack {
                                ControlButton(imageName: "dial.high") {
                                    if controlsViewModel.showingAIControls {
                                        controlsViewModel.hideAIControls()
                                    } else {
                                        controlsViewModel.showAIControls()
                                    }
                                }
                            }
                            .background {
                                ShinyRect()
                            }
                            
                            if controlsViewModel.showAIControlsInline {
                                AIControlsView(liveImage: liveImage, canvasManager: canvasManager)
                                   
                            }
                            Spacer()
                            upgradeBanner()
                        }
                        //                        HStack {
                        //                            Text(timeNow)
                        //                                .onReceive(timer) { _ in
                        //                                    self.timeNow = dateFormatter.string(from: Date())
                        //                                }
                        //                        }
                        //                        .background {
                        //                            RoundedRectangle(cornerRadius: 24)
                        //                                .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                        //                        }
                    }
                    .padding()
                    //                    .padding(.top, safeAreaInsets.top)
                    
                }
                
                //                GeometryReader { geo in
                //                    ZStack (alignment: .leading) {
                //                        BrushControls(isRightHanded: isRightHanded, controlsViewModel: controlsViewModel )
                //                            .modifier(
                //                                SnapDraggingModifier(
                //                                    axis: .horizontal,
                //                                    horizontalBoundary: .init(min: 0, max: .infinity, bandLength: 50),
                //                                    handler: .init(onEndDragging: { velocity, offset, contentSize in
                //
                //                                        print(velocity, offset, contentSize)
                //
                //                                        if velocity.dx > 50 || offset.width > (geo.size.width / 2) {
                //                                            print("remove")
                //                                            return .init(width: geo.size.width, height: 0)
                //                                        } else {
                //                                            print("stay")
                //                                            return .zero
                //                                        }
                //                                    })
                //                                )
                //                            )
                //                    }
                //                }
                if canvasManager.isRightHanded {
                    HStack {
                        BrushControls(canvasManager: canvasManager)
                        if controlsViewModel.showColorPickerInline {
                            MuseColors(onColorChanged: { color in
                                canvasManager.brushColor = UIColor(color)
                            }, onEyedropperSelected: {
                                controlsViewModel.hideColorPicker()
                                controlsViewModel.showEyeDropper(target: .brushColor)
                            }, onClose: {
                                controlsViewModel.hideColorPicker()
                            }, primaryColor: Color(uiColor: canvasManager.brushColor))
                                .frame(width: 320, height: 550)
                                .background {
                                    ShinyRect()
                                }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.trailing, UIDevice.isIPhone && orientationInfo.orientation == .landscape ? 16 : 8)
                } else {
                    HStack {
                        Spacer()
                        if controlsViewModel.showColorPickerInline {
                            MuseColors(onColorChanged: { color in
                                canvasManager.brushColor = UIColor(color)
                            }, onEyedropperSelected: {
                                controlsViewModel.hideColorPicker()
                                controlsViewModel.showEyeDropper(target: .brushColor)
                            }, onClose: {
                                controlsViewModel.hideColorPicker()
                            }, primaryColor: Color(uiColor: canvasManager.brushColor))
                                .frame(width: 320, height: 550)
                                .background {
                                    ShinyRect()
                                }
                        }
                        BrushControls(canvasManager: canvasManager)
                    }
                    .padding(.horizontal, 8)
                    .padding(.trailing, UIDevice.isIPhone && orientationInfo.orientation == .landscape ? 16 : 8)
                }
                
                if controlsViewModel.showBrushLibraryInline {
                    ZStack (alignment: .top) {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture()
                                .onChanged({ _ in
                                    controlsViewModel.hideBrushLibrary()
                                })
                            )
                            .onTapGesture {
                                controlsViewModel.hideBrushLibrary()
                            }
                        HStack {
                            Spacer()
                            BrushLibrary() { brush in
                                if let brush {
                                    canvasManager.useTool(brush)
                                }
                                controlsViewModel.hideBrushLibrary()
                            } onCancel: {
                                controlsViewModel.hideBrushLibrary()
                            }
                        }
                        .padding()
                    }
                    .padding(.top, 64)
                }
                
                if controlsViewModel.showLayerManagerInline {
                    ZStack (alignment: .top) {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture()
                                .onChanged({ _ in
                                    controlsViewModel.hideLayerManager()
                                })
                            )
                            .onTapGesture {
                                controlsViewModel.hideLayerManager()
                            }
                        
                        HStack {
                            Spacer()
                            LayersView(canvasManager: canvasManager, data: canvasManager.data)
                        }
                        .padding()
                    }
                    .padding(.top, 64)
                }
                
                if controlsViewModel.adjusting {
                    BrushDisplayView(canvasManager: canvasManager)
                }
                
                if controlsViewModel.showTextEditorInline || controlsViewModel.showTextEditorSheet {
                    ZStack (alignment: .top) {
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(DragGesture()
                                .onChanged({ _ in
                                    controlsViewModel.hideTextEditor()
                                })
                            )
                            .onTapGesture {
                                controlsViewModel.hideTextEditor()
                            }
                        HStack (alignment: .top) {
                            TextEditor(canvasManager: canvasManager){
                                controlsViewModel.hideTextEditor()
                            } onSelect: {
                                controlsViewModel.hideTextEditor()
                            }
                        }
                        
                    }
                    .padding(.top, 64)
                    
                }
            }
        }
        .onChange(of: liveImage.strength) { _ in
            DispatchQueue.main.async {
                canvasManager.canvas?.updateResized()
            }
        }
        .edgesIgnoringSafeArea(.all)
        .sheet(isPresented: $controlsViewModel.showBrushLibrarySheet) {
            BrushLibrary() { brush in
                if let brush {
                    canvasManager.useTool(brush)
                }
                controlsViewModel.hideBrushLibrary()
            } onCancel: {
                controlsViewModel.hideBrushLibrary()
            }
            .presentationBackground(.ultraThinMaterial)
            .presentationDetents([.medium, .large])
            
        }
        .sheet(isPresented: $controlsViewModel.showLayerManagerSheet) {
            LayersView(canvasManager: canvasManager, data: canvasManager.data)
                .presentationBackground(.ultraThinMaterial)
                .presentationDetents([.medium, .large])
            
        }
        .sheet(isPresented: $controlsViewModel.showAIControlsSheet) {
            AIControlsView(liveImage: liveImage, canvasManager: canvasManager)
                .padding()
                .presentationBackground(.ultraThinMaterial)
                .readHeight()
                .onPreferenceChange(HeightPreferenceKey.self) { height in
                    if let height {
                        self.detentHeight = height
                    }
                }
                .presentationDetents([.height(self.detentHeight)])
            
        }
        .sheet(isPresented: $controlsViewModel.showPromptViewSheet) {
            PromptView(liveImage: liveImage, controlsViewModel: controlsViewModel, canvasManager: canvasManager, focused: $promptFocused, expanded: .constant(true))
                .presentationBackground(.ultraThinMaterial)
            //                .presentationDetents([.medium, .large])
                .readHeight()
                .onPreferenceChange(HeightPreferenceKey.self) { height in
                    if let height {
                        self.detentHeight = height
                    }
                }
                .presentationDetents([.height(self.detentHeight)])
        }
        .sheet(isPresented: $controlsViewModel.showColorPickerSheet, content: {
            MuseColors(onColorChanged: { color in
                canvasManager.brushColor = UIColor(color)
            }, onEyedropperSelected: {
                controlsViewModel.hideColorPicker()
                controlsViewModel.showEyeDropper(target: .brushColor)
            }, onClose: {
                controlsViewModel.hideColorPicker()
            }, primaryColor: Color(uiColor: canvasManager.brushColor))
                .frame(minWidth: 320, minHeight: 550)
                .presentationDetents([.large])

        })
        
    }
    
    @ViewBuilder
    func upgradeBanner() -> some View {
        if showUpgradeBanner, userManager.subscription == .none {
            HStack {
                Button {
                    PaywallManager.shared.presentPaywall(force: true)
                } label: {
                    Text("Upgrade to unlock realtime drawing")
                }
                .foregroundColor(.controlForeground)
                Divider()
                
                Button {
                    showUpgradeBanner = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .light))

                }
                .foregroundColor(.controlForeground)
            }
            .padding()
            .frame(maxHeight: 48)
            .background {
                ShinyRect()
            }
        }
    }
}

struct CanvasMenu: View {
    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var liveImage: LiveImage
    @State var imageWrapper: ImageWrapper?
    
    var body: some View {
        Menu {
            Button {
                canvasManager.isRightHanded.toggle()
            } label: {
                Label("Flip Controls", systemImage: "arrowshape.left.arrowshape.right")
            }
            Button {
                canvasManager.overlayMode.toggle()
            } label: {
                Label("\(canvasManager.overlayMode ? "Disable" : "Enable") Overlay", systemImage: "star.square.on.square")
            }
            Section("AI Canvas") {
                Button {
                    liveImage.enabled.toggle()
                } label: {
                    if !liveImage.enabled {
                        Label("Resume", systemImage: "play.circle")
                    } else {
                        Label("Pause", systemImage: "pause.circle")
                    }
                }
   
                Button {
                    canvasManager.saveImage()
                    ToastManager.shared.showSuccess(message: "Saved")
                    
                } label: {
                    Label("Save AI Image", systemImage: "square.and.arrow.down")
                }
                Button {
                    AnalyticsUtil.logEvent("musepro_share_ai_image")
                    
                    if let currentImage = liveImage.currentImage,
                       let image = UIImage(data: currentImage) {
                        self.imageWrapper = ImageWrapper(image: image)
                    }
                } label: {
                    Label("Share AI Image", systemImage: "square.and.arrow.up")
                }
            }
            Section("Drawing") {
                Button {
                    AnalyticsUtil.logEvent("musepro_enhance")
                    
                    guard UserManager.shared.canPerformPro(with: 20) else {
                        PaywallManager.shared.presentPaywall()
                        return
                    }
      
                    withAnimation {
                        ControlsViewModel.shared.showEnhanceView()
                    }
                } label: {
                    Label("Enhance Drawing", systemImage: "sparkles")
                }
                Button {
                    canvasManager.saveDrawing()
                    ToastManager.shared.showSuccess(message: "Saved")
                } label: {
                    Label("Save Drawing", systemImage: "square.and.arrow.down")
                }
                Button {
                    AnalyticsUtil.logEvent("musepro_share_drawing")
                    
                    if let currentImage = canvasManager.renderer?.currentTexture?.toData(context: canvasManager.renderer?.context),
                       let image = UIImage(data: currentImage) {
                        self.imageWrapper = ImageWrapper(image: image)
                    }
                } label: {
                    Label("Share Drawing", systemImage: "square.and.arrow.up")
                }
            }
        } label: {
            ControlView(imageName: "ellipsis.circle")
        }
        .sheet(item: $imageWrapper, onDismiss: {
            
        }, content: { image in
            ActivityViewController(imageWrapper: image)
        })
    }
}



struct ImageWrapper: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ActivityViewController: UIViewControllerRepresentable {
    let imageWrapper: ImageWrapper
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [imageWrapper.image], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

struct CanvasControls: View {
    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var liveImage: LiveImage
    @Environment(\.colorScheme) var colorScheme
    
    @State var showEnhanceOptions: Bool = false
    @State var showRenderModeOptions: Bool = false
    
    @State var creativity: Float = 0.1 //0.2 //0-1
    @State var detail: Float = 1.0 //1.5 //0-3
    @State var preservation: Float = 0.5 //1 //0-3
    
    @State var imageWrapper: ImageWrapper?
    
    var body: some View {
        
        MultiTapButton (singleTapAction: {
            liveImage.enabled.toggle()
        }, doubleTapAction: {
            
        }, longPressAction: {
            withAnimation {
                showRenderModeOptions.toggle()
            }
        }, duration: 0.5) {
            ControlView(imageName: liveImage.enabled ? "pause.circle" : "play.circle", selected: false, disabled: false)
        }
        .popover(isPresented: $showRenderModeOptions, content: {
            VStack (spacing: 12) {
                Toggle(
                    "Realtime",
                    systemImage: "livephoto.play",
                    isOn: Binding(
                        get: { liveImage.renderMode == .fast },
                        set: { newValue in
                            if newValue {
                                if UserManager.shared.subscription != .pro && UserManager.shared.subscription != .trial {
                                    PaywallManager.shared.presentPaywall()
                                } else {
                                    liveImage.renderMode = .fast
                                }
                            } else {
                                liveImage.renderMode = .slow
                            }
                        })
                )
                .tint(.purple)
                
                Picker(selection: $liveImage.model, label: Text(""), content: {
                    ForEach(Model.allCases) { option in

                        Text(String(describing: option))

                    }

                }).pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom)
//                
//                Picker(selection: $canvasManager.nis, label: Text(""), content: {
//                    Image(systemName: "gauge.with.dots.needle.0percent").tag(8)
//                        .font(.system(size: 20, weight: .light))
//
//                    Image(systemName: "gauge.with.dots.needle.50percent").tag(4)
//                        .font(.system(size: 20, weight: .light))
//
//                    Image(systemName: "gauge.with.dots.needle.100percent").tag(2)
//                        .font(.system(size: 20, weight: .light))
//                    
//                    Image(systemName: "gauge.open.with.lines.needle.84percent.exclamation").tag(1)
//                        .font(.system(size: 20, weight: .light))
//
//                }).pickerStyle(SegmentedPickerStyle())
//                    .padding(.bottom)
//                        .onChange(of: scale) { value in
//                            enhanceManager.current.scale = CGFloat(scale)
//                        }
            }
            .frame(minWidth: 160)
            .padding()
            .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
            .presentationCompactAdaptation(.popover)
        })
        
        //        TokenCounter()
        //        Counter()
        //        ControlDivider()
        //        Counter2()
        //        FPS(liveImage: liveImage)
        ControlButton(imageName: "arrow.right.doc.on.clipboard") {
            canvasManager.copyAICanvas()
        }
        MultiTapButton (singleTapAction: {
            AnalyticsUtil.logEvent("musepro_enhance")
            withAnimation {
                ControlsViewModel.shared.showEnhanceView()
            }
        }, doubleTapAction: {
            
        }, longPressAction: {

        }, duration: 0.5) {
            ControlView(imageName: "sparkles", selected: false, disabled: false, inProgress: liveImage.enhancing )
        }
    }
}

struct ToolBar: View {
    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var controlsViewModel = ControlsViewModel.shared
    
    @Binding var showImagePicker: Bool
    
    var body: some View {
        ControlButton(imageName: "cursorarrow", selected: canvasManager.currentMode == .selection) {
            controlsViewModel.hidePanels()
            canvasManager.usePointer()
        }
        
        ControlButton(imageName: "paintbrush.pointed", selected: canvasManager.currentMode == .brush) {
            let wasOpen = controlsViewModel.showingBrushLibrary
            controlsViewModel.hidePanels()
            if canvasManager.currentMode == .brush {
                if wasOpen {
                    controlsViewModel.hideBrushLibrary()
                } else {
                    controlsViewModel.showBrushLibrary()
                }
            } else {
                canvasManager.useBrush()
            }
        }
        
        ControlButton(imageName: "eraser", selected: canvasManager.currentMode == .eraser) {
            let wasOpen = controlsViewModel.showingBrushLibrary
            controlsViewModel.hidePanels()
            if canvasManager.currentMode == .eraser {
                if wasOpen {
                    controlsViewModel.hideBrushLibrary()
                } else {
                    controlsViewModel.showBrushLibrary()
                }
            } else {
                canvasManager.useEraser()
            }
        }
        
        ControlButton(imageName: "lasso", selected: canvasManager.currentMode == .lasso) {
            controlsViewModel.hidePanels()
            canvasManager.useLasso()
        }
        
        ControlButton(imageName: "square.2.layers.3d") {
            canvasManager.currentMode = .brush
            let wasOpen = controlsViewModel.showingLayerManager
            controlsViewModel.hidePanels()
            if !wasOpen {
                controlsViewModel.showLayerManager()
            } else {
                controlsViewModel.hideLayerManager()
            }
        }
        Menu {
            Button {
                controlsViewModel.hidePanels()
                controlsViewModel.showTextEditor()
                
            } label: {
                Label("Insert text", systemImage: "textformat")
            }
            Button {
                controlsViewModel.hidePanels()
                showImagePicker = true
            } label: {
                Label("Insert a photo", systemImage: "photo.on.rectangle.angled")
            }
            Button {
                canvasManager.copyAICanvas()
                
            } label: {
                Label("Paste from AI Canvas", systemImage: "arrow.right.doc.on.clipboard")
            }
            Button {
                let pasteboard = UIPasteboard.general
                if pasteboard.hasImages {
                    canvasManager.addImage(pasteboard.image!)
                }
            } label: {
                Label("Paste from clipboard", systemImage: "doc.on.clipboard")
            }
            //                                Button {
            //                                } label: {
            //                                   Label("Add Text", systemImage: "textformat")
            //                                }
            Button {
                canvasManager.addRectangle(color: canvasManager.brushColor.toMLColor())
                
            } label: {
                Label("Add Rectangle", systemImage: "rectangle")
            }
            Button {
                canvasManager.addCircle(color: canvasManager.brushColor.toMLColor())
            } label: {
                Label("Add Circle", systemImage: "circle")
            }
            Button {
                canvasManager.addTriangle(color: canvasManager.brushColor.toMLColor())
            } label: {
                Label("Add Triangle", systemImage: "triangle")
            }
            //                                Button {
            //                                } label: {
            //                                    Label("Add Polygon", systemImage: "hexagon")
            //                                }
        } label: {
            ControlView(imageName: "plus.square.on.square")
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(onSelect: { image in
                showImagePicker = false
                canvasManager.addImage(image)
            })
        }
    }
}

struct BrushControls: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var canvasManager: CanvasManager
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    @State var showBrushSizeView: Bool = false
    @State var showBrushOpacityView: Bool = false
    
    @State var colorTarget: ColorTarget = .brush
    @State var pickedColor: Color = .foreground
    
    @State var previousColor: UIColor?
    
    @ObservedObject var controlsViewModel = ControlsViewModel.shared
    
    let controlMargin: CGFloat = 30.0
    let controlLength: CGFloat = 100.0
    let controlMultiplier: CGFloat = 0.4
    
    //    let size = UIDevice.isIPhone ? 36.0 : 48.0
    let padding = UIDevice.isIPhone ? 8.0 : 12.0
    
    var body: some View {
        let controlSize = UIDevice.isIPhone ? (orientationInfo.orientation == .landscape ? 100.0 : 130.0) : 130.0
        VStack (alignment: canvasManager.isRightHanded ? .leading : .trailing) {
            //            RoundedRectangle(cornerRadius: 4)
            //                .fill(.controlForeground)
            //                .padding()
            //                .frame(width: 36, height: 8)
            //                .padding(.vertical, 8)
            
                Button() {
                    colorTarget = .brush
                    controlsViewModel.showColorPicker()
                } label: {
                    Circle()
                        .strokeBorder(Color.foreground, lineWidth: 2)
                        .background(Circle().fill(Color(canvasManager.brushColor)))
                        .frame(width: 34, height: 34)
                        .onTapGesture {
                            colorTarget = .brush
                            controlsViewModel.showColorPicker()
                        }
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    //                                controlsViewModel.startAdjusting(with: canvasManager.brushColor)
                                    //                                let dragAmount = gesture.translation
                                    //                                let amount = (abs(dragAmount.width) + abs(dragAmount.height)) / 2
                                    //                                let newColor = controlsViewModel.adjustingColor!.adjustedLuminance(min((amount - controlMargin), controlLength) / controlLength)
                                    //                                canvasManager.brushColor = newColor
                                    if !controlsViewModel.showingColorPicker {
                                        colorTarget = .brush
                                        controlsViewModel.showColorPicker()
                                    }
                                }
                            //                            .onEnded { _ in
                            //                                controlsViewModel.stopAdjusting()
                            //                            }
                        )
                }
                .frame(width: 36, height: 36)
               
            
//            .popover(isPresented: $controlsViewModel.showColorPickerInline, content: {
//                MuseColors(onColorChanged: { color in
//                    canvasManager.brushColor = UIColor(color)
//                }, onEyedropperSelected: {
//                    
//                }, primaryColor: Color(uiColor: canvasManager.brushColor))
//                    .frame(minWidth: 320, minHeight: 550)
//            })

            HStack {
                if !canvasManager.isRightHanded, showBrushSizeView {
                    BrushSizeView(canvasManager: canvasManager)
                }
                VStack {
                    VSlider(value: $canvasManager.brushPointSize, in: 0.01...1.0, onEditingChanged: { started in
                        showBrushSizeView = started
                    })
                    .frame(width: 36, height: controlSize)
                    
                }
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.sliderBackground)
                }
                if canvasManager.isRightHanded, showBrushSizeView {
                    BrushSizeView(canvasManager: canvasManager)
                }
            }
            HStack {
                if !canvasManager.isRightHanded, showBrushOpacityView {
                    BrushOpacityView(canvasManager: canvasManager)
                }
                VStack {
                    VSlider(value: $canvasManager.brushOpacity, in: 0.01...1.0, onEditingChanged: { started in
                        showBrushOpacityView = started
                    })
                    .frame(width: 36, height: controlSize)
                }
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.sliderBackground)
                }
                if canvasManager.isRightHanded, showBrushOpacityView {
                    BrushOpacityView(canvasManager: canvasManager)
                }
            }
            VStack {
                ControlButtonSm(imageName: "arrow.uturn.left", disabled: !canvasManager.canUndo) {
                    canvasManager.undo()
                }
                ControlButtonSm(imageName: "arrow.uturn.right", disabled: !canvasManager.canRedo) {
                    canvasManager.redo()
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(alignment: canvasManager.isRightHanded ? .leading : .trailing) {
            ShinyRect()
                .frame(maxWidth: 44)
        }
    }
}

struct BrushSizeView:View {
    @ObservedObject var canvasManager: CanvasManager
    @EnvironmentObject var orientationInfo: OrientationInfo
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let controlSize = UIDevice.isIPhone ? (orientationInfo.orientation == .landscape ? 100.0 : 130.0) : 130.0
        ZStack {
            VStack {
                Rectangle()
                    .fill(Color(canvasManager.brushColor.withAlphaComponent(canvasManager.brushOpacity)))
                    .frame(width: .infinity, height: .infinity)
                    .scaleEffect(canvasManager.brushPointSize)
                    .mask {
                        if let data = canvasManager.currentBrush?.preview, let image = Image(data: data) {
                            image
                                .resizable()
                                .frame(width: .infinity, height: .infinity)
                                .scaleEffect(canvasManager.brushPointSize)
                                .luminanceToAlpha()
                        } else {
                            Rectangle()
                                .scaledToFit()
                        }
                    }
            }
            .frame(width: controlSize, height: controlSize)
            .background {
                ShinyRect()
            }
            VStack {
                Text("Size: \(round(canvasManager.brushPointSize * 100), specifier: "%.0f")%")
                    .font(.footnote)
                Spacer()
            }
            .padding()
            .frame(width: controlSize, height: controlSize)
        }
    }
}


struct BrushOpacityView: View {
    @ObservedObject var canvasManager: CanvasManager
    @EnvironmentObject var orientationInfo: OrientationInfo
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let controlSize = UIDevice.isIPhone ? (orientationInfo.orientation == .landscape ? 100.0 : 130.0) : 130.0
        ZStack {
            VStack {
                Rectangle()
                    .fill(Color(canvasManager.brushColor.withAlphaComponent(canvasManager.brushOpacity)))
                    .frame(width: .infinity, height: .infinity)
                    .scaleEffect(canvasManager.brushPointSize)
                    .mask {
                        if let data = canvasManager.currentBrush?.preview, let image = Image(data: data) {
                            image
                                .resizable()
                                .frame(width: .infinity, height: .infinity)
                                .scaleEffect(canvasManager.brushPointSize)
                                .luminanceToAlpha()
                        } else {
                            Rectangle()
                                .scaledToFit()
                        }
                    }
            }
            .frame(width: controlSize, height: controlSize)
            .background {
                ShinyRect()
                
            }
            VStack {
                Text("Opacity: \(round(canvasManager.brushOpacity*100), specifier: "%.0f")%")
                    .font(.footnote)
                Spacer()
            }
            .padding()
            .frame(width: controlSize, height: controlSize)
        }
    }
}

struct BrushDisplayView: View {
    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var controlsViewModel = ControlsViewModel.shared
    
    var body: some View {
        ZStack {
            Color.foreground.opacity(0.5) // Semi-transparent white background
            
            // Circle with gradient based on hardness
            //            if viewModel.brushHardness == 1 {
            Circle()
                .trim(from: 0, to: 0.5)
                .fill(Color(canvasManager.brushColor))
            //                    .frame(width: viewModel.brushPointSize, height: viewModel.brushPointSize)
                .frame(width: 120, height: 120)
            Circle()
                .trim(from: 0.5, to: 1)
                .fill(Color(controlsViewModel.adjustingColor ?? canvasManager.brushColor))
            //                    .frame(width: viewModel.brushPointSize, height: viewModel.brushPointSize)
                .frame(width: 120, height: 120)
            
            
            //            } else {
            //                Circle()
            //                    .fill(RadialGradient(gradient: Gradient(colors: [Color(viewModel.brushColor.withAlphaComponent(viewModel.brushOpacity)), Color(viewModel.brushColor.withAlphaComponent(0))]), center: .center, startRadius: viewModel.brushHardness / 2 * viewModel.brushPointSize, endRadius: viewModel.brushPointSize / 2))
            //                    .frame(width: viewModel.brushPointSize, height: viewModel.brushPointSize)
            //            }
            
            
            // Your ControlButton views here
            // ...
        }
        .clipped()
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var onSelect: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    if let image = image as? UIImage {
                        DispatchQueue.main.async { [weak self] in
                            guard let strongSelf = self else { return }
                            
                            strongSelf.parent.onSelect(image.upOrientationImage())
                        }
                    } 
//                    else {
//                        provider.loadDataRepresentation(forTypeIdentifier: "public.image") { imageData, error in
//                            if let imageData, let image = UIImage(data: imageData) {
//                                DispatchQueue.main.async { [weak self] in
//                                    guard let strongSelf = self else { return }
//                                    
//                                    strongSelf.parent.onSelect(image)
//                                }
//                            }
//                        }
//                    }
                }
            }
        }
    }
}
//
//struct AIControlsView: View {
//    @ObservedObject var liveImage: LiveImage
//    weak var canvasManager: CanvasManager?
//
//    @ViewBuilder
//    func tools() -> some View {
//        VStack {
//            Text("AI Creativity")
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .foregroundStyle(Color.foreground)
//                .font(.system(.headline))
//            StrengthSliderHorizontal(liveImage: liveImage)
//                .frame(height: 48)
//        }
//        .frame(height: 48)
//        .frame(maxWidth: UIDevice.isIPhone ? .infinity : 300)
//        VStack {
//            Text("Seed")
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .foregroundStyle(Color.foreground)
//                .font(.system(.headline))
//
//            Button {
//                canvasManager?.shuffleSeed()
//            } label: {
//                HStack {
//                    Text("\(liveImage.seed)")
//                        .foregroundStyle(Color.promptForeground)
//                        .font(.body)
//                    Image(systemName: "dice")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .foregroundStyle(Color.promptForeground)
//                        .frame(width: 22, height: 22)
//                }
//                .padding()
//            }
//            .background {
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(Color.promptBackground)
//            }
//        }
//        .frame(maxWidth: UIDevice.isIPhone ? .infinity : 150)
//    }
//    var body: some View {
//
//        if UIDevice.isIPhone {
//            VStack(spacing: 12) {
//               tools()
//            }
//            .padding()
//        } else {
//            HStack(spacing: 12) {
//               tools()
//            }
//            .padding()
//        }
//
//    }
//}


struct AIControlsView: View {
    @ObservedObject var liveImage: LiveImage
    @ObservedObject var canvasManager: CanvasManager
    
    var body: some View {
        if UIDevice.isIPhone {
            VStack(spacing: 12) {
                HStack {
                    Button {
                        canvasManager.shuffleSeed()
                    } label: {
                        
                        Image(systemName: "dice")
                            .font(.system(size: 20, weight: .light))
                        
                            .foregroundStyle(Color.controlForegroundSecondary)
                            .frame(width: 22, height: 22)
                    }
                    
                    HStack {
                        //canvasManager.nis >= 4 ? 0.1 : 0.2
                        HSlider(value: $liveImage.strength, in: 0.05...0.99, step: 0.01, onEditingChanged: { editing in
                            if !editing {
                                liveImage.setStrength()
                            }
                        })
                        .frame(height: 44)
                        .frame(maxWidth: UIDevice.isIPhone ? .infinity : 240)
                        .padding(.trailing, 8)
                    }
                    
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.sliderBackground)
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.sliderStroke)
                            HStack {
                                Image(systemName: "scribble.variable")
                                    .font(.system(size: 20, weight: .light))
                                
                                    .frame(width: 22, height: 22)
                                    .foregroundColor(Color.controlForegroundSecondary)
                                Spacer()
                                Image(systemName: "textformat")
                                    .font(.system(size: 20, weight: .light))
                                    .frame(width: 22, height: 22)
                                    .foregroundColor(Color.controlForegroundSecondary)
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                }
                
                HStack {
                    HSlider(value: $canvasManager.nis, in: 1.0...8.0, step: 1.0, onEditingChanged: { editing in
    //                    if !editing {
    //                        liveImage.setStrength()
    //                    }
                    })
                    .frame(height: 44)
                    .frame(maxWidth: UIDevice.isIPhone ? .infinity : 240)
                    .padding(.trailing, 8)
                }
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.sliderBackground)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.sliderStroke)
                        HStack {
                            Image(systemName: "gauge.with.dots.needle.100percent")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                            Spacer()

                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                           
                        }
                        .padding(.horizontal, 10)
                    }
                }
                HStack {
                    HSlider(value: $liveImage.cfg, in: 0.0...3.0, step: 0.5, onEditingChanged: { editing in
    //                    if !editing {
    //                        liveImage.setStrength()
    //                    }
                    })
                    .frame(height: 44)
                    .frame(maxWidth: UIDevice.isIPhone ? .infinity : 240)
                    .padding(.trailing, 8)
                }
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.sliderBackground)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.sliderStroke)
                        HStack {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                            Spacer()
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                        }
                        .padding(.horizontal, 10)
                    }
                }
            }
            .padding(.vertical, 2)
            .padding(.leading, 16)
            .padding(.trailing, 2)
            .background {
                if !UIDevice.isIPhone {
                    ShinyRect()
                }
            }
        } else {
            HStack(spacing: 12) {
                Button {
                    canvasManager.shuffleSeed()
                } label: {
                    
                    Image(systemName: "dice")
                        .font(.system(size: 20, weight: .light))

                        .foregroundStyle(Color.controlForegroundSecondary)
                        .frame(width: 22, height: 22)
                }
                
                HStack {
                    //canvasManager.nis >= 4 ? 0.1 : 0.2
                    HSlider(value: $liveImage.strength, in: 0.05...0.99, step: 0.01, onEditingChanged: { editing in
                        if !editing {
                            liveImage.setStrength()
                        }
                    })
                    .frame(height: 44)
                    .frame(maxWidth: UIDevice.isIPhone ? .infinity : 240)
                    .padding(.trailing, 8)
                }
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.sliderBackground)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.sliderStroke)
                        HStack {
                            Image(systemName: "scribble.variable")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                            Spacer()
                            Image(systemName: "textformat")
                                .font(.system(size: 20, weight: .light))
                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                        }
                        .padding(.horizontal, 10)
                    }
                }
                
                HStack {
                    HSlider(value: $canvasManager.nis, in: 1.0...8.0, step: 1.0, onEditingChanged: { editing in
    //                    if !editing {
    //                        liveImage.setStrength()
    //                    }
                    })
                    .frame(height: 44)
                    .frame(maxWidth: UIDevice.isIPhone ? .infinity : 240)
                    .padding(.trailing, 8)
                }
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.sliderBackground)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.sliderStroke)
                        HStack {
                            Image(systemName: "gauge.with.dots.needle.100percent")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                            Spacer()

                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                        }
                        .padding(.horizontal, 10)
                    }
                }
                
                HStack {
                    HSlider(value: $liveImage.cfg, in: 0.0...3.0, step: 0.5, onEditingChanged: { editing in
    //                    if !editing {
    //                        liveImage.setStrength()
    //                    }
                    })
                    .frame(height: 44)
                    .frame(maxWidth: UIDevice.isIPhone ? .infinity : 240)
                    .padding(.trailing, 8)
                }
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.sliderBackground)
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.sliderStroke)
                        HStack {
                            Image(systemName: "lightbulb")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                            Spacer()
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 20, weight: .light))

                                .frame(width: 22, height: 22)
                                .foregroundColor(Color.controlForegroundSecondary)
                        }
                        .padding(.horizontal, 10)
                    }
                }
                
    //        
            }
            .padding(.vertical, 2)
            .padding(.leading, 16)
            .padding(.trailing, 2)
            .background {
                if !UIDevice.isIPhone {
                    ShinyRect()
                }
            }
        }
       
    }
}

struct PromptView: View {
    @ObservedObject var liveImage: LiveImage
    @EnvironmentObject var orientationInfo: OrientationInfo
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var controlsViewModel: ControlsViewModel
    
    weak var canvasManager: CanvasManager?
    
    @FocusState.Binding var focused: Bool
    @Binding var expanded: Bool
    @State var processingVision: Bool = false
    var body: some View {
        VStack (spacing: 0) {
            if expanded {
                HStack {
                    Text("Prompt")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(Color.foreground)
                        .font(.system(.headline))
                    //                        .padding(.top, 8)
                    Spacer()
                    if !UIDevice.isIPhone {
                        Button {
                            withAnimation {
                                controlsViewModel.hidePromptView()
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                focused = false
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .foregroundStyle(.black.opacity(0.001))
                                    .frame(width: 18, height: 18)
                                Image(systemName: "chevron.up.circle.fill")
                                    .font(.system(size: 20, weight: .light))

                                    .foregroundStyle(Color.promptForeground)
                            }
                        }
                    }
                }
                .padding(.bottom)
            }
            VStack {
                HStack {
                    PromptTextField(promptFocused: $focused, expanded: $expanded, liveImage: liveImage)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .padding(.top, expanded ? 12 : 0)
                    if !expanded {
                        Button {
                            withAnimation {
                                controlsViewModel.showPromptView()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .foregroundStyle(.black.opacity(0.001))
                                Image(systemName: "chevron.down.circle.fill")
                                    .font(.system(size: 20, weight: .light))

                                    .foregroundStyle(Color.promptForeground)
                            }
                        }
                        .frame(width: UIDevice.isIPhone ? 42 : 48, height: UIDevice.isIPhone ? 42 : 48)
                    }
                }
                if expanded {
                    
                    HStack (spacing: 16) {
                        Button {
                            guard UserManager.shared.canPerformPro(with: 2) else {
                                PaywallManager.shared.presentPaywall()
                                return
                            }
                            AnalyticsUtil.logEvent("musepro_prompt_enhance")

                            liveImage.enhancePrompt()
                        } label: {
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .light))

                                .foregroundStyle(Color.controlForegroundSecondary)
                                .frame(width: 22, height: 22)
                            
                        }
                        Button {
                            guard UserManager.shared.canPerformPro(with: 2) else {
                                PaywallManager.shared.presentPaywall()
                                return
                            }
                            AnalyticsUtil.logEvent("musepro_prompt_random")

                            liveImage.randomPrompt()
                        } label: {
                            
                            Image(systemName: "dice")
                                .font(.system(size: 20, weight: .light))

                                .foregroundStyle(Color.controlForegroundSecondary)
                                .frame(width: 22, height: 22)
                            
                        }
                        Button {
                            guard UserManager.shared.canPerformPro(with: 10) else {
                                PaywallManager.shared.presentPaywall()
                                return
                            }
                            AnalyticsUtil.logEvent("musepro_prompt_vision")

                            processingVision = true
                            liveImage.visionPrompt {
                                processingVision = false
                            }
                        } label: {
                            
                            if processingVision {
                                ProgressView()
                                    .frame(width: 22, height: 22)
                            } else {
                                Image(systemName: "eye")
                                    .font(.system(size: 20, weight: .light))

                                    .foregroundStyle(Color.controlForegroundSecondary)
                                    .frame(width: 22, height: 22)
                            }
                            
                        }
                        .disabled(processingVision)
                        Button {
                            guard UserManager.shared.canPerformPro(with: 2) else {
                                PaywallManager.shared.presentPaywall()
                                return
                            }
                            AnalyticsUtil.logEvent("musepro_prompt_translate")

                            liveImage.translatePrompt()
                        } label: {
                            
                           
                            Image(systemName: "character.book.closed")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(Color.controlForegroundSecondary)
                                .frame(width: 22, height: 22)
                            
                        }
                        Spacer()
                        Button {
                            liveImage.prompt = ""
                        } label: {
                            
                            Image(systemName: "delete.backward")
                                .font(.system(size: 20, weight: .light))

                                .foregroundStyle(Color.controlForegroundSecondary)
                                .frame(width: 22, height: 22)
                            
                        }
                        
                    }
                    .padding(12)
                }
            }
            .onTapGesture {
                withAnimation {
                    controlsViewModel.showPromptView()
                }
            }
            
            .background {
                RoundedRectangle(cornerRadius: expanded ? 10 : 24)
                    .fill(Color.promptBackground)
                    .frame(minHeight: UIDevice.isIPhone ? 42 : 48)
            }
            
        }
        .padding(expanded ? 16 : 0)
        .background {
            if !UIDevice.isIPhone {
                ShinyRect()
            }
        }
        .frame(minWidth: 250, maxWidth: 500)
        .onChange(of: focused) { value in
            if value {
                expanded = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    
                    focused = true
                }
                liveImage.lastPrompt = liveImage.prompt
            } else {
                liveImage.setPrompt()
            }
        }
    }
}

struct PromptTextField: View {
    @FocusState.Binding var promptFocused: Bool
    @Binding var expanded: Bool
    @ObservedObject var liveImage: LiveImage
    
    var body: some View {
        TextField("",
                  text: $liveImage.prompt,
                  prompt: Text("What does the eye of your mind see?").foregroundColor(.gray),
                  axis: expanded ? .vertical : .horizontal)
        .truncationMode(.tail)
        .focused($promptFocused)
        .lineLimit(expanded ? 6 : 1)
        .foregroundColor(Color.foreground)
        .onChange(of: liveImage.prompt) { newValue in
            guard promptFocused else { return }
            guard newValue.contains("\n") else { return }
            promptFocused = false
            liveImage.prompt = newValue.replacing("\n", with: "")
        }
        .fixedSize(horizontal: false, vertical: true)
        
    }
}

struct ControlButtonSm: View {
    let imageName: String
    var selected: Bool = false
    var disabled: Bool = false
    let action: () -> Void
    var body: some View {
        Button {
            Haptic.impact(.light).generate()
            action()
        } label: {
            ControlViewSm(imageName: imageName, selected: selected, disabled: disabled)
        }
        //        }
        //        .disabled(disabled)
    }
}

struct ControlViewSm: View {
    let imageName: String
    var selected: Bool = false
    var disabled: Bool = false
    
    var body: some View {
        ZStack {
            if selected {
                Circle()
                    .fill(Color.controlBackgroundSelected)
                    .padding(2)
            }
            Image(systemName: imageName)
                .font(.system(size: 20, weight: .light))

                .foregroundColor(disabled == true ? Color.controlDisabled : .foreground)
                .padding(10)
                .contentShape(Rectangle())
        }
        .frame(width: 36, height: 36)
    }
}


struct AnimatableGradientModifier: AnimatableModifier {
    
    let fromGradient: Gradient
    let toGradient: Gradient
    var progress: CGFloat = 0.0
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        var gradientColors = [Color]()
        
        for i in 0..<fromGradient.stops.count {
            let fromColor = UIColor(fromGradient.stops[i].color)
            let toColor = UIColor(toGradient.stops[i].color)
            
            gradientColors.append(colorMixer(fromColor: fromColor, toColor: toColor, progress: progress))
        }
        
        return LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    func colorMixer(fromColor: UIColor, toColor: UIColor, progress: CGFloat) -> Color {
        guard let fromColor = fromColor.cgColor.components else { return Color(fromColor) }
        guard let toColor = toColor.cgColor.components else { return Color(toColor) }
        
        let red = fromColor[0] + (toColor[0] - fromColor[0]) * progress
        let green = fromColor[1] + (toColor[1] - fromColor[1]) * progress
        let blue = fromColor[2] + (toColor[2] - fromColor[2]) * progress
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
}

struct MultiTapButton<Label> : View where Label : View {
    
    let label: Label
    let singleTapAction: () -> Void
    let doubleTapAction: () -> Void
    let longPressAction: () -> Void
    let duration: Double
    
    init(singleTapAction: @escaping () -> Void, doubleTapAction: @escaping () -> Void, longPressAction: @escaping () -> Void, duration: Double, @ViewBuilder label: () -> Label) {
        self.label = label()
        self.singleTapAction = singleTapAction
        self.doubleTapAction = doubleTapAction
        self.longPressAction = longPressAction
        self.duration = duration
    }
    
    @GestureState var onPressing: Bool = false
    @State var longAction: Bool = false
    
    var gesture: some Gesture {
        LongPressGesture(minimumDuration: duration)
            .updating($onPressing) { currentState, gestureState, transaction in
                gestureState = currentState
                transaction.animation = Animation.spring(duration: 0.0625)
            }
            .onEnded { finished in
                longAction = true
                longPressAction()
            }
    }
    
    var body: some View {
        Button(action: {
            if longAction {
                longAction = false
                return
            }
            singleTapAction()
        }) {
            label
        }
        .simultaneousGesture(gesture)
        .highPriorityGesture(
            TapGesture(count: 2)
                .onEnded { _ in
                    doubleTapAction()
                }
        )
    }
}

struct ControlButton: View {
    let imageName: String
    var selected: Bool = false
    var disabled: Bool = false
    var inProgress: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button {
            Haptic.impact(.light).generate()
            action()
        } label: {
            ControlView(imageName: imageName, selected: selected, disabled: disabled, inProgress: inProgress)
        }
        //        }
        //        .disabled(disabled)
    }
}

struct ControlView: View {
    let imageName: String
    var selected: Bool = false
    var disabled: Bool = false
    var inProgress: Bool = false
    
    let size = 44.0//UIDevice.isIPhone ? 42.0 : 48.0
    let padding = 10.0 //UIDevice.isIPhone ? 8.0 : 12.0
    
    @State var progress: CGFloat = 0
    let gradient1 = Gradient(colors: [.purple, .yellow])
    let gradient2 = Gradient(colors: [.blue, .purple])
    
    var body: some View {
        ZStack {
            if selected {
                Circle()
                    .fill(Color.controlBackgroundSelected)
                    .padding(4)
            }
            if inProgress {
                Rectangle()
                    .animatableGradient(fromGradient: gradient1, toGradient: gradient2, progress: progress)
                    .ignoresSafeArea()
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                            self.progress = 1.0
                        }
                    }
                    .mask {
                        Image(systemName: imageName)
                            .font(.system(size: 20, weight: .light))

                            .foregroundColor(disabled == true ? Color.controlDisabled : .controlForeground)
                            .padding(padding)
                            .contentShape(Rectangle())
                    }
            } else {
                Image(systemName: imageName)
                    .font(.system(size: 20, weight: .light))

                    .foregroundColor(disabled == true ? Color.controlDisabled : .controlForeground)
                
                    .padding(padding)
                    .aspectRatio(contentMode: .fit)
                    .contentShape(Rectangle())
            }
            
        }
        .frame(width: size, height: size)
    }
}

struct ControlDivider: View {
    var body: some View {
        Rectangle()
        //            .frame(height: 1)
        //            .frame(maxWidth: 30)
            .frame(maxHeight: 30)
            .frame(width: 1)
            .foregroundColor(Color.controlDivider)
            .padding(.horizontal, 8)
    }
}

struct StrengthSliderHorizontal: View {
    @ObservedObject var liveImage: LiveImage
    
    var body: some View {
        //        VStack {
        HStack (spacing: 12) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 20, weight: .light))

                .frame(width: 22, height: 22)
                .foregroundColor(Color.controlForeground)
            Slider(value: $liveImage.strength, in: 0.05...0.99, step: 0.01)
            { editing in
                if !editing {
                    liveImage.setStrength()
                }
            }
            .accentColor(Color.foreground)
            Image(systemName: "textformat")
                .font(.system(size: 20, weight: .light))

                .frame(width: 22, height: 22)
                .foregroundColor(Color.controlForeground)
        }
    }
}

struct TokenCounter: View {
    @ObservedObject var userManager = UserManager.shared
    var body: some View {
        Text("\(userManager.remainingOnboardingTokens)")
            .foregroundStyle(Color.foreground)
            .padding(12)
        
    }
}

struct Counter: View {
    @ObservedObject var liveImage: LiveImage
    var body: some View {
        Text("\(liveImage.counter)")
            .foregroundStyle(Color.foreground)
            .padding(12)
        
    }
}
struct Counter2: View {
    @ObservedObject var liveImage: LiveImage
    var body: some View {
        Text("\(liveImage.counter_alt)")
            .foregroundStyle(Color.foreground)
            .padding(12)
    }
}
struct FPS: View {
    @ObservedObject var liveImage: LiveImage
    var body: some View {
        Text("\(liveImage.fps)")
            .foregroundStyle(Color.foreground)
            .padding(12)
    }
}

//#Preview {
//    ControlsView()
//        .ignoresSafeArea(.keyboard)
//}
