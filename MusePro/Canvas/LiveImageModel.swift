//
//  ViewModel.swift
//  Huner
//
//  Created by Omer Karisman on 04.12.23.
//

import FalClient
import SwiftUI
import OpenAI
// See https://www.fal.ai/models/latent-consistency-sd/api for API documentation

let OptimizedLatentConsistency = "fal-ai/fast-lcm-diffusion/image-to-image"
//let OptimizedLatentConsistency = "1448702/8c507339-f143-4d28-823d-9d5c8627e4c1"
//let OptimizedLatentConsistency = "fal-ai/lcm"
//let OptimizedLatentConsistency = "fal-ai/fast-lcm-diffusion/image-to-image"
//let OptimizedLatentConsistency = "fal-ai/fast-turbo-diffusion/image-to-image"
let Lightning = "fal-ai/fast-lightning-sdxl/image-to-image"

struct LcmInput: Encodable {
    let model: String
    let prompt: String
    let image: Data
    let imageSize: ImageSize
    let seed: Int
    let syncMode: Bool
    let strength: Float
    let enableSafetyChecks: Bool
    let numInferenceSteps: Int
    let guidanceScale: Float
    let loraURL: String?
    
    enum CodingKeys: String, CodingKey {
        case model = "model_name"
        case prompt
        case image = "image_bytes"
        case imageSize = "image_size"
        case seed
        case syncMode = "sync_mode"
        case strength
        case enableSafetyChecks = "enable_safety_checks"
        case numInferenceSteps = "num_inference_steps"
        case guidanceScale = "guidance_scale"
        case loraURL = "lora_url"
    }
}

struct ImageSize: Encodable {
    let width: Int
    let height: Int
}

struct SDXLInput: Encodable {
    let prompt: String
    let image: Data
    let imageSize: String
    let seed: Int
    let syncMode: Bool
    let strength: Float
    let enableSafetyChecks: Bool
    let numInferenceSteps: Int
    let guidanceScale: Float
//    let loraURL: String?
    
    enum CodingKeys: String, CodingKey {
        case prompt
        case image = "image_bytes"
        case imageSize = "image_size"
        case seed
        case syncMode = "sync_mode"
        case strength
        case enableSafetyChecks = "enable_safety_checks"
        case numInferenceSteps = "num_inference_steps"
        case guidanceScale = "guidance_scale"
//        case loraURL = "lora_url"
    }
}

struct EnhanceInput: Encodable {
    let model: String
    let prompt: String
    let image: String
    let scale: Float
    let creativity: Float
    let detail: Float
    let seed: Int
    let shapePreservation: Float
    let guidanceScale: Float
    let enableSafetyChecks: Bool
    
    enum CodingKeys: String, CodingKey {
        case model = "model_type"
        case prompt
        case image = "image_url"
        case scale
        case creativity
        case detail
        case seed
        case shapePreservation = "shape_preservation"
        case guidanceScale = "guidance_scale"
        case enableSafetyChecks = "enable_safety_checker"
    }
}


//struct LcmImage: Decodable {
//    let url: String
//    let width: Int
//    let height: Int
//}

struct LcmResponse: Decodable {
    let images: [FalImage]
}

class ConnectionManager {
    static let shared = ConnectionManager()
    
    var fal: Client?
    var lcmConnection: TypedRealtimeConnection<LcmInput>?
    var lightningConnection: TypedRealtimeConnection<SDXLInput>?

//    private var imageStreaming: ImageStreaming

    func setupClient(with key: String) {
        //let fal = FalClient.withProxy("http://localhost:3333/api/fal/proxy")
        fal = FalClient.withCredentials(.keyPair(key))
    }
    
    func connect(key: String = "PencilKitDemo", onResult: @escaping ((Result<LcmResponse, Error>) -> Void)) {
        
        guard let fal else { print("Client not set up");
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.connect(key: key, onResult: onResult)
            }
            return
        }
        
//        imageStreaming = ImageStreaming()
        
        if lcmConnection != nil {
            lcmConnection?.close()
        }
        do {
            lcmConnection = try fal.realtime.connect(
                to: OptimizedLatentConsistency,
                connectionKey: key,
                throttleInterval: .never,//.milliseconds(8),
                onResult: onResult)
        } catch {
            print("Fal Connection Error", error)
        }
        
        if lightningConnection != nil {
            lightningConnection?.close()
        }
        
        do {
            lightningConnection = try fal.realtime.connect(
                to: Lightning,
                connectionKey: key,
                throttleInterval: .milliseconds(250),
                onResult: onResult)
        } catch {
            print("Fal Connection Error", error)
        }
    }
}

class LiveImage: ObservableObject {
    
    let document: Document
    
    @Published var fps: Int = 0
    var lastUpdateTime: TimeInterval = CACurrentMediaTime()
    
    
    init(document: Document) {
        
        self.document = document
        self.prompt = document.params.prompt
        self.strength = document.params.strength
        self.cfg = document.params.cfg
        self.seed = document.params.seed

        ConnectionManager.shared.connect(key: document.id.uuidString + UUID().uuidString, onResult: { result in
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                
                if case let .success(payload) = result
                    {
                    
                    guard let image = payload.images.first else {
                        print("No image available in response")
                        return
                    }
                    
                    var data: Data?
                    switch image.content {
                    case let .url(url):
                        let url = URL(string: url)!
                        data = try? Data(contentsOf: url)
                    case let .raw(imageData):
                        data = imageData
                    }
                    guard let data else {
                        print("Image data is nil")
                        return
                    }
                    
                    guard data.count > 8000 else { return }
                    strongSelf.currentImage = data
                    strongSelf.counter += 1
                    
                    if strongSelf.saveState {
                        strongSelf.saveState = false
                        strongSelf.document.data = data
                        strongSelf.document.saveDocumentData()
                    }
                }
                if case let .failure(error) = result {
                    print(error)
                }
            }
        })
    }
    
    @Published var currentImage: Data?
    var lastDrawing: Data?
    @Published var renderMode: RenderMode = .fast
    
    @Published var seed: Int = 6_252_023 {
        didSet {
            if seed != oldValue {
                if renderMode == .fast {
                    redraw()
                }
            }
        }
    }
    @Published var prompt: String = ""
    {
        didSet {
            if prompt != oldValue {
                if renderMode == .fast {
                    redraw()
                }
            }
        }
    }
    
    @Published var strength: Float = 0.70
    {
        didSet {
            if strength != oldValue {
                if renderMode == .fast {
                    redraw()
                }
            }
        }
    }
    
    @Published var cfg: Float = 1.5 //1 for lcm 0 for lightning
    {
        didSet {
            if cfg != oldValue {
                if renderMode == .fast {
                    redraw()
                }
            }
        }
    }
    let generationQueue = DispatchQueue(label: "GenerationQueue", qos: .userInitiated)

    @Published var counter: Int = 0
    @Published var counter_alt: Int = 0
    @Published var modelUrl: String? = "YOUR_MODEL_URL"
    @Published var enabled: Bool = true {
        didSet {
            if enabled {
                generationQueue.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.redraw()
                }
            }
        }
    }
    @Published var enhancing: Bool = false
    @Published var removing: Bool = false
    @Published var inferenceSteps: Int = 2

    
    var lastStrength: Float = 0.75
    func setStrength() {
        let updateStrengthCmd = UpdateStrengthCommand(liveImage: self, oldStrength: lastStrength, newStrength: strength)
        CommandManager.shared.executeCommand(updateStrengthCmd)
        lastStrength = strength
        saveParams()
        redraw()
    }
    
    var lastPrompt: String = ""
    func setPrompt() {
        if lastPrompt == prompt {
            return
        }
        let updatePromptCmd = UpdatePromptCommand(liveImage: self, oldPrompt: lastPrompt, newPrompt: prompt)
        CommandManager.shared.executeCommand(updatePromptCmd)
        lastPrompt = prompt
        saveParams()
        redraw()
    }
    
    func shuffleSeed() {
        let updateSeedCmd = UpdateSeedCommand(liveImage: self, newSeed: Int.random(in: 0..<10_000_000))
        CommandManager.shared.executeCommand(updateSeedCmd)
        saveParams()
        redraw()
    }
    
    func saveParams() {
        document.params.prompt = prompt
        document.params.strength = strength
        document.params.cfg = cfg
        document.params.seed = seed
        document.data = currentImage
        document.saveMetadata()
    }
    
    var lastNis: Int = 4 

    func redraw() {
        if let lastDrawing {
            generate(drawing: lastDrawing, save: true, num_inference_steps: lastNis)
        }
    }
    
    //    func disconnect() {
    //        if let connection {
    //            connection
    //        }
    //    }
    
    var saveState: Bool = true
    
    var model: Model = .lcm
    
    let layerSavingQueue = DispatchQueue(label: "LayerSavingQueue", qos: .userInitiated)

    func generate(drawing: Data, save: Bool = false, num_inference_steps: Int = 4) {
        guard enabled else { return }

        lastDrawing = drawing
        lastNis = num_inference_steps
        saveState = save
        
        generationQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            
            let str = (strongSelf.strength * 100).rounded() / 100.0
            let imageSize = ImageSize(width: Int(strongSelf.document.size.width), height: Int(strongSelf.document.size.height))

            if strongSelf.model == .lcm || strongSelf.model == .sdxl {
                let sdModel = strongSelf.model == .lcm ? "runwayml/stable-diffusion-v1-5" : "stabilityai/stable-diffusion-xl-base-1.0"
                let request = LcmInput(
                    model: sdModel,
                    prompt: strongSelf.prompt,
                    image: drawing,
                    imageSize: imageSize,
                    seed: strongSelf.seed, // + Int(strongSelf.strength * 100),
                    syncMode: true,
                    strength: Float(str),
                    enableSafetyChecks: false,
                    numInferenceSteps: num_inference_steps,
                    guidanceScale: strongSelf.cfg,
                    loraURL: strongSelf.modelUrl
                )
                
                do {
                    try ConnectionManager.shared.lcmConnection?.send(request)
                } catch {
                    DispatchQueue.main.async {
                        print("Generate AI Error:", error)
                    }
                }
            }
            
//            if strongSelf.model == .lightning {
//                let request = SDXLInput(
//                    prompt: strongSelf.prompt,
//                    image: drawing,
//                    imageSize: "square_hd",
//                    seed: strongSelf.seed,
//                    syncMode: true,
//                    strength: Float(str),
//                    enableSafetyChecks: false,
//                    numInferenceSteps: num_inference_steps,
//                    guidanceScale: 0
//                )
//                print(request)
//                do {
//                    try ConnectionManager.shared.lightningConnection?.send(request)
//                } catch {
//                    DispatchQueue.main.async {
//                        print("Generate AI Error:", error)
//                    }
//                }
//            }
            
          
        }
    }
    
    
    let openAI = OpenAI(apiToken: "YOUR_OPENAI_API_KEY")
    
    
    func enhancePrompt() {
        
        Task {
            let content = [Chat.ContentElement.text("Do what I say without commenting on it or adding any formatting. Enhance the image prompt provided, just like a dall-e 3 prompt. Be very descriptive but you don't need directives like 'generate' or real sentence structures, we just need keywords. Try to limit to 70 words but be as descriptive as possible, don't include any formatting or special characters, I need only the prompt. Don't start with 'Existing Prompt' or similar pretext")]
            let content2 = [Chat.ContentElement.text("Existing Prompt: \(self.prompt)")]
            
            let query = ChatQuery(model: .gpt4, messages: [
                .init(role: .system, content: content),
                .init(role: .user, content: content2)
            ])
            self.prompt = ""
            openAI.chatsStream(query: query) { partialResult in
                switch partialResult {
                case .success(let result):
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        
                        withAnimation {
                            strongSelf.prompt = strongSelf.prompt + (result.choices[0].delta.content ?? "").replacingOccurrences(of: "\"", with: "")
                        }
                    }
                case .failure(_): break
                    //Handle chunk error here
                }
            } completion: { error in
                // Handle streaming error
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.setPrompt()
                }
            }
        }
    }
    
    func translatePrompt() {
        
        Task {
            let content = [Chat.ContentElement.text("Do what I say without commenting on it or adding any formatting. Translate the image prompt provided to English, just like a dall-e 3 prompt. Be very descriptive but you don't need directives like 'generate' or real sentence structures, we just need keywords. Try to limit to 70 words but be as descriptive as possible, don't include any formatting or special characters, I need only the prompt. Don't start with 'Existing Prompt' or similar pretext")]
            let content2 = [Chat.ContentElement.text("Existing Prompt: \(self.prompt)")]
            
            let query = ChatQuery(model: .gpt4, messages: [
                .init(role: .system, content: content),
                .init(role: .user, content: content2)
            ])
            self.prompt = ""
            openAI.chatsStream(query: query) { partialResult in
                switch partialResult {
                case .success(let result):
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        
                        withAnimation {
                            strongSelf.prompt = strongSelf.prompt + (result.choices[0].delta.content ?? "").replacingOccurrences(of: "\"", with: "")
                        }
                    }
                case .failure(_): break
                    //Handle chunk error here
                }
            } completion: { error in
                // Handle streaming error
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.setPrompt()
                }
            }
        }
    }
    
    func randomPrompt() {
        deltaLength = 0
        Task {
            let content = [Chat.ContentElement.text("Do what I say without commenting on it. Create a random image prompt, just like a dall-e 3 prompt. Describe a picture of a random topic. It can be an object a sceneray a theme, anything. Be very descriptive but you don't need directives like 'generate' or real sentence structures, we just need keywords. Try to limit to 70 words but be as descriptive as possible. Don't use Victorian era at all.")]
            let seed = Int.random(in: 0..<10_000_000)

            let content2 = [Chat.ContentElement.text("Create a prompt on a random topic, choose the topic with seed: \(seed)")]
            
            let query = ChatQuery(model: .gpt4, messages: [
                .init(role: .system, content: content),
                .init(role: .user, content: content2)
            ], temperature: 0.8)
            self.prompt = ""
            openAI.chatsStream(query: query) { partialResult in
                switch partialResult {
                case .success(let result):
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        
                        withAnimation {
                            strongSelf.prompt = strongSelf.prompt + (result.choices[0].delta.content ?? "").replacingOccurrences(of: "\"", with: "")
//                            strongSelf.applyDeltaUpdate((result.choices[0].delta.content ?? "").replacingOccurrences(of: "\"", with: ""))
                        }
                    }
                case .failure(_): break
                    //Handle chunk error here
                }
            } completion: { error in
                // Handle streaming error
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
//                    strongSelf.endDeltaUpdate()
                    strongSelf.setPrompt()
                }
            }
        }
    }
    
    var deltaLength = 0
    
//    func applyDeltaUpdate(_ delta: String) {
//        let startIndex = self.prompt.startIndex
//        let endIndex = self.prompt.endIndex
//
//        if deltaLength >= 0 && deltaLength < self.prompt.count {
//            let start = self.prompt.index(startIndex, offsetBy: deltaLength)
//            let end = self.prompt.index(start, offsetBy: min(delta.count, self.prompt.distance(from: start, to: endIndex)))
//            
//            if delta.count <= self.prompt.distance(from: start, to: endIndex) {
//                self.prompt.replaceSubrange(start...end, with: delta)
//            } else {
//                let replaceCount = min(delta.count, self.prompt.distance(from: start, to: endIndex) - 1)
//                let replaceRange = start...self.prompt.index(start, offsetBy: replaceCount)
//                let remainingDelta = delta.suffix(delta.count - replaceCount)
//                
//                self.prompt.replaceSubrange(replaceRange, with: delta.prefix(replaceCount))
//                self.prompt += remainingDelta
//            }
//        } else {
//            self.prompt += delta
//        }
//        
//        deltaLength += delta.count
//       
//    }
//    
//    func endDeltaUpdate() {
//        if deltaLength < self.prompt.count {
//            let startIndex = self.prompt.startIndex
//            let endIndex = self.prompt.endIndex
//            
//            let start = self.prompt.index(startIndex, offsetBy: deltaLength)
//            let end = endIndex
//            
//            self.prompt.removeSubrange(start..<end)
//        }
//        
//        deltaLength = 0
//    }
    
    func visionPrompt(onFinished: @escaping () -> Void) {
        
        Task {
            let base64 = self.lastDrawing?.base64EncodedString()
            let content = [Chat.ContentElement.text("Do what I say without commenting on it. Create an image prompt, just like a dall-e 3 prompt based on what you see in the image. Image will be hand drawn, I want you to describe what it means to represent. So if it's a stick figure it's probably a person. Be very descriptive but you don't need directives like 'generate' or real sentence structures, we just need keywords. Try to limit to 70 words but be as descriptive as possible")]
            let content2 = [Chat.ContentElement.text("Describe the drawing in the image with keywords like color, object names, mood, style just like a dall-e 3 prompt, Try to limit to 70 words but be as descriptive as possible"), Chat.ContentElement.imageUrl("data:image/png;base64,\(base64!)")]
            let query = ChatQuery(model: .gpt4_vision_preview, messages: [
                .init(role: .system, content: content),
                .init(role: .user, content: content2)
            ], maxTokens: 1000)
            self.prompt = ""
            
            openAI.chatsStream(query: query) { partialResult in
                switch partialResult {
                case .success(let result):
                    onFinished()
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        
                        withAnimation {
                            strongSelf.prompt = strongSelf.prompt + (result.choices[0].delta.content ?? "").replacingOccurrences(of: "\"", with: "")
                        }
                    }
                case .failure(let error):
                    print("Vision Prompt Error:", error)
                }
                
            } completion: { error in
                if error != nil {
                    print("Vision Prompt Error:", error!.localizedDescription)
                }
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.setPrompt()
                }
            }
        }
    }
    
    func enhance(data: Data, scale: Float = 2.0, prompt: String = "", seed: Int = 42, guidance: Float = 7.5, creativity: Float = 0.1, detail: Float = 1.0, preservation: Float = 0.5, onComplete: @escaping (_ image: Data?)->()) {
        guard let fal = ConnectionManager.shared.fal else { print("Client not set up"); return }
        
        self.enhancing = true
        
        
        guard data.count < 4_000_000 else { onComplete(nil); return }
        //        let image = UIImage(data: data)
        
        Task {
            do {
                let result = try await fal.subscribe(
                    to: "fal-ai/creative-upscaler",
                    input: [
                        "model_type": "SD_1_5", //"SDXL"
                        "prompt": .string(prompt),
                        "image_url": .string("data:image/jpeg;base64,\(data.base64EncodedString())"),
                        "scale": .double(Double(scale)),
                        "creativity": .double(Double(creativity)),
                        "detail": .double(Double(detail)),
                        "shape_preservation": .double(Double(preservation)),
                        "seed": .int(seed),
                        "guidance_scale": .double(Double(guidance)),
                        "override_size_limits": true,
                        "enable_safety_checks": false
                    ],
                    pollInterval: .seconds(2),
                    timeout: .minutes(5),
                    includeLogs: true
                ) { update in
                    update.logs
                        .filter { log in !log.message.isEmpty }
                        .forEach { log in
                            print("Enhance Log:",log.message)
                        }
                }
                if case let .string(url) = result["image"]["url"] {
                    let data = try? Data(contentsOf: URL(string: url)!)
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        
                        
                        //                        self.currentImage = data
                        //                        let image = UIImage(data: self.currentImage!)
                        
                        //                        let imageSaver = ImageSaver()
                        //                        imageSaver.writeToPhotoAlbum(image: image)
                        strongSelf.enhancing = false
                        onComplete(data)
                    }
                } else {
                    print("Unknown AI error", result)
                    self.enhancing = false
                    onComplete(nil)
                }
            } catch {
                print("Unknown AI error", error)
                self.enhancing = false
                onComplete(nil)
            }
        }
    }
    //
    //    func enhance(isDrawing: Bool = false, creativity: Float = 0.1, detail: Float = 1.0, preservation: Float = 0.5, onComplete: @escaping (_ image: Data?)->()) {
    //        guard let fal = ConnectionManager.shared.fal else { print("Client not set up"); return }
    //
    //        self.enhancing = true
    //
    //        let imageToEnhance = isDrawing ? self.lastDrawing : self.currentImage
    //
    //        guard let drawing = imageToEnhance else { return }
    //        guard drawing.count < 4_000_000 else { onComplete(nil); return }
    //        let image = UIImage(data: drawing)
    //
    //        Task {
    //            do {
    //                let result = try await fal.subscribe(
    //                    to: "fal-ai/creative-upscaler",
    //                    input: [
    //                        "prompt": .string(prompt),
    //                        "image_url": .string("data:image/jpeg;base64,\(drawing.base64EncodedString())"),
    //                        "scale": .double(2),
    //                        "creativity": .double(Double(creativity)),
    //                        "detail": .double(Double(detail)),
    //                        "shape_preservation": .double(Double(preservation)),
    //                        "seed": .int(seed),
    //                        "guidance_scale": .double(8),
    //                        "enable_safety_checks": false
    //                    ],
    //                    pollInterval: .seconds(2),
    //                    timeout: .minutes(5),
    //                    includeLogs: true
    //                ) { update in
    //                    update.logs
    //                        .filter { log in !log.message.isEmpty }
    //                        .forEach { log in
    //                            print("Enhance Log:",log.message)
    //                        }
    //                }
    //                if case let .string(url) = result["image"]["url"] {
    //                    let data = try? Data(contentsOf: URL(string: url)!)
    //                    DispatchQueue.main.async {
    //
    //                        self.currentImage = data
    //                        let image = UIImage(data: self.currentImage!)
    //
    ////                        let imageSaver = ImageSaver()
    ////                        imageSaver.writeToPhotoAlbum(image: image)
    //                        self.enhancing = false
    //                        onComplete(data)
    //                    }
    //                } else {
    //                    print("Unknown AI error", result)
    //                    self.enhancing = false
    //                    onComplete(nil)
    //                }
    //            } catch {
    //                print("Unknown AI error", error)
    //                self.enhancing = false
    //                onComplete(nil)
    //            }
    //        }
    //    }
    
    func removeBg(data: Data, onComplete: @escaping (Data?)->()) {
        guard let fal = ConnectionManager.shared.fal else { print("Client not set up"); return }
        
        self.removing = true
        Task {
            do {
                let result = try await fal.subscribe(
                    to: "fal-ai/imageutils/rembg",
                    input: [
                        "image_url": .string("data:image/jpeg;base64,\(data.base64EncodedString())"),
                    ],
                    pollInterval: .seconds(2),
                    timeout: .minutes(5),
                    includeLogs: true
                ) { update in
                    update.logs
                        .filter { log in !log.message.isEmpty }
                        .forEach { log in
                            print("Enhance Log:",log.message)
                        }
                }
                if case let .string(url) = result["image"]["url"] {
                    let data = try? Data(contentsOf: URL(string: url)!)
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        
                        onComplete(data)
                        strongSelf.removing = false
                    }
                } else {
                    print("Unknown AI error", result)
                    onComplete(nil)
                    self.removing = false
                }
            } catch {
                print("Unknown AI error", error)
                onComplete(nil)
                self.removing = false
            }
        }
        
    }
}
