import Foundation
import Metal
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import UniformTypeIdentifiers

/// texture with UUID
class MLTexture: Hashable {
    
     var id: String
    
     var texture: MTLTexture
    
    init(id: String, texture: MTLTexture) {
        self.id = id
        self.texture = texture
    }

    // size of texture in points
    lazy var size: CGSize = {
        let scaleFactor = UIScreen.main.nativeScale
        return CGSize(width: CGFloat(texture.width) / scaleFactor, height: CGFloat(texture.height) / scaleFactor)
    }()

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MLTexture, rhs: MLTexture) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MTLTexture {
    
    /// get CIImage from this texture
    func toCIImage() -> CIImage? {
        let image = CIImage(mtlTexture: self, options: [.colorSpace: CGColorSpaceCreateDeviceRGB()])
        return image?.oriented(forExifOrientation: 4)
    }
    
    /// get CGImage from this texture
//    func toCGImage() -> CGImage? {
//        guard let ciimage = toCIImage() else {
//            return nil
//        }
//        let context = CIContext() // Prepare for create CGImage
//        let rect = CGRect(origin: .zero, size: ciimage.extent.size)
//        return context.createCGImage(ciimage, from: rect)
//    }
    
    /// get UIImage from this texture
//    func toUIImage() -> UIImage? {
//        guard let cgimage = toCGImage() else {
//            return nil
//        }
//        return UIImage(cgImage: cgimage)
//    }
    
    /// get data from this texture
    func toData(context: CIContext?) -> Data? {
        guard let image = toCIImage(),
              let device = sharedDevice
        else {
            return nil
        }
        
        var context = context
        if context == nil {
            context = CIContext(mtlDevice: device)
        }

        return context!.pngRepresentation(of: image, format: .BGRA8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
    }
    
    func toJPEGData(context: CIContext?) -> Data? {
        guard let image = toCIImage(),
              let device = sharedDevice
        else {
            return nil
        }
        
        var context = context
        if context == nil {
            context = CIContext(mtlDevice: device)
        }
        
        return context!.jpegRepresentation(of: image, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:])
    }
    
    
    func resizeCGImage(_ cgImage: CGImage, to size: CGSize) -> CGImage? {
         let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                                 bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
                                 space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                 bitmapInfo: cgImage.bitmapInfo.rawValue)
         context?.interpolationQuality = .high
         context?.draw(cgImage, in: CGRect(origin: .zero, size: size))

         return context?.makeImage()
     }

     /// Get PNG data from this texture, with an optional size for resizing
     func toPNGData(resizedTo size: CGSize? = nil) -> Data? {
         guard let image = toCIImage(),
               let device = sharedDevice
         else {
             return nil
         }
         
         let context = CIContext(mtlDevice: device) //TODO: Find a way to reuse this

         return context.pngRepresentation(of: image, format: .RGBA16, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
     }

     /// Get JPEG data from this texture, with an optional size for resizing
//    func toJPEGData(resizedTo size: CGSize? = nil, compressionQuality: CGFloat = 1.0) -> Data? {
//        guard let cgImage = toCGImage() else {
//            return nil
//        }
//
//        // Start measuring the time
//        let startTime = CACurrentMediaTime()
//
//        let finalCGImage = size != nil ? resizeCGImage(cgImage, to: size!) : cgImage
//
//        // Measure the time taken for resizing
//        let resizeTime = CACurrentMediaTime() - startTime
//
//        let imageData = NSMutableData()
//        guard let imageDestination = CGImageDestinationCreateWithData(imageData, UTType.jpeg.identifier as CFString, 1, nil),
//              let finalImage = finalCGImage else {
//            return nil
//        }
//        let options: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: compressionQuality]
//        CGImageDestinationAddImage(imageDestination, finalImage, options as CFDictionary)
//
//        // Measure the time taken for encoding
//        let encodingTime = CACurrentMediaTime() - startTime - resizeTime
//
//        guard CGImageDestinationFinalize(imageDestination) else {
//            return nil
//        }
//
//        // Measure the total time taken
//        let totalTime = CACurrentMediaTime() - startTime
//
//        // Print the timing information
//        print("Time taken for resizing: \(resizeTime) seconds")
//        print("Time taken for encoding: \(encodingTime) seconds")
//        print("Total time taken: \(totalTime) seconds")
//
//        return imageData as Data
//    }

}
