//
//  Storage.swift
//  MusePro
//
//  Created by Omer Karisman on 10.02.24.
//

import Foundation

class Storage {
    
    init() { }
    
    enum Directory {
        case documents(subfolder: String?)
        case caches
        
        func url() -> URL {
            var searchPathDirectory: FileManager.SearchPathDirectory
            
            switch self {
            case .documents:
                searchPathDirectory = .documentDirectory
            case .caches:
                searchPathDirectory = .cachesDirectory
            }
            
            if var url = FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first {
                if case let .documents(subfolderName?) = self {
                    url = url.appendingPathComponent(subfolderName, isDirectory: true)
                    if !FileManager.default.fileExists(atPath: url.path(percentEncoded: true)) {
                        do {
                            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            fatalError("Could not create subdirectory for specified directory! Error: \(error.localizedDescription)")
                        }
                    }
                }
                return url
            } else {
                fatalError("Could not create URL for specified directory!")
            }
        }
    }
    
    static func store<T: Encodable>(_ object: T, to directory: Directory, as fileName: String) {
        let url = directory.url().appendingPathComponent(fileName, isDirectory: false)
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            NSData(data: data).write(to: url, atomically: true)
        } catch {
            print("Encoder error:", error)
        }
    }
    
    static func retrieve<T: Decodable>(_ fileName: String, from directory: Directory, as type: T.Type) -> T? {
        let url = directory.url().appendingPathComponent(fileName, isDirectory: false)
        
        if !FileManager.default.fileExists(atPath: url.path(percentEncoded: true)) {
            print("File at path \(url.path) does not exist!")
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                return model
            } catch {
                fatalError(error.localizedDescription)
            }
        } else {
            print("No data at \(url.path)!")
        }
        return nil
    }
    
    static func clear(_ directory: Directory) {
        let url = directory.url()
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for fileUrl in contents {
                try FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    static func remove(_ fileName: String, from directory: Directory) {
        let url = directory.url().appendingPathComponent(fileName, isDirectory: false)
        if FileManager.default.fileExists(atPath: url.path(percentEncoded: true)) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    static func fileExists(_ fileName: String, in directory: Directory) -> Bool {
        let url = directory.url().appendingPathComponent(fileName, isDirectory: false)
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: true))
    }
}
