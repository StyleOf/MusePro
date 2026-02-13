import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

protocol ActionObserver: AnyObject {
    func canvasDidRedraw(_ canvas: MTKCanvas, final: Bool)
    func canvasDidFinishRenderingChanges(_ canvas: MTKCanvas)
}

extension ActionObserver {
    func canvasDidRedraw(_ canvas: MTKCanvas, final: Bool) {}
    func canvasDidFinishRenderingChanges(_ canvas: MTKCanvas) {}
}

final class ActionObserverPool: WeakObjectsPool {
    
    func addObserver(_ observer: ActionObserver) {
        super.addObject(observer)
    }
    
    // return unreleased objects
    var aliveObservers: [ActionObserver] {
        return aliveObjects.compactMap { $0 as? ActionObserver }
    }
}

extension ActionObserverPool: ActionObserver {
    func canvasDidRedraw(_ canvas: MTKCanvas, final: Bool = false) {
        aliveObservers.forEach { $0.canvasDidRedraw(canvas, final: final) }
    }
    
    func canvasDidFinishRenderingChanges(_ canvas: MTKCanvas) {
        aliveObservers.forEach { $0.canvasDidFinishRenderingChanges(canvas) }
    }
}
