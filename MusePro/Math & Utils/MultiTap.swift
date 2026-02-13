//
//  MultiTap.swift
//  MusePro
//
//  Created by Omer Karisman on 13.02.24.
//

import Foundation
import SwiftUI

struct MultiTapView: UIViewRepresentable
{
    var doubleTapCallback: (UITapGestureRecognizer) -> Void
    var tripleTapCallback: (UITapGestureRecognizer) -> Void
    var quadrupleTapCallback: (UITapGestureRecognizer) -> Void

    typealias UIViewType = UIView

    func makeCoordinator() -> MultiTapView.Coordinator
    {
        Coordinator(onDoubleTap: doubleTapCallback, onTripleTap: tripleTapCallback, onQuadrupleTap: quadrupleTapCallback)
    }

    func makeUIView(context: Context) -> UIView
    {
        let view = UIView()
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(sender:)))
       
        /// Set number of touches.
        doubleTapGestureRecognizer.numberOfTouchesRequired = 2
       
        view.addGestureRecognizer(doubleTapGestureRecognizer)
        
        let tripleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTripleTap(sender:)))
       
        /// Set number of touches.
        tripleTapGestureRecognizer.numberOfTouchesRequired = 3
       
        view.addGestureRecognizer(tripleTapGestureRecognizer)
        
        let quadrupleTapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleQuadrupleTap(sender:)))
       
        /// Set number of touches.
        quadrupleTapGestureRecognizer.numberOfTouchesRequired = 4
       
        view.addGestureRecognizer(quadrupleTapGestureRecognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context)
    {
    }

    class Coordinator
    {
        var onDoubleTap: (UITapGestureRecognizer) -> Void
        var onTripleTap: (UITapGestureRecognizer) -> Void
        var onQuadrupleTap: (UITapGestureRecognizer) -> Void

        init(onDoubleTap: @escaping (UITapGestureRecognizer) -> Void, onTripleTap: @escaping (UITapGestureRecognizer) -> Void, onQuadrupleTap: @escaping (UITapGestureRecognizer) -> Void)
        {
            self.onDoubleTap = onDoubleTap
            self.onTripleTap = onTripleTap
            self.onQuadrupleTap = onQuadrupleTap

        }

        @objc func handleDoubleTap(sender: UITapGestureRecognizer)
        {
            self.onDoubleTap(sender)
        }
        
        @objc func handleTripleTap(sender: UITapGestureRecognizer)
        {
            self.onTripleTap(sender)
        }
        
        @objc func handleQuadrupleTap(sender: UITapGestureRecognizer)
        {
            self.onQuadrupleTap(sender)
        }
    }
}
