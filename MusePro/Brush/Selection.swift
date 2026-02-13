//
//  Selection.swift
//  Muse Pro
//
//  Created by Omer Karisman on 22.03.24.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Metal

class Selection: Brush {
    override func makeShaderVertexFunction(from library: MTLLibrary) -> MTLFunction? {
        return library.makeFunction(name: "selection_vertex")
    }
    
    override func makeShaderFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
        return library.makeFunction(name: "selection_fragment")
    }
    
//    override func makeRevealShaderVertexFunction(from library: MTLLibrary) -> MTLFunction? {
//        return library.makeFunction(name: "selection_second_vertex")
//    }
//    
//    override func makeRevealShaderFragmentFunction(from library: MTLLibrary) -> MTLFunction? {
//        return library.makeFunction(name: "selection_second_fragment")
//    }
    
    override func setupBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
        attachment.isBlendingEnabled = true
        
        attachment.rgbBlendOperation = .add
        attachment.alphaBlendOperation = .add
        
        attachment.sourceRGBBlendFactor = .one
        attachment.sourceAlphaBlendFactor = .one
        
        attachment.destinationRGBBlendFactor = .one
        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
    }
    
//    override func setupRevealBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
//        attachment.isBlendingEnabled = true
//        
//        attachment.rgbBlendOperation = .add
//        attachment.alphaBlendOperation = .add
//        
//        attachment.sourceRGBBlendFactor = .sourceAlpha
//        attachment.sourceAlphaBlendFactor = .one
//        
//        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
//        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
//    }
//    
//    override func setupRevealTransparentBlendOptions(for attachment: MTLRenderPipelineColorAttachmentDescriptor) {
//        attachment.isBlendingEnabled = true
//        
//        attachment.rgbBlendOperation = .add
//        attachment.alphaBlendOperation = .add
//        
//        attachment.sourceRGBBlendFactor = .one
//        attachment.sourceAlphaBlendFactor = .one
//        
//        attachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
//        attachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha
//    }
}
