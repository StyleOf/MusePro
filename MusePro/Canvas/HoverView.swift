//
//  HoverView.swift
//  Muse Pro
//
//  Created by Omer Karisman on 01.04.24.
//

import SwiftUI

struct HoverView: View {
    @State private var overText = false

       var body: some View {
           Text("Hello, World!")
               .foregroundStyle(overText ? .green : .red)
               .onHover { over in
                   overText = over
               }
       }
}

#Preview {
    HoverView()
}
