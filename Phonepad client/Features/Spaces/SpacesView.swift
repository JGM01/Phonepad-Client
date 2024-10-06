//
//  SpacesView.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 10/5/24.
//

import SwiftUI

struct SpacesView: View {
    let sendData: (CGFloat, CGFloat, GestureType) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                sendData(0, 0, .switchSpaceLeft)
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 48))
                    .padding()
            }
            Spacer()
            Button(action: {
                sendData(0, 0, .switchSpaceRight)
            }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 48))
                    .padding()
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(20)
    }
}
