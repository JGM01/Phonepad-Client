//
//  VolumeView.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 10/5/24.
//
import SwiftUI

struct VolumeView: View {
    @State private var volume: Double = 0.5
    
    var body: some View {
        VStack {
            Text("Volume")
                .font(.headline)
            HStack {
                Image(systemName: "speaker.fill")
                Slider(value: $volume)
                Image(systemName: "speaker.wave.3.fill")
            }
        }
        .padding()
        .frame(width: 300, height: 100)
        .background(.thinMaterial)
        .cornerRadius(20)
    }
}
