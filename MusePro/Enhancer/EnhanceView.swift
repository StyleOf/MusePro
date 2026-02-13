//
//  EnhanceView.swift
//  Muse Pro
//
//  Created by Omer Karisman on 20.02.24.
//

import SwiftUI

class EnhanceObject: ObservableObject, Codable, Equatable, Identifiable {
    
    var id: UUID
    @Published var input: Data?
    @Published var output: Data?
    @Published var prompt: String
    @Published var scale: CGFloat
    @Published var creativity: CGFloat
    @Published var detail: CGFloat
    @Published var preservation: CGFloat
    @Published var seed: Int
    @Published var guidance: CGFloat
    @Published var inProgress: Bool = false
    
    lazy var inputImage: UIImage? = {
        guard let input else { return nil }
        return UIImage(data: input)
    }()
    
    var outputImage: UIImage? {
        guard let output else { return nil }
        return UIImage(data: output)
    }
    
    init(id: UUID = UUID(), input: Data? = nil, output: Data? = nil, prompt: String = "", scale: CGFloat = 1.0, creativity: CGFloat = 0.1 , detail: CGFloat = 1.0, preservation: CGFloat = 0.5, seed: Int = 42, guidance: CGFloat = 7.5, inProgress: Bool = false) {
        self.id = id
        self.input = input
        self.output = output
        self.prompt = prompt
        self.scale = scale
        self.creativity = creativity
        self.detail = detail
        self.preservation = preservation
        self.seed = seed
        self.guidance = guidance
        self.inProgress = inProgress
    }
    
    static func == (lhs: EnhanceObject, rhs: EnhanceObject) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: CodingKey {
        case id, prompt, scale, creativity, detail, preservation, seed, guidance
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(prompt, forKey: .prompt)
        try container.encode(scale, forKey: .scale)
        try container.encode(creativity, forKey: .creativity)
        try container.encode(detail, forKey: .detail)
        try container.encode(preservation, forKey: .preservation)
        try container.encode(seed, forKey: .seed)
        try container.encode(guidance, forKey: .guidance)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        prompt = try container.decode(String.self, forKey: .id)
        scale = try container.decode(CGFloat.self, forKey: .id)
        creativity = try container.decode(CGFloat.self, forKey: .id)
        detail = try container.decode(CGFloat.self, forKey: .id)
        preservation = try container.decode(CGFloat.self, forKey: .id)
        seed = try container.decode(Int.self, forKey: .id)
        guidance = try container.decode(CGFloat.self, forKey: .id)
        
    }
}

class EnhanceManager: ObservableObject {
    @Published var enhances: [EnhanceObject] = [EnhanceObject]()
    @Published var current: EnhanceObject = EnhanceObject()
    //    init() {
    //        let enhanceObject = EnhanceObject(input: Data(), scale: 2.0, creativity: 0.1, detail: 1.0, preservation: 0.5, seed: Int.random(in: 0..<10_000_000), guidance: 7.5)
    //        self.enhances = [enhanceObject]
    //    }
    
    init() {
        
    }
    
    init(enhances: [EnhanceObject]) {
        self.enhances = enhances
    }
}

struct EnhanceView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var orientationInfo: OrientationInfo

    @ObservedObject var canvasManager: CanvasManager
    @ObservedObject var liveImage: LiveImage
    @ObservedObject var enhanceManager: EnhanceManager

    @State var selectedTab = 0

    @State var input: Data?
    @State var output: Data?
    @State var creativity: Float = 0.04 //0.2 //0-1
    @State var detail: Float = 1.2 //1.5 //0-3
    @State var preservation: Float = 0.5 //1 //0-3
    @State var guidance: Float = 7.5 //1 //0-3
    @State var scale: Int = 1
    @State var seed: Int = 424242
    @State var prompt: String = ""
           
    @State var inProgress: Bool = false

    
//    init(data: Data? = nil, prompt: String = "") {
//        _input = State(initialValue: data)
//        _prompt = State(initialValue: prompt)
//    }
    
    init(canvasManager: CanvasManager, liveImage: LiveImage, enhanceManager: EnhanceManager) {
        self.canvasManager = canvasManager
        self.liveImage = liveImage
        self.enhanceManager = enhanceManager
        _prompt = State(initialValue: liveImage.prompt)

        _input = State(initialValue: canvasManager.renderer?.resizedTexture?.toData(context: canvasManager.renderer?.context))
//        _output = State(initialValue: canvasManager.renderer?.resizedTexture?.toData(context: canvasManager.renderer?.context))

        _seed = State(initialValue: Int.random(in: 0..<10_000_000))

    }
    
    var body: some View {
        VStack {
            if UIDevice.isIPhone {
                if orientationInfo.orientation == .portrait {
                    VStack {
                        EnhanceNavigationBar()
                        EnhanceResultView()
                        if !enhanceManager.enhances.isEmpty {
                            EnhanceFooter()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.top, 8)
                        }
                        //                EnhanceResultsView(horizontal: true)
                        //                    .padding(.horizontal, 8)
                        EnhanceSidebar()
                    }
                    .padding()
                } else {
                    HStack (alignment: .top, spacing: 16) {
                        VStack {
                            EnhanceNavigationBar()
                            EnhanceSidebar()
                            if !enhanceManager.enhances.isEmpty {
                                EnhanceFooter()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.top, 8)
                            }
                        }
                        EnhanceResultView()
                    }
                    .padding()
                   
                }
            } else {
                if orientationInfo.orientation == .portrait {
                    VStack {
                        EnhanceNavigationBar()
                        EnhanceResultView()
                        if !enhanceManager.enhances.isEmpty {
                            EnhanceFooter()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.top, 8)
                        }
                        //                EnhanceResultsView(horizontal: true)
                        //                    .padding(.horizontal, 8)
                        EnhanceSidebar()
                    }
                    .padding()
                   
                } else {
                    HStack (alignment: .top, spacing: 16) {
                        VStack {
                            EnhanceNavigationBar()
                            EnhanceSidebar()
                        }
                        EnhanceResultView()
                    }
                    .padding()
                    if !enhanceManager.enhances.isEmpty {
                        EnhanceFooter()
                            .padding(.top, 8)
                    }
                }
               
            }
        }
        .background(.canvasBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.keyboard)
    }
    
   
    @ViewBuilder
    func EnhanceFooter() -> some View {
        HStack (spacing: 16) {
            EnhanceResultsView()
            Button {
                if let data = enhanceManager.current.output {
                    canvasManager.addImage(data, select: true)
                    withAnimation {
                        ControlsViewModel.shared.hideEnhanceView()
                    }
                }
            } label: {
                HStack {
                    Text("Add")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .light))

                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.controlForeground)
            .foregroundStyle(.canvasBackground)
            .disabled(enhanceManager.current.output == nil)

        }
            
        .padding(8)
        .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
    }
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    @ViewBuilder
    func EnhanceNavigationBar() -> some View {
        ZStack {
            HStack {
                Button {
                    withAnimation {
                        ControlsViewModel.shared.hideEnhanceView()
                    }
                } label: {
                    Text("Close")
                }
                .buttonStyle(.borderless)
                .background(.clear)
                
                
                Spacer()
            }
            Text("Enhance")
                .font(.title)
        }
        //        .padding(.horizontal)
    }
    
    @ViewBuilder
    func EnhanceSidebar() -> some View {
        VStack {
            EnhanceParametersView()
            //                .padding(.horizontal)
        }
    }
    
    @FocusState
        var isFocused: Bool

    @State var source: Int = 2
    @ViewBuilder
    func EnhanceParametersView() -> some View {
        VStack {
            
            //            Picker(selection: $selectedTab, label: Text(""), content: {
            //                           Text("Settings").tag(0)
            //                           Text("Layers").tag(1)
            //                       }).pickerStyle(SegmentedPickerStyle())
            //                .padding(.bottom)
            ScrollView(.vertical, showsIndicators: false) {
                VStack (spacing: 12) {
                    Picker(selection: $source, label: Text(""), content: {
                        Text("Generated").tag(1)
                        Text("Drawing").tag(2)
                    }).pickerStyle(SegmentedPickerStyle())
//                        .padding(.bottom)
                        .onChange(of: source) { _ in
                            if source == 2 {
                                input = canvasManager.renderer?.resizedTexture?.toData(context: canvasManager.renderer?.context)
                            } else if source == 1 {
                                input = canvasManager.liveImage?.currentImage
                            }
                        }
                    Divider()
                    Text("Prompt")
                        .foregroundStyle(.infoText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                    TextField("",
                              text: $prompt,//$liveImage.prompt, TODO: Get current prompt on launch
                              prompt: Text("What does the eye of your mind see?").foregroundColor(.gray),
                              axis: .vertical)
                    .focused($isFocused)
                    .onChange(of: prompt) { newValue in
                        guard isFocused else { return }
                        guard newValue.contains("\n") else { return }
                        isFocused = false
                        prompt = newValue.replacing("\n", with: "")
                    }
//                        .onChange(of: prompt) { value in
//                            enhanceManager.current.prompt = CGFloat(prompt)
//                        }
                    .lineLimit(3)
                    .padding(12)
                    .background(.promptBackground)
                    .foregroundColor(Color.foreground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.bottom, 8)
                    
                    Text("Guidance Scale")
                        .foregroundStyle(.infoText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack {
                        Slider(value: $guidance, in: 0...15, step: 0.1)
                            .tint(Color(UIColor.systemBlue))
//                            .onChange(of: guidance) { value in
//                                enhanceManager.current.guidance = CGFloat(guidance)
//                            }
                        Text(guidance/15, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(Color.foreground)
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    
                    Divider()
                    
                    Text("Creativity")
                        .foregroundStyle(.infoText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack {
                        Slider(value: $creativity, in: 0...0.4, step: 0.01)
                            .tint(Color(UIColor.systemBlue))
//                            .onChange(of: creativity) { value in
//                                enhanceManager.current.creativity = CGFloat(creativity)
//                            }
                        Text(creativity/0.4, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(Color.foreground)
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    
                    Text("Detail")
                        .foregroundStyle(.infoText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack {
                        Slider(value: $detail, in: 0...3, step: 0.01)
                            .tint(Color(UIColor.systemBlue))
//                            .onChange(of: detail) { value in
//                                enhanceManager.current.detail = CGFloat(detail)
//                            }
                        Text(detail/3, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(Color.foreground)
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    
                    Text("Shape Preservation")
                        .foregroundStyle(.infoText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack {
                        Slider(value: $preservation, in: 0...3, step: 0.01)
                            .tint(Color(UIColor.systemBlue))
//                            .onChange(of: preservation) { value in
//                                enhanceManager.current.preservation = CGFloat(preservation)
//                            }
                        Text(preservation/3, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(Color.foreground)
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    
                    Divider()
                    
                    Text("Scale Multiplier")
                        .foregroundStyle(.infoText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                    Picker(selection: $scale, label: Text(""), content: {
                        Text("1x").tag(1)
                        Text("2x").tag(2)
                        Text("4x").tag(4)
                    }).pickerStyle(SegmentedPickerStyle())
                        .padding(.bottom)
//                        .onChange(of: scale) { value in
//                            enhanceManager.current.scale = CGFloat(scale)
//                        }
                    
                    Divider()
                    
                    Text("Seed")
                        .foregroundStyle(.infoText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.system(size: 13, weight: .medium))
                    HStack {
                        TextField("Enter a seed value to control randomness",
                                  value: $seed,
                                  formatter: formatter)
//                        .onChange(of: seed) { value in
//                            enhanceManager.current.seed = CGFloat(seed)
//                        }
                        .lineLimit(1)
                        .padding(12)
                        .background(.promptBackground)
                        .foregroundColor(Color.foreground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button {
                            seed = Int.random(in: 0..<10_000_000)
                        } label: {
                            Image(systemName: "dice")
                                .font(.system(size: 20, weight: .light))

                        }
                    }
                    Divider()
                    
                }
                
            }
            .frame(maxHeight: .infinity)
            
            Button {
                guard UserManager.shared.canPerformPro(with: 20) else {
                    PaywallManager.shared.presentPaywall()
                    return
                }

                if let data = input {
                    let newEnhanceObject = EnhanceObject(input: data, prompt: prompt, scale: CGFloat(scale), creativity: CGFloat(creativity), detail: CGFloat(detail), preservation: CGFloat(preservation), seed: seed, guidance: CGFloat(guidance), inProgress: true)
                    changeCurrentEnhanceObject(enhanceObject: newEnhanceObject)
                    enhanceManager.enhances.append(newEnhanceObject)
                    liveImage.enhance(data: data, scale: Float(enhanceManager.current.scale), prompt: enhanceManager.current.prompt, seed: enhanceManager.current.seed, guidance: Float(enhanceManager.current.guidance), creativity: Float(enhanceManager.current.creativity), detail: Float(enhanceManager.current.detail), preservation: Float(enhanceManager.current.preservation), onComplete: { image in
                        newEnhanceObject.output = image
                        newEnhanceObject.inProgress = false
                        if newEnhanceObject == enhanceManager.current {
                            self.output = image
                        }
                    })
                }
            } label: {
                Text("Enhance")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Color(UIColor.systemBlue))
            .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 320, maxHeight: .infinity)
        .frame(minWidth: 320)
    }
    
    @ViewBuilder
    func EnhanceResultView() -> some View {
        ZStack {
            BeforeAfterView(enhanceManager: enhanceManager, input: $input, output: $output)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            if enhanceManager.current.inProgress {
                AnimatedGradientRectangle()
                    .ignoresSafeArea()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .reverseMask {
                        RoundedRectangle(cornerRadius: 4)
                            .padding(4)
                        
                    }
//                    .aspectRatio(1, contentMode: .fit)
            }
        }
//        .scaledToFit()
        .layoutPriority(1)
    }
    
    func changeCurrentEnhanceObject(enhanceObject: EnhanceObject) {
        enhanceManager.current = enhanceObject
        self.input = enhanceObject.input
        self.output = enhanceObject.output
        self.prompt = enhanceObject.prompt
        self.scale = Int(enhanceObject.scale)
        self.creativity = Float(enhanceObject.creativity)
        self.detail = Float(enhanceObject.detail)
        self.preservation = Float(enhanceObject.preservation)
        self.seed = enhanceObject.seed
        self.guidance = Float(enhanceObject.guidance)
    }
    
    @ViewBuilder
    func EnhanceResultsView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(enhanceManager.enhances, id: \.id) { enhanceObject in
                    Button {
                        withAnimation {
                            changeCurrentEnhanceObject(enhanceObject: enhanceObject)
                        }
                        //                        prompt = enhanceObject.prompt ?? ""
                        //                        seed = enhanceObject.seed
                        //                        creativity = Float(enhanceObject.creativity)
                        //                        detail = Float(enhanceObject.detail)
                        //                        preservation = Float(enhanceObject.preservation)
                        //                        guidance = Float(enhanceObject.guidance)
                        //                        scale = Int(enhanceObject.scale)
                        
                    } label: {
                        ZStack {
                            if let uiImage = enhanceObject.outputImage ?? enhanceObject.inputImage {
                               Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 64, height: 64)
                                    .zIndex(0)
                                
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .foregroundStyle(.controlForeground)
                                    .zIndex(0)
                            }
                            if enhanceObject == enhanceManager.current {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(UIColor.systemBlue), lineWidth: 2.0)
                                    .frame(width: 62, height: 62)
                                    .zIndex(1)
                            }
                            if enhanceObject.inProgress {
                                AnimatedGradientRectangle()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .reverseMask {
                                        RoundedRectangle(cornerRadius: 10)
                                            .padding(2)
                                        
                                    }
                                    .frame(width: 64, height: 64)
                                    .aspectRatio(1, contentMode: .fit)
                                    .zIndex(2)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
//                Button {
//                    //TODO: currentTexture / resizedTexture
//                    let currentEnhance = enhanceManager.current
//                    let newEnhanceObject = EnhanceObject(input: canvasManager.canvas?.renderer?.resizedTexture?.toData(context: canvasManager.canvas?.renderer?.context) ?? Data(),
//                                                         scale: CGFloat(currentEnhance.scale), creativity: CGFloat(currentEnhance.creativity), detail: CGFloat(currentEnhance.detail), preservation: CGFloat(currentEnhance.preservation), seed: currentEnhance.seed, guidance: CGFloat(currentEnhance.guidance))
//                    enhanceManager.enhances.append(newEnhanceObject)
//                    enhanceManager.current = newEnhanceObject
//                    
//                    
//                } label: {
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 12)
//                            .frame(square: 64)
//                            .foregroundStyle(.controlForeground)
//                        Image(systemName: "plus")
//                            .foregroundStyle(.controlBackground)
//                    }
//                }
            }
            .padding(4)
        }
    }
}

struct AnimatedGradientRectangle: View {
    @State var progress: CGFloat = 0
    let gradient1 = Gradient(colors: [.purple, .yellow])
    let gradient2 = Gradient(colors: [.blue, .purple])
    
    var body: some View {
        Rectangle()
            .animatableGradient(fromGradient: gradient1, toGradient: gradient2, progress: progress)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: true)) {
                    self.progress = 1.0
                }
            }
    }
}

struct BeforeAfterView: View {
    @ObservedObject var enhanceManager: EnhanceManager
    
    @State private var location: CGPoint = CGPoint(x: 0, y: 0)
    @State private var maskWidth: CGFloat = 0
    
    @State var startPoint: CGFloat = 0
    @State var endPoint: CGFloat = 0
    @State var yPoint: CGFloat = 0
    
    var sliderWidth: CGFloat = 30
    @State var containerWidth: CGFloat = 200
    @State var containerHeight: CGFloat = 200
    
    @State var zoomScale: CGFloat = 1
    @State var contentOffset: CGPoint = CGPoint(x: 0, y: 0)
    
    @Binding var input: Data?
    @Binding var output: Data?
    
    @State var imageWrapper: ImageWrapper?

    func adjustMaskAndSlider(geo: GeometryProxy) {
        containerWidth = geo.size.width
        containerHeight = geo.size.height
        
        if maskWidth == 0 {
            location = CGPoint(x: containerWidth / 2, y: containerHeight / 2)
            maskWidth = containerWidth / 2
        }
        
        endPoint = containerWidth
        yPoint = containerHeight / 2
        
        updateDragView(point: location)
        updateMaskView()
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let input = input, let image = Image(data: input) {
                    ZoomableContainer (content: {
                        ZStack (alignment: .topLeading) {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: containerWidth, height: containerHeight)
                                .background(Color.clear)
                                .clipped()
                            
                            Text("Original")
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding()
                        }
                        .clipped()
                    }, didScroll: { contentOffset in
                        //                    self.contentOffset = contentOffset
                    }, didZoom: { zoomScale in
                        //                    self.zoomScale = zoomScale
                    }, scale: $zoomScale, offset: $contentOffset)
//                    .disabled(output == nil)
                }
                if let output = output, let image = Image(data: output) {
                    ZoomableContainer (content: {
                        ZStack (alignment: .topTrailing) {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: containerWidth, height: containerHeight)
                                .clipped()
                                .background(Color.clear)
                            Text("Enhanced")
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding()
                        }
                        .clipped()
                    }, didScroll: { contentOffset in
                        //                    self.contentOffset = contentOffset
                    }, didZoom: { zoomScale in
                        //                    self.zoomScale = zoomScale
                    }, scale: $zoomScale, offset: $contentOffset)
                    .mask(mask)
                    
//                    Slider
//                        .frame(maxWidth: 50)
//                        .background(.red.opacity(0.1))
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.white)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 1)
                            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                            .hoverEffect()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.white)
                        
                    }
                    .frame(maxWidth: 50)
                    .background {
                        Rectangle()
                            .fill(.blue.opacity(0.001))
                    }
                    .position(location)
                    .gesture(dragAction)
//                        .opacity(output == nil ? 0 : 1)
                    
                    VStack {
                        Spacer()
                        HStack {
                            Button {
                                if let data = enhanceManager.current.output,
                                   let image = UIImage(data: data) {
                                   self.imageWrapper = ImageWrapper(image: image)
                                }
                            } label: {
                                HStack {
                                    Text("Share")
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 20, weight: .light))

                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                            .tint(.controlForeground)
                            .foregroundStyle(.canvasBackground)
                            .disabled(enhanceManager.current.output == nil)
                            .sheet(item: $imageWrapper, onDismiss: {
                                
                            }, content: { image in
                                ActivityViewController(imageWrapper: image)
                            })
                            Button {
                                if let data = enhanceManager.current.output,
                                   let image = UIImage(data: data) {
                                    let imageSaver = ImageSaver()
                                    imageSaver.writeToPhotoAlbum(image: image)
                                }
                                ToastManager.shared.showSuccess(message: "Saved")

                            } label: {
                                HStack {
                                    Text("Save")
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 20, weight: .light))

                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .controlSize(.small)
                            .tint(.controlForeground)
                            .foregroundStyle(.canvasBackground)
                            .disabled(enhanceManager.current.output == nil)
                            .sheet(item: $imageWrapper, onDismiss: {
                                
                            }, content: { image in
                                ActivityViewController(imageWrapper: image)
                            })
                        }
                    }
                    .padding()
                    
                }
                
               
            }
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                adjustMaskAndSlider(geo: geo)
            }
            .onChange(of: geo.size) { _ in
               adjustMaskAndSlider(geo: geo)
            }
            .onChange(of: input) { _ in
                zoomScale = 1
                contentOffset = CGPoint(x: 0, y: 0)
            }
            .onChange(of: output) { _ in
                zoomScale = 1
                contentOffset = CGPoint(x: 0, y: 0)
            }
        }
    }
    
    var dragAction: some Gesture {
        DragGesture()
            .onChanged { value in
                updateDragView(point: value.location)
                updateMaskView()
            }
            .onEnded { value in
                // No longer resetting to initial position to maintain the last position after drag
            }
    }
    
    var mask: some View {
        HStack {
            Spacer()
            Rectangle()
                .mask(Color.black)
                .frame(width: maskWidth, height: containerHeight)
        }
    }
    
    var Slider: some View {
//        VStack(spacing: 0) {
//            Rectangle()
//                .fill(Color.white)
//                .frame(width: 4)
//            Image(systemName: "circle.circle.fill")
//                .font(.system(size: 20, weight: .light))
//
//                .foregroundColor(.white)
//                .frame(width: sliderWidth, height: sliderWidth)
//                .font(.system(size: sliderWidth))
//            Rectangle()
//                .fill(Color.white)
//                .frame(width: 4)
//        }
            HStack {
                Image(systemName: "chevron.left")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 1)
                    .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 10))
                    .hoverEffect()
                Image(systemName: "chevron.right")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(.white)
                
            }
            .frame(maxWidth: 50)
            .background {
                Rectangle()
                    .fill(.blue.opacity(0.1))
            }
            .position(location)
            .gesture(dragAction)
//            .shadow(radius: 4)

    }
    
    func updateDragView(point: CGPoint) {
        let locX = point.x
        if locX > startPoint && locX < endPoint {
            self.location = CGPoint(x: point.x, y: yPoint)
        }
    }
    
    func updateMaskView() {
        if (location.x) > 0 && location.x < containerWidth {
            maskWidth = containerWidth - location.x
        }
    }
}


//#Preview {
//    ZStack {
//        Rectangle()
//            .background(.white)
//        VStack {
//            EnhanceView()
//        }
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//        .padding()
//        .background(.black.opacity(0.4))
//        .ignoresSafeArea(.all)
//    }
//}
