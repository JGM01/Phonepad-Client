//
//  BrightnessView.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 10/5/24.
//

import SwiftUI

struct BrightnessView: View {
    @State private var brightness: Double = 0.5
    
    var body: some View {
        VStack {
            Text("Brightness")
                .font(.headline)
            HStack {
                Image(systemName: "sun.min")
                Slider(value: $brightness)
                Image(systemName: "sun.max")
            }
        }
        .padding()
        .frame(width: 300, height: 100)
        .background(.thinMaterial)
        .cornerRadius(20)
    }
}
