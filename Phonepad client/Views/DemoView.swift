//
//  DemoView.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 9/25/24.
//

import SwiftUI

struct DemoView: View {
    @Binding var scrollSensitivity: CGFloat
    @Binding var scrollDeceleration: CGFloat
    @Binding var minScrollVelocity: CGFloat
    @Binding var scrollThreshold: CGFloat
    @Binding var releaseVelocityFactor: CGFloat

    var body: some View {
        VStack {
            Text("Scroll Parameters")
                .font(.headline)
            
            ParameterSlider(value: $scrollSensitivity, range: 0.1...2.0, label: "Scroll Sensitivity")
            ParameterSlider(value: $scrollDeceleration, range: 0.8...0.99, label: "Scroll Deceleration")
            ParameterSlider(value: $minScrollVelocity, range: 0.01...0.5, label: "Min Scroll Velocity")
            ParameterSlider(value: $scrollThreshold, range: 0.5...5.0, label: "Scroll Threshold")
            ParameterSlider(value: $releaseVelocityFactor, range: 0.0...1.0, label: "Release Velocity Factor")
        }
        .padding()
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(10)
    }
}

struct ParameterSlider: View {
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    let label: String

    var body: some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: "%.2f", value))
            }
            Slider(value: $value, in: range)
        }
    }
}
