import SwiftUI

struct ScrollBarView: View {
    let sendData: (CGFloat, CGFloat, GestureType) -> Void
    
    @State private var scrollVelocity: CGFloat = 0
    @State private var lastScrollPosition: CGFloat = 0
    @State private var lastScrollTime: Date = Date()
    @State private var isScrolling = false
    @State private var scrollAccumulator: CGFloat = 0
    @State private var recentScrollSpeeds: [CGFloat] = []
    
    let scrollSensitivity: CGFloat = 1.0
    let scrollDeceleration: CGFloat = 0.86
    let minScrollVelocity: CGFloat = 0.1
    let scrollThreshold: CGFloat = 1.0
    let releaseVelocityFactor: CGFloat = 0.01
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            handleScroll(value: value, in: geometry)
                        }
                        .onEnded { _ in
                            endScroll()
                        }
                )
            
        }
        .onReceive(Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()) { _ in
            updateScroll()
        }
    }
    
    private func handleScroll(value: DragGesture.Value, in geometry: GeometryProxy) {
        let currentPosition = value.location.y
        let currentTime = Date()
        
        if !isScrolling {
            isScrolling = true
            lastScrollPosition = currentPosition
            lastScrollTime = currentTime
            scrollAccumulator = 0
            recentScrollSpeeds = []
            return
        }
        
        let deltaY = currentPosition - lastScrollPosition
        let deltaTime = currentTime.timeIntervalSince(lastScrollTime)
        
        if deltaTime > 0 {
            let instantSpeed = deltaY / CGFloat(deltaTime)
            recentScrollSpeeds.append(instantSpeed)
            if recentScrollSpeeds.count > 5 {
                recentScrollSpeeds.removeFirst()
            }
        }
        
        scrollAccumulator += deltaY
        
        if abs(scrollAccumulator) >= scrollThreshold {
            let scrollAmount = scrollAccumulator
            scrollAccumulator = 0
            
            sendData(0, -scrollAmount * scrollSensitivity, .scroll)
        }
        
        lastScrollPosition = currentPosition
        lastScrollTime = currentTime
    }
    
    private func endScroll() {
        isScrolling = false
        if abs(scrollAccumulator) > 0 {
            sendData(0, -scrollAccumulator * scrollSensitivity, .scroll)
            scrollAccumulator = 0
        }
        
        if !recentScrollSpeeds.isEmpty {
            let averageSpeed = recentScrollSpeeds.reduce(0, +) / CGFloat(recentScrollSpeeds.count)
            scrollVelocity = averageSpeed * scrollSensitivity * releaseVelocityFactor
        } else {
            scrollVelocity = 0
        }
    }
    
    private func updateScroll() {
        guard !isScrolling && abs(scrollVelocity) > minScrollVelocity else {
            if !isScrolling {
                scrollVelocity = 0
            }
            return
        }
        
        scrollVelocity *= scrollDeceleration
        sendData(0, -scrollVelocity, .scroll)
    }
}

struct ScrollView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollBarView(sendData: { _, _, _ in
            print("ScrollView sendData called")
        })
        .frame(width: 64, height: 320)
        .background(.thickMaterial)
        .cornerRadius(24)
        .padding()
        .previewDisplayName("Normal ScrollView")
    }
}
