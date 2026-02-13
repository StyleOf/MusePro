import Foundation

protocol DataObserver: AnyObject {
    
    func lineStrip(_ strip: LineStrip, didBeginOn data: CanvasData)
    
    func element(_ element: CanvasElement, didFinishOn data: CanvasData)
    
    func dataDidClear(_ data: CanvasData)
    
    func dataDidUndo(_ data: CanvasData)
    
    func dataDidRedo(_ data: CanvasData)
    
    func data(_ data: CanvasData, didResetTo newData: CanvasData)
}

extension DataObserver {
    func lineStrip(_ strip: LineStrip, didBeginOn data: CanvasData) {}
    func element(_ element: CanvasElement, didFinishOn data: CanvasData) {}
    func dataDidClear(_ data: CanvasData) {}
    func dataDidUndo(_ data: CanvasData) {}
    func dataDidRedo(_ data: CanvasData) {}
    func data(_ data: CanvasData, didResetTo newData: CanvasData) {}
}

final class DataObserverPool: WeakObjectsPool {
    
    func addObserver(_ observer: DataObserver) {
        super.addObject(observer)
    }
    
    var aliveObservers: [DataObserver] {
        return aliveObjects.compactMap { $0 as? DataObserver }
    }
}

extension DataObserverPool {
    func lineStrip(_ strip: LineStrip, didBeginOn data: CanvasData) {
        aliveObservers.forEach {
            $0.lineStrip(strip, didBeginOn: data)
        }
    }
    
    func element(_ element: CanvasElement, didFinishOn data: CanvasData) {
        aliveObservers.forEach {
            $0.element(element, didFinishOn: data)
        }
    }
    
    func dataDidClear(_ data: CanvasData) {
        aliveObservers.forEach {
            $0.dataDidClear(data)
        }
    }
    
    func dataDidUndo(_ data: CanvasData) {
        aliveObservers.forEach {
            $0.dataDidUndo(data)
        }
    }
    
    func dataDidRedo(_ data: CanvasData) {
        aliveObservers.forEach {
            $0.dataDidRedo(data)
        }
    }
    
    func data(_ data: CanvasData, didResetTo newData: CanvasData) {
        aliveObservers.forEach {
            $0.data(data, didResetTo: newData)
        }
    }
}
