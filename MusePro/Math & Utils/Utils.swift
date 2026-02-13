#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Metal
import simd

extension Bundle {
    static var musepro: Bundle {
        var bundle: Bundle = Bundle.main
        let framework = Bundle(for: MTKCanvas.self)
        if let resource = framework.path(forResource: "MusePro", ofType: "bundle") {
            bundle = Bundle(path: resource) ?? Bundle.main
        }
        return bundle
    }
}

extension MTLDevice {
    func library() -> MTLLibrary? {
        let framework = Bundle(for: MTKCanvas.self)
        guard let resource = framework.path(forResource: "default", ofType: "metallib") else {
            return nil
        }
        return try? makeLibrary(URL: URL(fileURLWithPath: resource))
    }
}

//extension MTLTexture {
//    func clear() {
//        let region = MTLRegion(
//            origin: MTLOrigin(x: 0, y: 0, z: 0),
//            size: MTLSize(width: width, height: height, depth: 1)
//        )
//        let bytesPerRow = 4 * width
//        let data = Data(capacity: Int(bytesPerRow * height))
//        if let bytes = data.withUnsafeBytes({ $0.baseAddress }) {
//            replace(region: region, mipmapLevel: 0, withBytes: bytes, bytesPerRow: bytesPerRow)
//        }
//    }
//}

extension MTLTexture {
    func clear() {
        let region = MTLRegion(
            origin: MTLOrigin(x: 0, y: 0, z: 0),
            size: MTLSize(width: width, height: height, depth: 1)
        )
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let clearValue: UInt8 = 0
        var data = Data(count: Int(bytesPerRow * height))
        data.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            if let baseAddress = ptr.baseAddress {
                memset(baseAddress, Int32(clearValue), ptr.count)
            }
        }
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            if let bytes = ptr.baseAddress {
                replace(region: region, mipmapLevel: 0, withBytes: bytes, bytesPerRow: bytesPerRow)
            }
        }
    }
}

extension MTLTexture {
    func bounds(angle: Float = 0.0) -> CGRect {
        let width = self.width
        let height = self.height
        let bytesPerRow = width * 4
        
        let data = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * height, alignment: 4)
        defer {
            data.deallocate()
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        self.getBytes(data, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        let bind = data.assumingMemoryBound(to: UInt8.self)
        
        var aMin = 16384
        var aMax = 0
        var bMin = 16384
        var bMax = 0
        
        let angleRadians = angle * .pi / 180
        let cosAngle = cos(angleRadians)
        let sinAngle = sin(angleRadians)
        
        // Create a serial queue for synchronization
        let syncQueue = DispatchQueue(label: "syncQueue")
        
        DispatchQueue.concurrentPerform(iterations: height) { y in
            var localAMin = 16384
            var localAMax = 0
            var localBMin = 16384
            var localBMax = 0
            
            for x in 0..<width {
                let index = y * bytesPerRow + x * 4
                if bind[index + 3] != 0 {
                    let rotatedX = cosAngle * Float(x) - sinAngle * Float(y)
                    let rotatedY = sinAngle * Float(x) + cosAngle * Float(y)
                    
                    localAMin = min(localAMin, Int(rotatedX))
                    localAMax = max(localAMax, Int(rotatedX))
                    localBMin = min(localBMin, Int(rotatedY))
                    localBMax = max(localBMax, Int(rotatedY))
                }
            }
            
            // Synchronize updates to shared variables
            syncQueue.sync {
                aMin = min(aMin, localAMin)
                aMax = max(aMax, localAMax)
                bMin = min(bMin, localBMin)
                bMax = max(bMax, localBMax)
            }
        }
        
        aMin = (aMin / 4) * 4
        aMax = ((aMax + 3) / 4) * 4
        bMin = (bMin / 4) * 4
        bMax = ((bMax + 3) / 4) * 4
        
        return CGRect(x: aMin, y: bMin, width: aMax - aMin, height: bMax - bMin)
    }
}

extension MTLTexture {
    func calculateFilledArea(renderer: Renderer, mask: MTLTexture?) -> CGRect? {
        if let boundsBuffer = device.makeBuffer(length: MemoryLayout<UInt32>.size * 4, options: .storageModeShared),
           let commandBuffer = renderer.commandQueue.makeCommandBuffer(),
           let computeEncoder = commandBuffer.makeComputeCommandEncoder() {
            var initialBounds: [UInt32] = [16384, 0, 16384, 0]
            boundsBuffer.contents().copyMemory(from: &initialBounds, byteCount: MemoryLayout<UInt32>.size * 4)
            if mask != nil {
                computeEncoder.setComputePipelineState(renderer.computeBoundsWithMaskPipelineState)
                computeEncoder.setTexture(self, index: 0)
                computeEncoder.setTexture(mask, index: 1)
            } else {
                computeEncoder.setComputePipelineState(renderer.computeBoundsPipelineState)
                computeEncoder.setTexture(self, index: 0)
            }
           
            computeEncoder.setBuffer(boundsBuffer, offset: 0, index: 0)
            let threadExecutionWidth = renderer.computeBoundsPipelineState.threadExecutionWidth
            let maxTotalThreadsPerThreadgroup = renderer.computeBoundsPipelineState.maxTotalThreadsPerThreadgroup
            let threadsPerThreadgroup = MTLSize(width: threadExecutionWidth, height: maxTotalThreadsPerThreadgroup / threadExecutionWidth, depth: 1)
            
            let threadgroupsPerGrid = MTLSize(width: (self.width + threadsPerThreadgroup.width + 1) / threadsPerThreadgroup.width,
                                              height: (self.height + threadsPerThreadgroup.height + 1) / threadsPerThreadgroup.height,
                                              depth: 1)

            computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            computeEncoder.endEncoding()
            
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            let boundsPointer = boundsBuffer.contents().bindMemory(to: UInt32.self, capacity: 4)
            var minX = UInt32(boundsPointer[0])
            var maxX = UInt32(boundsPointer[1])
            var minY = UInt32(boundsPointer[2])
            var maxY = UInt32(boundsPointer[3])
            
            minX = (minX / 4) * 4
            maxX = ((maxX + 3) / 4) * 4
            minY = (minY / 4) * 4
            maxY = ((maxY + 3) / 4) * 4

            if maxX <= minX {
                return nil
            }
            
            if maxY <= minY {
                return nil
            }
            // Convert the atomic bounds to a CGRect
            let origin = CGPoint(x: CGFloat(minX), y: CGFloat(minY))
            let size = CGSize(width: CGFloat(maxX - minX), height: CGFloat(maxY - minY))
            let boundingRect = CGRect(origin: origin, size: size)
            // Read back and interpret the bounds from the buffer
            return boundingRect
        }
        return nil
    }
}

// MARK: - Point Utils
extension CGPoint {
    
    func between(min: CGPoint, max: CGPoint) -> CGPoint {
        return CGPoint(x: x.valueBetween(min: min.x, max: max.x),
                       y: y.valueBetween(min: min.y, max: max.y))
    }
    
    // MARK: - Codable utils
    static func make(from ints: [Int]) -> CGPoint {
        return CGPoint(x: CGFloat(ints.first ?? 0) / 10, y: CGFloat(ints.last ?? 0) / 10)
    }
    
    func encodeToInts() -> [Int] {
        return [Int(x * 10), Int(y * 10)]
    }
}

extension CGSize {
    // MARK: - Codable utils
    static func make(from ints: [Int]) -> CGSize {
        return CGSize(width: CGFloat(ints.first ?? 0) / 10, height: CGFloat(ints.last ?? 0) / 10)
    }
    
    func encodeToInts() -> [Int] {
        return [Int(width * 10), Int(height * 10)]
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: origin.x + width / 2, y: origin.y + height / 2)
    }
}

/// called when saving or reading finished
typealias ResultHandler = (Result<Void, Error>) -> ()

/// called when saving or reading progress changed
typealias ProgressHandler = (CGFloat) -> ()


// MARK: - Progress reporting
/// report progress via progresshander on main queue
func reportProgress(_ progress: CGFloat, on handler: ProgressHandler?) {
    DispatchQueue.main.async {
        handler?(progress)
    }
}

func reportProgress(base: CGFloat, unit: Int, total: Int, on handler: ProgressHandler?) {
    let progress = CGFloat(unit) / CGFloat(total) * (1 - base) + base
    reportProgress(progress, on: handler)
}
