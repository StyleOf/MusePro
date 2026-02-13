//
//  ColorPickerSheet.swift
//  MusePro
//
//  Created by Omer Karisman on 28.12.23.
//

import SwiftUI
//
//extension View {
//    @available(iOS 15.0, *)
//    func colorPickerSheet(isPresented: Binding<Bool>, selection: Binding<Color>, supportsAlpha: Bool = false, title: String? = nil, action: @escaping () -> Void, colorChanged: @escaping () -> Void) -> some View {
//        self.background(ColorPickerSheet(isPresented: isPresented, selection: selection, supportsAlpha: supportsAlpha, title: title, action: action, colorChanged: colorChanged))
//    }
//}
//
//@available(iOS 15.0, *)
//struct ColorPickerSheet: UIViewRepresentable {
//    @Binding var isPresented: Bool
//    @Binding var selection: Color
//    var supportsAlpha: Bool
//    var title: String?
//    var action: () -> Void
//    var colorChanged: () -> Void
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(selection: $selection, isPresented: $isPresented, action: action, colorChanged: colorChanged)
//    }
//    
//    class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
//        @Binding var selection: Color
//        @Binding var isPresented: Bool
//        var didPresent = false
//        var action: () -> Void
//        var colorChanged: () -> Void
//        
//        init(selection: Binding<Color>, isPresented: Binding<Bool>, action: @escaping () -> Void, colorChanged: @escaping () -> Void) {
//            self._selection = selection
//            self._isPresented = isPresented
//            self.action = action
//            self.colorChanged = colorChanged
//        }
//        
//        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
//            selection = Color(viewController.selectedColor)
//            colorChanged()
//        }
//        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
//            isPresented = false
//            didPresent = false
//        }
//        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
//            isPresented = false
//            didPresent = false
//            action()
//        }
//        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
//            print("SHOULDA WOULDA COULDA")
//            return true
//        }
//        func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
//            return .popover
//        }
//        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
//            return .popover
//        }
//    }
//    
//    func getTopViewController(from view: UIView) -> UIViewController? {
//        guard var top = view.window?.rootViewController else {
//            return nil
//        }
//        while let next = top.presentedViewController {
//            top = next
//        }
//        return top
//    }
//    
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        view.isHidden = true
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {
//        if isPresented && !context.coordinator.didPresent {
//            let modal = UIColorPickerViewController()
//            modal.selectedColor = UIColor(selection)
//            modal.supportsAlpha = supportsAlpha
//            modal.title = title
//            modal.delegate = context.coordinator
//            
//            modal.modalPresentationStyle = .popover
//            
//            if let popoverController = modal.popoverPresentationController {
//                popoverController.sourceView = uiView
//                popoverController.sourceRect = CGRect(x: uiView.bounds.midX, y: uiView.bounds.midY, width: 0, height: 0)
//                popoverController.permittedArrowDirections = [.any]
//                popoverController.delegate = context.coordinator
//            }
//            
//            
//            let top = getTopViewController(from: uiView)
//            top?.presentationController?.delegate = context.coordinator
//            top?.present(modal, animated: true)
//            context.coordinator.didPresent = true
//        }
//    }
//}



import SwiftUI

extension View {
    @available(iOS 15.0, *)
    public func colorPickerSheet(isPresented: Binding<Bool>, selection: Binding<Color>, supportsAlpha: Bool = false, title: String? = nil, onDismiss: @escaping () -> Void, onChange: @escaping () -> Void) -> some View {
        self.background(ColorPickerSheet(isPresented: isPresented, selection: selection, supportsAlpha: supportsAlpha, title: title, onDismiss: onDismiss, onChange: onChange))
    }
}

@available(iOS 15.0, *)
private struct ColorPickerSheet: UIViewRepresentable {
    @Binding var isPresented: Bool
    @Binding var selection: Color
    var supportsAlpha: Bool
    var title: String?
    var onDismiss: () -> Void
    var onChange: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection, isPresented: $isPresented, onDismiss: onDismiss, onChange: onChange)
    }
    
    class Coordinator: NSObject, UIColorPickerViewControllerDelegate, UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
        @Binding var selection: Color
        @Binding var isPresented: Bool
        var didPresent = false
        var onDismiss: () -> Void
        var onChange: () -> Void

        init(selection: Binding<Color>, isPresented: Binding<Bool>, onDismiss: @escaping () -> Void, onChange: @escaping () -> Void) {
            self._selection = selection
            self._isPresented = isPresented
            self.onDismiss = onDismiss
            self.onChange = onChange
        }
        
        func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
            selection = Color(viewController.selectedColor)
            onChange()
        }
        func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
            isPresented = false
            didPresent = false
        }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            isPresented = false
            didPresent = false
            onDismiss()
        }
        
        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
            isPresented = false
            didPresent = false
        }
        
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            isPresented = false
            didPresent = false
            return true
        }
    }

    func getTopViewController(from view: UIView) -> UIViewController? {
        guard var top = view.window?.rootViewController else {
            return nil
        }
        while let next = top.presentedViewController {
            top = next
        }
        return top
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isHidden = true
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if !isPresented {
            context.coordinator.didPresent = false
        }
        if isPresented && !context.coordinator.didPresent {
            let modal = UICPVC()
            modal.selectedColor = UIColor(selection)
            modal.supportsAlpha = supportsAlpha
            modal.title = title
            modal.delegate = context.coordinator
            modal.UICPVCDelegate = context.coordinator
            modal.modalPresentationStyle = .popover
            
            if let popoverController = modal.popoverPresentationController {
                popoverController.sourceView = uiView
                popoverController.sourceRect = CGRect(x: uiView.bounds.midX, y: uiView.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = [.any]
                popoverController.delegate = context.coordinator
            }
            
            let top = getTopViewController(from: uiView)
            top?.present(modal, animated: true)
            context.coordinator.didPresent = true
        }
    }
}

class UICPVC: UIColorPickerViewController {
    var UICPVCDelegate: UIColorPickerViewControllerDelegate?
}
