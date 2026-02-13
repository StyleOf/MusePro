//
//  BrushPickerView.swift
//  MusePro
//
//  Created by Omer Karisman on 22.01.24.
//

import SwiftUI
import ZIPFoundation

struct BrushSet: Identifiable {
    var id: String
    var name: String
    var brushes: [PCBrush]
    
    static func == (lhs: BrushSet, rhs: BrushSet) -> Bool {
        return lhs.id == rhs.id
    }
}

class BrushManager: ObservableObject {
    static let shared = BrushManager()
    @Published var brushSets = [BrushSet]()
    @Published var selectedBrushSet: BrushSet?
    @Published var recentBrushes: BrushSet
    var defaultBrush: PCBrush?
    
    init() {
        let defaultBrushSetsPath = Bundle.main.resourceURL!.appendingPathComponent("BrushSets").path
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        let loadedBrushSetsPath = docURL.appendingPathComponent("BrushSets")
        if !FileManager.default.fileExists(atPath: loadedBrushSetsPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: loadedBrushSetsPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        let defaultBrushSetsArchives = FileManager.default.listFiles(path: defaultBrushSetsPath)
        recentBrushes = BrushSet(id: "Recent", name: "Recent Brushes", brushes: [])
        brushSets = [recentBrushes]
        defaultBrushSetsArchives.forEach { path in
            let loadedBrushSet = loadBrushset(from: path, to: URL(fileURLWithPath: "\(loadedBrushSetsPath)/\(path.lastPathComponent)"))
            brushSets.append(loadedBrushSet)
        }
    }
    
    func decodeBrush(url: URL) -> PCBrush? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Decode Brush Error: File does not exist at the path")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            NSKeyedUnarchiver.setClass(PCBrush.self, forClassName: "SilicaBrush")

            let unarchivedObject = try NSKeyedUnarchiver.unarchivedObject(ofClass: PCBrush.self, from: data)

            unarchivedObject?.archiveURL = url.deletingLastPathComponent()

            return unarchivedObject
        } catch {
            print("Decode Brush Error: \(error)")
            return nil
        }
    }
    
    func loadBrushset(from: URL, to: URL) -> BrushSet {
        if !FileManager.default.fileExists(atPath: to.path) {
            do {
                try FileManager.default.unzipItem(at: from, to: to)
                
            } catch {
                print("Unzip BrushSet Error:: \(error)")

            }
        }
        let brushesToLoad = FileManager.default.listFiles(path: to.path)
        var loadedBrushes = [PCBrush]()
        brushesToLoad.forEach { brushPath in
            if brushPath.absoluteString.contains(".plist") {
                return
            }
            let brushArchivePath = brushPath.appendingPathComponent("Brush.archive")
            let brushPreviewPath = brushPath.appendingPathComponent("QuickLook/Thumbnail.png")
            if let brushObject = decodeBrush(url: brushArchivePath) {
                brushObject.bundledGrainPath = brushObject.bundledGrainPath
                brushObject.bundledHeightPath = brushObject.bundledHeightPath
                brushObject.bundledMetallicPath = brushObject.bundledMetallicPath
                brushObject.bundledRoughnessPath = brushObject.bundledRoughnessPath
                brushObject.bundledShapePath = brushObject.bundledShapePath
                brushObject.previewPath = brushPreviewPath.path

                loadedBrushes.append(brushObject)
                if brushObject.name == "Soft Brush" {
                    defaultBrush = brushObject
                    addRecentBrush(recentBrush: brushObject)
                }
            }
        }
        let brushSetName = to.lastPathComponent.replacingOccurrences(of: ".brushset", with: "")
        let brushSet = BrushSet(id: UUID().uuidString, name: brushSetName, brushes: loadedBrushes)
        return brushSet
    }
    
    func addRecentBrush(recentBrush: PCBrush) {
        recentBrushes.brushes.removeAll { brush in
            brush.name == recentBrush.name
        }
        recentBrushes.brushes.insert(recentBrush, at: 0)
        
        if recentBrushes.brushes.count > 20 {
            recentBrushes.brushes.removeLast()
        }
        
        print(recentBrushes)
    }
    
    func findBrushByName(_ name: String) -> PCBrush? {
        var foundBrush: PCBrush? = nil
        brushSets.forEach { brushSet in
            brushSet.brushes.forEach { brush in
                if brush.name == name {
                    foundBrush = brush
                    return
                }
            }
        }
        return foundBrush
    }
}

struct BrushLibrary: View {
    @EnvironmentObject var orientationInfo: OrientationInfo
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var brushManager = BrushManager.shared
//    let categories: [String] = ["Sketching", "Inking", "Drawing", "Painting", "Artistic", "Calligraphy", "Airbrush", "Textures", "Abstract", "Charcoals", "Elements", "Spraypaints", "Materials", "Vintage", "Luminance", "Industrial"]
    var onSelect: (_ brush: PCBrush?) -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Brush Catalog")
                        .font(.title)
                        .foregroundStyle(Color.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    Spacer()
                    if !UIDevice.isIPhone {
                        Button {
                            onCancel()
                        } label: {
//                            Image(systemName: "xmark.circle")
//                                .font(.system(size: 20, weight: .light))
//
//                                .foregroundStyle(Color.foreground)
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 20, height: 20)
                            Text("Close")
                        }
                        .frame(width: 44, height: 44)
                    }

                }
                HStack (alignment: .top) {
                    ScrollView (showsIndicators: false) {
                        VStack (alignment: .leading) {
//                            Button {
//                                
//                            } label: {
//                                ZStack (alignment: .leading){
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
//                                    Text("Recently Used")
//                                        .padding()
//                                        .foregroundStyle(Color.foreground)
//                                }
//                            }
//                            .frame(width: 200, height: 48)
                            ForEach(brushManager.brushSets) { brushSet in
                                if UIDevice.isIPhone && orientationInfo.orientation == .portrait {
                                    Button {
                                        if brushSet.id == "Recent" {
                                            brushManager.selectedBrushSet = brushManager.recentBrushes
                                        } else {
                                            brushManager.selectedBrushSet = brushSet
                                        }
                                    } label: {
                                        ZStack (alignment: .leading){
                                            if brushManager.selectedBrushSet != nil, brushManager.selectedBrushSet! == brushSet {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.clear)
                                            }
                                            Text(brushSet.name)
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color.foreground)
                                                .padding(.horizontal, 4)

                                        }
                                    }
                                    .frame(width: 96, height: 36)
                                } else {
                                    Button {
                                        if brushSet.id == "Recent" {
                                            brushManager.selectedBrushSet = brushManager.recentBrushes
                                        } else {
                                            brushManager.selectedBrushSet = brushSet
                                        }
                                    } label: {
                                        ZStack (alignment: .leading){
                                            if brushManager.selectedBrushSet != nil, brushManager.selectedBrushSet! == brushSet {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                                            } else {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.clear)
                                            }
                                            Text(brushSet.name)
                                                .foregroundStyle(Color.foreground)
                                                .padding(.horizontal)

                                        }
                                    }
                                    .frame(width: 200, height: 48)
                                }
                                
                            }
                        }
//                        .padding(.vertical)
                    }
                    .clipped()
                    if brushManager.selectedBrushSet != nil {
                        ScrollView (showsIndicators: false) {
                            LazyVStack {
                                ForEach(brushManager.selectedBrushSet!.brushes.indices, id: \.self) { index in
                                    let brush = brushManager.selectedBrushSet!.brushes[index]
                                    let previewImage = UIImage(contentsOfFile: brush.previewPath) ?? UIImage()
                                    Button {
                                        brushManager.addRecentBrush(recentBrush: brush)
                                        onSelect(brush)
                                    } label: {
                                        ZStack (alignment: .topLeading) {
                                            Text(brush.name)
                                                .frame(height: 20)
                                                .frame(maxWidth: 300, alignment: .leading)
                                                .foregroundStyle(Color.foreground)
                                            Image(uiImage: previewImage)
                                                .renderingMode(.template)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
//                                                .frame(height: 50)
                                                .frame(maxWidth: 300)
                                                .foregroundColor(Color.foreground)
                                        }
                                       
                                    }
                                    .padding(8)
                                    .background(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .clipped()

                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
            .onAppear {
                if brushManager.selectedBrushSet == nil {
                    brushManager.selectedBrushSet = brushManager.brushSets[1]
                }
            }
        }
        .frame(maxWidth: 600, maxHeight: 800)
        .background {
            if !UIDevice.isIPhone {
                ShinyRect()

            }
        }
    }
}


#Preview {
    BrushLibrary() { brush in
        
    } onCancel: {
        
    }
    .background(.black)
}
