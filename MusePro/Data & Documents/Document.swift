//
//  Document.swift
//  MusePro
//
//  Created by Omer Karisman on 11.02.24.
//

import Foundation

struct DocumentMetadata: Codable {
    let id: UUID
    let size: CGSize
    let createdAt: Date
    var updatedAt: Date
    var params: Params
    var backgroundColor: MLColor?
    var brushOpacity: CGFloat?
    var brushSize: CGFloat?
    var brushColor: MLColor?
    var brushName: String?
    var layers: [LayerData]
}

class Document: Codable, Identifiable, Hashable {
    static func == (lhs: Document, rhs: Document) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    let id: UUID
    let size: CGSize
    let createdAt: Date
    var updatedAt: Date
    var params: Params
    var backgroundColor: MLColor? = .white
    var brushOpacity: CGFloat? = 0.5
    var brushSize: CGFloat? = 0.5
    var brushColor: MLColor? = .white
    var brushName: String? = "Medium Airbrush"

    var layers: [LayerData]
    @CodableIgnored var data: Data?

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    static var cachesURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    init(id: UUID = UUID(), size: CGSize, createdAt: Date = Date(), updatedAt: Date = Date(), params: Params = Params(prompt: "", strength: 0.75, cfg: 0, seed: 6_252_023), backgroundColor: MLColor? = nil, brushOpacity: CGFloat? = 0.5, brushSize: CGFloat? = 0.5, brushColor: MLColor? = .black, brushName: String? = "Medium Airbrush", layers: [LayerData] = [LayerData](), data: Data? = nil) {
        self.id = id
        self.size = size
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.params = params
        self.backgroundColor = backgroundColor
        self.brushOpacity = brushOpacity
        self.brushSize = brushSize
        self.brushColor = brushColor
        self.brushName = brushName
        self.layers = layers
        self.data = data
        
        createDocumentFolder()
        saveMetadata()
    }
    
    func createDocumentFolder() {
        let documentDirectoryURL = Document.documentsURL.appendingPathComponent(self.id.uuidString)
        do {
            try FileManager.default.createDirectory(at: documentDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating document directory: \(error)")
        }
    }

    func saveMetadata() {
        let metadata = DocumentMetadata(
            id: self.id,
            size: self.size,
            createdAt: self.createdAt,
            updatedAt: Date(),
            params: self.params,
            backgroundColor: self.backgroundColor,
            brushOpacity: self.brushOpacity,
            brushSize: self.brushSize,
            brushColor: self.brushColor,
            brushName: self.brushName,
            layers: self.layers
        )

        let documentDirectoryURL = Document.documentsURL.appendingPathComponent(metadata.id.uuidString)
        Storage.store(metadata, to: .documents(subfolder: documentDirectoryURL.lastPathComponent), as: "document.json")
    }
    
    @CodableIgnored var task: Task<(), Never>?

    func debounce(interval: Duration = .nanoseconds(10000),
                  operation: @escaping () -> Void) {
        task?.cancel()

        task = Task {
            do {
                try await Task.sleep(for: interval)
                operation()
            } catch {
                // TODO
            }
        }
    }
    
    func saveDocumentData() {
//        print("Saving document data")
        if let documentData = self.data {
            debounce(interval: .seconds(1)) {
                self.saveDataBlob(data: documentData, with: self.id)
            }
        } else {
            print("Unable to save document data because self.data is empty")
        }
    }

    func saveLayerData(layer: Layer? = nil) {
//        print("Saving layer data")
        saveMetadata()
        if let layer {
            if let layerData = layer.snapshot {
                saveDataBlob(data: layerData, with: layer.id)
            } else {
                print("Unable to save layer data because layer.data is empty")
            }
        } else {
            layers.forEach { layer in
                if let layerData = layer.data {
                    saveDataBlob(data: layerData, with: layer.id)
                } else {
                    print("Unable to save layer data because layer.data is empty")
                }
            }
        }
    }
    
    func export() -> URL? {
        let documentPath = Document.documentsURL.appendingPathComponent(id.uuidString)
        let zipPath = Document.cachesURL.appendingPathComponent(id.uuidString + ".musepro")
        if FileManager.default.fileExists(atPath: zipPath.path(percentEncoded: true)) {
            do {
                try FileManager.default.removeItem(atPath: zipPath.path(percentEncoded: true))
            } catch {
                print("Unable to remove existing zip \(error)")
            }
        }
        do {
            try FileManager.default.zipItem(at: documentPath, to: zipPath)
            return zipPath
        } catch {
            print("Unable to zip document directory \(error)")
        }
        return nil
    }
    
    func delete() {
        let documentDirectoryURL = Document.documentsURL.appendingPathComponent(self.id.uuidString)
        do {
            try FileManager.default.removeItem(at: documentDirectoryURL)
//            print("Document directory successfully deleted.")
        } catch {
            print("Error deleting document directory: \(error)")
        }
    }

    func loadData() {
        self.data = loadDataBlob(with: self.id)
    }
    
    func loadLayers() {
        self.layers = self.layers.map { layer in
            let updatedLayer = layer
            updatedLayer.data = loadDataBlob(with: layer.id)
            return updatedLayer
        }
    }
    
    func unloadLayers() {
        self.layers = self.layers.map { layer in
            let updatedLayer = layer
            updatedLayer.data = nil
            return updatedLayer
        }
    }

    func saveDataBlob(data: Data, with id: UUID, compress: Bool = true) {
        let dataPath = Document.documentsURL.appendingPathComponent(self.id.uuidString).appendingPathComponent(id.uuidString + ".data")
        let compressedDataPath = Document.documentsURL.appendingPathComponent(self.id.uuidString).appendingPathComponent(id.uuidString + ".lz4")

        if compress {
            let compressedData: Data! = data.compress(withAlgorithm: .lz4)

           let ratio = Double(data.count) / Double(compressedData.count)
            
            do {
                try compressedData.write(to: compressedDataPath)
//                print("Data blob was successfully saved for id: \(id.uuidString) with compression ratio: \(ratio)")
            } catch {
                print("Failed to save data blob for id: \(id.uuidString). Error: \(error.localizedDescription)")
            }
            
        } else {
            do {
                try data.write(to: dataPath)
//                print("Data blob was successfully saved for id: \(id.uuidString)")
            } catch {
                print("Failed to save data blob for id: \(id.uuidString). Error: \(error.localizedDescription)")
            }
        }
    }

    func loadDataBlob(with id: UUID) -> Data? {
        let dataPath = Document.documentsURL.appendingPathComponent(self.id.uuidString).appendingPathComponent(id.uuidString + ".data")
        let compressedDataPath = Document.documentsURL.appendingPathComponent(self.id.uuidString).appendingPathComponent(id.uuidString + ".lz4")
        
        if FileManager.default.fileExists(atPath: dataPath.path(percentEncoded: true)) {
//            print("Uncompressed data exists")
            do {
                let data = try Data(contentsOf: dataPath)
//                print("Data blob was successfully loaded for id: \(id.uuidString)")
                return data
            } catch {
                print("Failed to load data blob for id: \(id.uuidString). Error: \(error.localizedDescription)")
                return nil
            }
        } else if FileManager.default.fileExists(atPath: compressedDataPath.path(percentEncoded: true)) {
//            print("Compressed data exists")
            do {
                let compressedData = try Data(contentsOf: compressedDataPath)
//                print("Compressed data blob was successfully loaded for id: \(id.uuidString)")
                let data = compressedData.decompress(withAlgorithm: .lz4)
                return data
            } catch {
                print("Failed to load data blob for id: \(id.uuidString). Error: \(error.localizedDescription)")
                return nil
            }
        }
//        print("Neither compressed nor uncompressed data exists!", id.uuidString)

        return nil
    }
}

class LayerData: Codable {
    var id: UUID
    var index: Int
    var blendMode: BlendMode?
    var opacity: Float?
    var hidden: Bool?
    @CodableIgnored var data: Data?
    
    init(id: UUID, index: Int, blendMode: BlendMode = .add, opacity: Float = 1.0, hidden: Bool = false, data: Data? = nil) {
        self.id = id
        self.index = index
        self.blendMode = blendMode
        self.opacity = opacity
        self.hidden = hidden
        self.data = data
    }
}

class Params: Codable {
    var prompt: String
    var strength: Float
    var cfg: Float
    var seed: Int
    
    init(prompt: String, strength: Float, cfg: Float, seed: Int) {
        self.prompt = prompt
        self.strength = strength
        self.cfg = cfg
        self.seed = seed
    }
}

class DocumentManager: ObservableObject {
    static let shared = DocumentManager()
    
    var documentsURL: URL {
//        let containerIdentifier = "iCloud.com.styleof.musepro.iCloudDocuments"
//        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
//            print("Can't get UbiquityContainer url")
//            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        }
//
//       return containerURL.appendingPathComponent("Documents")
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
//    var localDocumentsURL: URL {
//        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//    }
    
    @Published var documents: [Document] = [Document]()
    
    init() {
        loadDocuments()
    }
    
    func createDocument(size: CGSize) -> Document {
        let document = Document(size: size)
        documents.insert(document, at: 0)
        return document
    }

    func loadDocuments() {
        self.documents = getDocuments()

//        let fileManager = FileManager.default
//        
//        do {
//            // Get current documents
//            
//            // Recursive function to copy files and directories
//            func recursiveCopy(from sourceURL: URL, to destinationURL: URL) throws {
//                let contents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
//                
//                for item in contents {
//                    let itemDestinationURL = destinationURL.appendingPathComponent(item.lastPathComponent)
//                    
//                    var isDirectory: ObjCBool = false
//                    guard fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) else { continue }
//                    
//                    if isDirectory.boolValue {
//                        // If it's a directory, create it and recurse
//                        try fileManager.createDirectory(at: itemDestinationURL, withIntermediateDirectories: true, attributes: nil)
//                        try recursiveCopy(from: item, to: itemDestinationURL)
//                    } else {
//                        // If it's a file, copy it if it doesn't exist or is different
//                        if !fileManager.fileExists(atPath: itemDestinationURL.path) ||
//                           !fileManager.contentsEqual(atPath: item.path, andPath: itemDestinationURL.path) {
//                            try fileManager.copyItem(at: item, to: itemDestinationURL)
//                            print("Copied \(item.lastPathComponent)")
//                        }
//                    }
//                }
//            }
//            
//            // Perform the recursive copy
//            try recursiveCopy(from: localDocumentsURL, to: documentsURL)
//            
//            // Reload documents after copying
//            self.documents = getDocuments()
//            print("Reloaded documents after copying")
//        } catch {
//            print("Error while processing files: \(error.localizedDescription)")
//        }
    }
    
    func importTemplates() {
        let templatesPath = Bundle.main.resourceURL!.appendingPathComponent("Templates").path
        let templates = FileManager.default.listFiles(path: templatesPath)
        templates.forEach { template in
           importDocument(url: template)
        }
    }
    
    func importDocument(url: URL) {
        let destinationURL = documentsURL
        do {
            _ = url.startAccessingSecurityScopedResource()

            try FileManager.default.unzipItem(at: url, to: destinationURL)
            
            url.stopAccessingSecurityScopedResource()

            loadDocuments()
        } catch {
            print("Error importing document: \(error)")
        }
       
    }
    
    func getDocuments() -> [Document] {
        guard let projectDirectories = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) else {
            return []
        }

        let documents = projectDirectories.compactMap { directoryURL -> Document? in
            guard UUID(uuidString: directoryURL.lastPathComponent) != nil else {
                return nil
            }
            return Storage.retrieve("document.json", from: .documents(subfolder: directoryURL.lastPathComponent), as: Document.self)
        }
        
        documents.forEach { document in
            document.loadData()
        }

        return documents.sorted { lhs, rhs in
            return lhs.updatedAt > rhs.updatedAt
        }
    }
}

extension Document {
    func duplicate() -> Document {
        loadData()
        loadLayers()
        
        let duplicatedDocument = Document(size: self.size, createdAt: Date(), updatedAt: Date(), params: self.params, backgroundColor: self.backgroundColor, brushOpacity: self.brushOpacity, brushSize: self.brushSize, brushColor: self.brushColor, brushName: self.brushName, layers: self.layers.map { $0.duplicate() }, data: self.data)
        duplicatedDocument.saveDocumentData()
        duplicatedDocument.saveLayerData()
        return duplicatedDocument
    }
}

extension LayerData {
    func duplicate() -> LayerData {
        // Create a new LayerData instance with a new ID but copying other properties
        return LayerData(id: UUID(), index: self.index, blendMode: self.blendMode ?? .add, opacity: self.opacity ?? 1.0, hidden: self.hidden ?? false, data: self.data)
    }
}
