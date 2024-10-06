//
//  MediaView.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 10/5/24.
//

import SwiftUI

struct MediaView: View {
    @State private var isPlaying = false
    
    var body: some View {
        VStack {
            Text("Media Controls")
                .font(.headline)
            
            HStack {
                Button(action: { /* Previous track */ }) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }
                
                Button(action: { isPlaying.toggle() }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                
                Button(action: { /* Next track */ }) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(20)
    }
}
