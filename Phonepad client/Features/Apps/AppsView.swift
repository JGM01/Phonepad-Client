//
//  AppsView.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 10/5/24.
//

import SwiftUI

struct AppsView: View {
    @ObservedObject var bleManager: BLEManager
    
    let columns = [
        GridItem(.adaptive(minimum: 96))
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(bleManager.runningApps) { app in
                VStack {
                    Image(uiImage: app.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                    Text(app.name)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding()
                .onTapGesture {
                    bleManager.switchToApp(bundleIdentifier: app.bundleIdentifier)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 24))
    }
}
