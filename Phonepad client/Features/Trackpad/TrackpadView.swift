//
//  Trackpad.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 9/25/24.
//

import SwiftUI
import CoreHaptics

struct TrackpadView: View {
    let sendData: (CGFloat, CGFloat, GestureType) -> Void
    
    @State private var engine: CHHapticEngine?
    @State private var lastLocation: CGPoint?
    @State private var gestureStartTime: Date?
    @State private var currentGesture: GestureType = .move
    @State private var totalDistance: CGFloat = 0
    @State private var isLongPress = false
    @State private var longPressTimer: Timer?
    
    let tapThreshold: TimeInterval = 0.2
    let longTapThreshold: TimeInterval = 0.75
    let moveThreshold: CGFloat = 5
    let sensitivity: CGFloat = 3.0
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleGesture(value: value, in: geometry)
                        }
                        .onEnded { _ in
                            handleGestureEnd()
                        }
                )
        }
        .onAppear(perform: prepareHaptics)
    }
    
    private func handleGesture(value: DragGesture.Value, in geometry: GeometryProxy) {
        let currentLocation = value.location
        
        if lastLocation == nil {
            gestureStartTime = Date()
            currentGesture = .move
            totalDistance = 0
            isLongPress = false
            
            longPressTimer?.invalidate()
            longPressTimer = Timer.scheduledTimer(withTimeInterval: longTapThreshold, repeats: false) { _ in
                isLongPress = true
                currentGesture = .rightClick
                sendData(0, 0, .rightClick)
                complexSuccess()
            }
        } else {
            let deltaX = (currentLocation.x - lastLocation!.x) * sensitivity
            let deltaY = (currentLocation.y - lastLocation!.y) * sensitivity
            totalDistance += sqrt(deltaX * deltaX + deltaY * deltaY)
            
            if totalDistance > moveThreshold {
                longPressTimer?.invalidate()
                currentGesture = .move
                sendData(deltaX, deltaY, .move)
            }
        }
        
        lastLocation = currentLocation
    }
    
    private func handleGestureEnd() {
        longPressTimer?.invalidate()
        
        guard let startTime = gestureStartTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        if totalDistance <= moveThreshold {
            if isLongPress {
                // Long tap (right click) has already been handled
            } else if duration < tapThreshold {
                currentGesture = .leftClick
                sendData(0, 0, .leftClick)
            }
        }
        
        lastLocation = nil
        gestureStartTime = nil
        totalDistance = 0
        isLongPress = false
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
    }
    
    func complexSuccess() {
        // make sure that the device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        // create one intense, sharp tap
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 2)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 2)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        // convert those events into a pattern and play it immediately
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

struct TrackpadView_Previews: PreviewProvider {
    static var previews: some View {
        TrackpadView { _, _, _ in
            print("TrackpadView sendData called")
        }
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .padding()
        .previewLayout(.fixed(width: 300, height: 300))
        .previewDisplayName("Square TrackpadView")
        
        TrackpadView { _, _, _ in
            print("TrackpadView sendData called")
        }
        .frame(width: 250, height: 150)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(15)
        .padding()
        .previewLayout(.fixed(width: 300, height: 200))
        .previewDisplayName("Rectangular TrackpadView")
        
        TrackpadView { _, _, _ in
            print("TrackpadView sendData called")
        }
        .frame(width: 200, height: 200)
        .background(
            Circle()
                .fill(Color.green.opacity(0.2))
        )
        .clipShape(Circle())
        .padding()
        .previewLayout(.fixed(width: 300, height: 300))
        .previewDisplayName("Circular TrackpadView")
    }
}
