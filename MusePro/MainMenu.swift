//
//  MainMenu().swift
//  MusePro
//
//  Created by Omer Karisman on 31.01.24.
//

import SwiftUI
import StoreKit
import RevenueCat
import SimpleToast
#if os(visionOS)
   // visionOS code
#elseif os(iOS)
import Intercom
#endif


//struct NavigationLazyView<Content: View>: View {
//    let build: () -> Content
//    init(_ build: @autoclosure @escaping () -> Content) {
//        self.build = build
//    }
//    var body: Content {
//        build()
//    }
//}

struct LinkPresenter<Content: View>: View {
    let content: () -> Content
    
    @State private var invlidated = false
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        Group {
            if self.invlidated {
                EmptyView()
            } else {
                content()
            }
        }
        .onDisappear { self.invlidated = true }
    }
}

class MainModel: ObservableObject {
    static let shared = MainModel()
    
    @Published var canvasManager: CanvasManager? = nil
    @Published var liveImage: LiveImage? = nil
    @Published var enhanceManager: EnhanceManager? = nil
    @Published var canvas: MTKCanvas? = nil
    @Published var currentDocument: Document?
    @Published var data: CanvasData? = nil
    
    func loadDocument(document: Document) {
        document.loadLayers()
        canvas = MTKCanvas(frame: CGRect(x: 0, y: 0, width: document.size.width, height: document.size.height))
        //        canvas!.data = CanvasData(canvas: canvas!)
        canvas!.framebufferOnly = false
        canvas!.preferredFramesPerSecond = 120
        canvas!.backgroundColor = .clear
        
        liveImage = LiveImage(document: document)
        canvasManager = CanvasManager(liveImage: liveImage!, document: document, canvas: canvas!)
        enhanceManager = EnhanceManager()
        
//        canvas!.canvasManager = canvasManager
//        canvas!.addObserver(canvasManager!)
        canvasManager!.importData()
        
        currentDocument = document
    }
    
    func unloadDocument(document: Document) {
        liveImage = nil
        canvas = nil
        canvasManager?.canvas = nil
        canvasManager = nil
        enhanceManager = nil
        document.unloadLayers()
    }
    
}

class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastImage: String = "info.bubble"

    var toastOptions = SimpleToastOptions(
       hideAfter: 2,
       animation: .linear(duration: 0.1),
       modifierType: .slide
    )
    
    func showSuccess(message: String) {
        toastMessage = message
        toastImage = "checkmark.circle"
        showToast = true
    }

    func showError(message: String) {
        toastMessage = message
        toastImage = "exclamationmark.circle"
        showToast = true
    }
    
    func showMessage(message: String, image: String = "info.bubble") {
        toastMessage = message
        toastImage = image
        showToast = true
    }
}

struct MainMenu: View {
    @AppStorage("loadedTemplates") var loadedTemplates: Bool = false

    @Environment(\.safeAreaInsets) var safeAreaInsets
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var orientationInfo: OrientationInfo
    @ObservedObject var mainModel = MainModel.shared
    
    @ObservedObject var documentsManager = DocumentManager.shared
    @ObservedObject var paywallManager = PaywallManager.shared
    @ObservedObject var userManager = UserManager.shared
    @ObservedObject var toastManager = ToastManager.shared

    @State var navigationPath = NavigationPath()
    @State var refreshID: UUID = UUID()
    @State var isMenuOpen: Bool = false
    @State var zipWrapper: ZipWrapper?
    @State var deleteAlertPresented: Bool = false
    @State var documentToDelete: Document? = nil
    @State private var sheetHeight: CGFloat = .zero
    @State var statusBarHidden = false
    
    @Namespace private var animation
    
    func closeMenu() {
        withAnimation {
            isMenuOpen = false
        }
    }
    
    var body: some View {
        ZStack {
            ZStack (alignment: .top) {
                contentGrid
                    .zIndex(1)
                
                topBar
                    .zIndex(2)
                
                if isMenuOpen {
                    SidebarMenuView(action: closeMenu)
                        .zIndex(3)
                }
            }
            .background(Color.canvasBackground)
            .onAppear {
//                refreshID = UUID()

                if !loadedTemplates {
                    DocumentManager.shared.importTemplates()
                    loadedTemplates = true
                }
                ReviewRequest.showReview()
                withAnimation {
                    DocumentManager.shared.loadDocuments()
                }
                let showPaywall = UserManager.shared.remoteConfig?.configValue(forKey: "showPaywallOnLaunch").boolValue ?? false
                if showPaywall {
                    PaywallManager.shared.presentPaywall()
                }

            }
            .zIndex(4)

            if mainModel.currentDocument != nil, mainModel.canvasManager != nil, mainModel.liveImage != nil, mainModel.enhanceManager != nil {
                LinkPresenter {
                    ContentView(canvasManager: mainModel.canvasManager!, liveImage: mainModel.liveImage!, enhanceManager: mainModel.enhanceManager!, namespace: animation, document: mainModel.currentDocument!) {
                        withAnimation {
                            DocumentManager.shared.loadDocuments()
                            mainModel.unloadDocument(document: mainModel.currentDocument!)
                            refreshID = UUID()
                            statusBarHidden = false
                        }
                    }
                }
                .zIndex(5)
//                .transition(.slide)
                
            }
            if paywallManager.showModal {
                ZStack {
                    Rectangle()
                        .fill(.controlForeground.opacity(0.5))
                        .onTapGesture {
                            withAnimation {
                                paywallManager.dismissPaywall()
                            }
                        }
                    PaywallView()
                        .frame(width: 400, height: 700)
                        .background(Color.paywallBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                }
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(6)
            }
        }
        .sheet(isPresented: $paywallManager.showSheet, content: {
            PaywallView()
                .background(Color.paywallBackground)
                .overlay {
                    GeometryReader { geometry in
                        Color.clear.preference(key: InnerHeightPreferenceKey.self, value: geometry.size.height)
                    }
                }
                .onPreferenceChange(InnerHeightPreferenceKey.self) { newHeight in
                    sheetHeight = newHeight
                }
                .presentationDetents([.large])
                .zIndex(7)
        })
        .alert(isPresented: $deleteAlertPresented) {
            Alert(
                title: Text("Are you sure you want to delete?"),
                message: Text("Deleting a document can not be undone."),
                primaryButton: .default(
                    Text("Cancel"),
                    action: {
                        
                    }
                ),
                secondaryButton: .destructive(
                    Text("Delete"),
                    action: {
                        guard let documentToDelete else { return }
                        documentToDelete.delete()
                        withAnimation {
                            documentsManager.loadDocuments()
                        }
                    }
                )
            )
            
        }
        .simpleToast(isPresented: $toastManager.showToast, options: toastManager.toastOptions) {
            Label(toastManager.toastMessage, systemImage: toastManager.toastImage)
            .padding()
            .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
            .foregroundColor(Color.foreground)
            .cornerRadius(30)
            .padding(.top)
        }
        .onOpenURL { url in
            navigationPath.removeLast(navigationPath.count)
            DocumentManager.shared.importDocument(url: url)
            withAnimation {
                DocumentManager.shared.loadDocuments()
            }
//            print("Open file", url)
        }
        .statusBarHidden(true)
    }
    
    var topBar: some View {
        HStack(alignment: .bottom, spacing: 16) {
            Button {
                withAnimation {
                    isMenuOpen = true
                }
            } label : {
                ZStack {
                  
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .light))

                        .foregroundColor(.foreground)
                        .padding(16)
                        .contentShape(Rectangle())
                }
                .frame(width: 48, height: 48)
            }
            .background(
                ShinyRect()
            )
            
            if userManager.subscription == .trial {
                Button  {
                    PaywallManager.shared.presentPaywall(force: true)
                } label: {
                    VStack (alignment: .leading) {
                        Text("Your trial usage")
                            .foregroundStyle(Color.foreground)
                        ProgressView(value: Float(userManager.remainingOnboardingTokens) / Float(userManager.totalOnboardingTokens))
                            .tint(.controlForeground)
                    }
                    .frame(minWidth: 100, maxWidth: 200)
                }
                .frame(height: 48)

            } else if userManager.subscription == .none {
                Button(action: {
                    PaywallManager.shared.presentPaywall(force: true)
                }) {
                    Text("Unlock all features")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#6932BC"), Color(hex: "#E06F91")]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(25)
                }
            }
            Spacer(minLength: 0)
            
            //            Button(action: {}) {
            //                Label("From Image", systemImage: "photo")
            //                    .labelStyle(.iconOnly)
            //                    .foregroundStyle(Color.foreground)
            //            }
            //            .buttonStyle(RoundedRectangleButtonStyle())
            
            aspectRatioMenu
        }
        .padding()
        .background {
            TransparentBlurView()
        }
        .ignoresSafeArea(.all)
    }
    
    var contentGrid: some View {
        ScrollView (.vertical, showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: UIDevice.isIPhone ? (orientationInfo.orientation == .portrait ? 2 : 3) : (orientationInfo.orientation == .portrait ? 4 : 5)), spacing: 20) {
                ForEach(documentsManager.documents, id: \.self) { document in
                    DocumentView(namespace: animation, document: document) { [weak mainModel] selectedDocument in
                        withAnimation {
                            mainModel?.loadDocument(document: selectedDocument)
                            statusBarHidden = true
                        }
                    }
                    .padding()
                    .aspectRatio(CGSize(width: 1, height: 1.2), contentMode: .fit)
                    .contextMenu {
                        Button {
                            if let zip = document.export() {
                                zipWrapper = ZipWrapper(url: zip)
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button {
                            let _ = document.duplicate()
                            withAnimation {
                                documentsManager.loadDocuments()
                            }
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            documentToDelete = document
                            deleteAlertPresented = true
//                            print("Delete Button",document.id.uuidString)
                            
                        } label: {
                            Label("Delete", systemImage: "trash.circle")
                        }
                    }
                    .sheet(item: $zipWrapper, onDismiss: {
                        
                    }, content: { zip in
                        ZIPActivityViewController(zipWrapper: zip)
                    })
                    
                }
            }
            .padding(.top, 64)
        }
    }
    
    var aspectRatioMenu: some View {
        Menu {
            ForEach(AspectRatio.allCases, id: \.self) { aspectRatio in
                Button {
                    AnalyticsUtil.logEvent("musepro_create_document")
                    let newDocument = DocumentManager.shared.createDocument(size: aspectRatio.size)
                    withAnimation {
                        mainModel.loadDocument(document: newDocument)
                    }
                    
                } label: {
                    Label(aspectRatio.title, systemImage: aspectRatio.systemImage)
                }
            }
        } label: {
            if UIDevice.isIPhone {
                if userManager.subscription == .none ||  userManager.subscription == .trial {
                    Label("New", systemImage: "plus")
                        .foregroundStyle(Color.foreground)
                } else {
                    Label("New Canvas", systemImage: "plus")
                        .foregroundStyle(Color.foreground)
                        .frame(minWidth: 120)
                }
            } else {
                Label("New Canvas", systemImage: "plus")
                    .foregroundStyle(Color.foreground)
                    .frame(minWidth: 120)
            }
        }
        .buttonStyle(RoundedRectangleButtonStyle())
    }
}

struct TransparentBlurView: UIViewRepresentable {
    typealias UIViewType = UIVisualEffectView

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialLight))

        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        DispatchQueue.main.async {
            if let backdropLayer  = uiView.layer.sublayers?.first {
                backdropLayer.filters?.removeAll(where: { filter in
                    String(describing: filter) != "gaussianBlur"
                })
            }
        }
    }
}


struct ZipWrapper: Identifiable {
    let id = UUID()
    let url: URL
}

struct ZIPActivityViewController: UIViewControllerRepresentable {
    let zipWrapper: ZipWrapper
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [zipWrapper.url], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

struct SidebarTitle: View {
    var text: String
    
    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(Color.foreground)
            .font(.system(.headline))
            .padding(.vertical, 8)
    }
}

struct SidebarMenuButton: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .foregroundStyle(Color.foreground)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 7)
                    .foregroundStyle(.regularMaterial)
            }
        }
    }
}

enum ReviewRequest {
    @AppStorage("runsSinceLastRequest") static var runsSinceLastRequest = 0
    @AppStorage("version") static var version = ""
    static var limit = 10
    
    static func showReview(force: Bool = false) {
        runsSinceLastRequest += 1
        let appBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let currentVersion = "Version \(appVersion), build \(appBuild)"
        
        // Check if the request should be forced or if it's past the limit
        guard force || currentVersion != version || runsSinceLastRequest >= limit else { return }
        
        if let scene = UIApplication.shared.connectedScenes.first(where: {$0.activationState == .foregroundActive}) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            
            // Reset runsSinceLastRequest
            runsSinceLastRequest = 0
            
            // Set version to currentVersion
            version = currentVersion
        }
    }
}

struct SidebarMenuView: View {
    @ObservedObject var userManager = UserManager.shared
    var action: () -> Void
    
    var body: some View {
        HStack () {
            ZStack (alignment: .leading) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    ScrollView (.vertical, showsIndicators: false) {
                        VStack {
                            if userManager.subscription != .pro {
                                SidebarTitle(text: "Upgrade")
                                Button {
                                    PaywallManager.shared.presentPaywall(force: true)
                                } label: {
                                    Image("SubscriptionBanner")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 50)
                                }
                            }
                            SidebarTitle(text: "Muse Pro")
                            //                        Link(destination: URL.generateEmailUrl(email: "hello@styleof.com", subject: "Muse Pro Feedback", body: "Please describe your request below:") ) {
                            
                            Button {
                                #if os(visionOS)
                                   // visionOS code
                                #elseif os(iOS)
                                Intercom.present()
                                #endif
                            } label: {
                                ZStack {
                                    Text("Get Support")
                                        .foregroundStyle(Color.foreground)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .foregroundStyle(.regularMaterial)
                                }
                            }
                            
                            
                            //                        SidebarMenuButton(title: "Advanced Settings") {
                            //                        }
                            //                        SidebarMenuButton(title: "iCloud Sync") {
                            //                        }
                            SidebarMenuButton(title: "Restore Purchases") {
                                Purchases.shared.restorePurchases { customerInfo, error in
                                    if error == nil{
                                        if let ci = customerInfo {
                                            if ci.entitlements["Pro"]?.isActive == true {
                                                UserManager.shared.subscription = .pro
                                            }
                                        } else {
                                            print("CUSTOMER INFO NOT FOUND THIS IS NO BUENO")
                                        }
                                    }
                                }
                            }
                            SidebarMenuButton(title: "Leave a Review") {
                                ReviewRequest.showReview(force: true)
                            }
                            
                            SidebarTitle(text: "Connect")
                            
                            Link(destination: URL.init(string: "https://instagram.com/musepro.app")!) {
                                
                                ZStack {
                                    Text("Instagram")
                                        .foregroundStyle(Color.foreground)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .foregroundStyle(.regularMaterial)
                                }
                                
                            }
                            
                            Link(destination: URL.init(string: "https://x.com/musepro_app")!) {
                                
                                ZStack {
                                    Text("X (Twitter)")
                                        .foregroundStyle(Color.foreground)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .foregroundStyle(.regularMaterial)
                                }
                                
                            }
                            
                            Link(destination: URL.init(string: "https://www.tiktok.com/@musepro.app")!) {
                                
                                ZStack {
                                    Text("TikTok")
                                        .foregroundStyle(Color.foreground)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .foregroundStyle(.regularMaterial)
                                }
                                
                            }
                          
                            SidebarTitle(text: "Privacy and Terms")
                            
                            Link(destination: URL.init(string: "https://bit.ly/muse-pro-tos")!) {
                                
                                ZStack {
                                    Text("Terms of Service")
                                        .foregroundStyle(Color.foreground)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .foregroundStyle(.regularMaterial)
                                }
                                
                            }
                            
                            Link(destination: URL.init(string: "https://bit.ly/muse-pro-privacy")!) {
                                
                                ZStack {
                                    Text("Privacy Policy")
                                        .foregroundStyle(Color.foreground)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding()
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background {
                                    RoundedRectangle(cornerRadius: 7)
                                        .foregroundStyle(.regularMaterial)
                                }
                                
                            }
                        }
                        .padding()
                        .frame(maxHeight: .infinity)
                        
                        
                       
                    }
                    .frame(maxHeight: .infinity)
                    VStack (spacing: 16) {
                        Text("Brought to you by")
                            .font(.system(size: 14))
                        HStack {
                            Link(destination: URL(string: "https://styleof.com")!) {
                                Image("styleof")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 22)
                            }
                            
                            Text("and")
                                .font(.system(size: 12))
                            Link(destination: URL(string: "https://fal.ai")!) {
                                Image("fal")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 22)
                            }
                        }
                        
                        
                    }
                    .padding()
                        VStack {
                            Text("ID: \(UserManager.shared.uid)")
                                .font(.system(size: 12))

                            HStack {
                                if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                                   Text("Version: \(appVersion)")
                                        .font(.system(size: 12))

                                }
                                if let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                                    Text("Build \(buildNumber)")
                                        .font(.system(size: 12))
 
                                }
                            }
                        }
                    .padding(8)
                    .padding(.bottom, 24)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let pasteboard = UIPasteboard.general
                        var version = ""
                        var build = ""
                        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
                            version = appVersion
                        }
                        if let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
                            build = buildNumber
                        }
                        pasteboard.string = "User ID: \(UserManager.shared.uid) Version: \(version) Build: \(build)"
                        ToastManager.shared.showSuccess(message: "Copied")
                    }
                    .opacity(0.5)

                }
            }
            .frame(maxWidth: UIDevice.isIPhone ? .infinity : 320)
            Rectangle()
                .fill(.red.opacity(0.001))
                .frame(maxWidth: UIDevice.isIPhone ? 120 : .infinity)
                .onTapGesture {
                    action()
                }
        }
        .frame(maxWidth: .infinity)
    }
}

struct RoundedRectangleButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 24).fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial))
    }
}

struct RoundedRectangleButtonStyleSM: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(height: 32)
            .background(RoundedRectangle(cornerRadius: 16).fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial))
    }
}

struct RoundedRectangleButtonStyleSMSystem: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(height: 32)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.systemBlue)))
    }
}

enum AspectRatio: CaseIterable {
    case square, squareHD, landscape169, portrait916, landscape43, portrait34//, landscape32, portrait23
    
    var size: CGSize {
        switch self {
            case .square: return CGSize(width: 512, height: 512) // Already divisible by 32
            case .squareHD: return CGSize(width: 768, height: 768) // Already divisible by 32
            case .landscape169: return CGSize(width: 736, height: 416) // Close to 768x432, divisible by 32
            case .portrait916: return CGSize(width: 416, height: 736) // Close to 432x768, divisible by 32
            case .landscape43: return CGSize(width: 672, height: 512) // Close to 680x512, divisible by 32
            case .portrait34: return CGSize(width: 512, height: 672) // Close to 512x680, divisible by 32
        }

    }
    
    //    var size: CGSize {
    //        switch self {
    //        case .square: return CGSize(width: 1024, height: 1024)
    //        case .landscape169: return CGSize(width: 1360, height: 768)
    //        case .portrait916: return CGSize(width: 768, height: 1360)
    //        case .landscape43: return CGSize(width: 1152, height: 864)
    //        case .portrait34: return CGSize(width: 864, height: 1152)
    //        case .landscape32: return CGSize(width: 1152, height: 768)
    //        case .portrait23: return CGSize(width: 768, height: 1152)
    //        }
    //    }
    
    var title: String {
        switch self {
        case .square: return "Square 1:1"
        case .squareHD: return "Square HD 1:1"
        case .landscape169: return "Landscape 16:9"
        case .portrait916: return "Portrait 9:16"
        case .landscape43: return "Landscape 4:3"
        case .portrait34: return "Portrait 3:4"
            //        case .landscape32: return "Landscape 3:2"
            //        case .portrait23: return "Portrait 2:3"
            
        }
        
    }
    
    var systemImage: String {
        switch self {
        case .square: return "square"
        case .squareHD: return "square"
        case .landscape169: return "rectangle.ratio.16.to.9"
        case .portrait916: return "rectangle.ratio.9.to.16"
        case .landscape43: return "rectangle.ratio.4.to.3"
        case .portrait34: return "rectangle.ratio.3.to.4"
            //        case .landscape32: return "rectangle.ratio.4.to.3"
            //        case .portrait23: return "rectangle.ratio.3.to.4"
        }
    }
}

struct DocumentView: View {
    var namespace: Namespace.ID
    let document: Document
    let onSelect: (_ document: Document) -> Void
    var body: some View {
        //        NavigationLink(destination: NavigationLazyView(ContentView(document: document))) {
        Button {
            onSelect(document)
        } label: {
            VStack(spacing: 8) {
                VStack {
                    Spacer()
                    if let data = document.data {
                        Image(data: data)!
                            .resizable()
                            .aspectRatio(document.size.width / document.size.height, contentMode: .fit)
                            .scaledToFit()
                        //                        .frame(width: UIDevice.isIPhone ? 120 : 160)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .matchedGeometryEffect(id: document.id, in: namespace)
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.foreground)
                            .aspectRatio(document.size.width / document.size.height, contentMode: .fit)
                            .scaledToFit()
                            .matchedGeometryEffect(id: document.id, in: namespace)
                        //                        .frame(width: UIDevice.isIPhone ? 120 : 160)
                    }
                    Spacer()
                }
                .aspectRatio(1, contentMode: .fit)
                Text(document.params.prompt)
                    .foregroundStyle(Color.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 8)
                Text("\(String(Int(document.size.width * 2))) x \(String(Int(document.size.height * 2)))px")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.timeIcon)
            }
        }
    }
}

struct BottomContentView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            Spacer()
            content
        }
    }
}

//
//#Preview {
//    MainMenu()
//}
