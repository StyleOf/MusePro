//
//  Haptics.swift
//  Muse Pro
//
//  Created by Omer Karisman on 15.03.24.
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

#if os(visionOS)
   // visionOS code
#elseif os(iOS)
public enum HapticFeedbackStyle: Int {
    case light, medium, heavy
    
    @available(iOS 13.0, *)
    case soft, rigid
}

@available(iOS 10.0, *)
extension HapticFeedbackStyle {
    var value: UIImpactFeedbackGenerator.FeedbackStyle {
        return UIImpactFeedbackGenerator.FeedbackStyle(rawValue: rawValue)!
    }
}

public enum HapticFeedbackType: Int {
    case success, warning, error
}

@available(iOS 10.0, *)
extension HapticFeedbackType {
    var value: UINotificationFeedbackGenerator.FeedbackType {
        return UINotificationFeedbackGenerator.FeedbackType(rawValue: rawValue)!
    }
}

public enum Haptic {
    case impact(HapticFeedbackStyle)
    case notification(HapticFeedbackType)
    case selection
    
    // trigger
    public func generate() {
        guard #available(iOS 10, *) else { return }
        
        switch self {
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style.value)
            generator.prepare()
            generator.impactOccurred()
        case .notification(let type):
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type.value)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
}


extension UIControl.Event: Hashable {
    public var hashValue: Int {
        return Int(rawValue)
    }
}

func == (lhs: UIControl.Event, rhs: UIControl.Event) -> Bool {
    return lhs.rawValue == rhs.rawValue
}

extension OperationQueue {
    static var serial: OperationQueue {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }
}

public extension Haptic {
    static let queue: OperationQueue = .serial
    
    static func play(_ notes: [Note]) {
        guard #available(iOS 10, *), queue.operations.isEmpty else { return }
        
        for note in notes {
            let operation = note.operation
            if let last = queue.operations.last {
                operation.addDependency(last)
            }
            queue.addOperation(operation)
        }
    }
    
    static func play(_ pattern: String, delay: TimeInterval) {
        let notes = pattern.compactMap { Note($0, delay: delay) }
        play(notes)
    }
}

public enum Note {
    case haptic(Haptic)
    case wait(TimeInterval)
    
    init?(_ char: Character, delay: TimeInterval) {
        switch String(char) {
        case "O":
            self = .haptic(.impact(.heavy))
        case "o":
            self = .haptic(.impact(.medium))
        case ".":
            self = .haptic(.impact(.light))
        case "X":
            if #available(iOS 13.0, *) {
                self = .haptic(.impact(.rigid))
            } else {
                self = .haptic(.impact(.heavy))
            }
        case "x":
            if #available(iOS 13.0, *) {
                self = .haptic(.impact(.soft))
            } else {
                self = .haptic(.impact(.light))
            }
        case "-":
            self = .wait(delay)
        default:
            return nil
        }
    }
    
    var operation: Operation {
        switch self {
        case .haptic(let haptic):
            return HapticOperation(haptic)
        case .wait(let interval):
            return WaitOperation(interval)
        }
    }
}

class HapticOperation: Operation {
    let haptic: Haptic
    init(_ haptic: Haptic) {
        self.haptic = haptic
    }
    override func main() {
        DispatchQueue.main.sync {
            self.haptic.generate()
        }
    }
}
class WaitOperation: Operation {
    let duration: TimeInterval
    init(_ duration: TimeInterval) {
        self.duration = duration
    }
    override func main() {
        Thread.sleep(forTimeInterval: duration)
    }
}


private var hapticKey: Void?
private var eventKey: Void?
private var targetsKey: Void?

public protocol Hapticable: class {
    func trigger(_ sender: Any)
}

extension Hapticable where Self: UIControl {
    
    public var isHaptic: Bool {
        get {
            guard let actions = actions(forTarget: self, forControlEvent: hapticControlEvents ?? .touchDown) else { return false }
            return !actions.filter { $0 == #selector(trigger).description }.isEmpty
        }
        set {
            if newValue {
                addTarget(self, action: #selector(trigger), for: hapticControlEvents ?? .touchDown)
            } else {
                removeTarget(self, action: #selector(trigger), for: hapticControlEvents ?? .touchDown)
            }
        }
    }
    
    public var hapticType: Haptic? {
        get { return getAssociatedObject(&hapticKey) }
        set { setAssociatedObject(&hapticKey, newValue) }
    }
    
    public var hapticControlEvents: UIControl.Event? {
        get { return getAssociatedObject(&eventKey) }
        set { setAssociatedObject(&eventKey, newValue) }
    }
    
    private var hapticTargets: [UIControl.Event: HapticTarget] {
        get { return getAssociatedObject(&targetsKey) ?? [:] }
        set { setAssociatedObject(&targetsKey, newValue) }
    }
    
    public func addHaptic(_ haptic: Haptic, forControlEvents events: UIControl.Event) {
        let hapticTarget = HapticTarget(haptic: haptic)
        hapticTargets[events] = hapticTarget
        addTarget(hapticTarget, action: #selector(hapticTarget.trigger), for: events)
    }
    
    public func removeHaptic(forControlEvents events: UIControl.Event) {
        guard let hapticTarget = hapticTargets[events] else { return }
        hapticTargets[events] = nil
        removeTarget(hapticTarget, action: #selector(hapticTarget.trigger), for: events)
    }
    
}

extension UIControl: Hapticable {
    @objc public func trigger(_ sender: Any) {
        hapticType?.generate()
    }
}

private class HapticTarget {
    let haptic: Haptic
    init(haptic: Haptic) {
        self.haptic = haptic
    }
    @objc func trigger(_ sender: Any) {
        haptic.generate()
    }
}


import Foundation

private class Associated<T>: NSObject {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}

protocol Associable {}

extension Associable where Self: AnyObject {
    
    func getAssociatedObject<T>(_ key: UnsafeRawPointer) -> T? {
        return (objc_getAssociatedObject(self, key) as? Associated<T>).map { $0.value }
    }
    
    func setAssociatedObject<T>(_ key: UnsafeRawPointer, _ value: T?) {
        objc_setAssociatedObject(self, key, value.map { Associated<T>($0) }, .OBJC_ASSOCIATION_RETAIN)
    }
    
}

extension NSObject: Associable {}
#endif
