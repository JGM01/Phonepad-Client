import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @State private var activeOverlay: OverlayType?
    @State private var isOverlayPresented = false
    
    var body: some View {
        ZStack {
            mainContent
                .scaleEffect(isOverlayPresented ? 0.8 : 1.0)
                .blur(radius: isOverlayPresented ? 10 : 0)
                .animation(.easeOut, value: isOverlayPresented)
            
            if let overlay = activeOverlay {
                Color.black.opacity(0.05)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismissOverlay()
                    }
                
                overlayView(for: overlay)
                    .padding()
                    .scaleEffect(isOverlayPresented ? 1.0 : 0.5)
                    .opacity(isOverlayPresented ? 1.0 : 0)
                    .animation(.default, value: isOverlayPresented)
            }
        }
    }
    
    private var mainContent: some View {
        VStack {
            headerView
            gridLayout
            buttonGrid
            Spacer()
        }
        .padding()
        .onAppear { bleManager.startScanning() }
    }
    
    private var headerView: some View {
        HStack {
            ConnectionStatusView(status: bleManager.connectionStatus)
            Spacer()
            if bleManager.connectionStatus != .connected {
                Button("Connect", action: bleManager.startScanning)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
    
    private var gridLayout: some View {
        Grid {
            GridRow {
                TrackpadView(sendData: bleManager.sendTrackpadData)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fit)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                verticalScrollView
            }
            GridRow {
                horizontalScrollView
                
                Button {} label: {
                    Image(systemName: "keyboard")
                        .frame(maxWidth: 48, maxHeight: 48)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical)
    }
    
    private var verticalScrollView: some View {
        ZStack {
            ScrollBarView(sendData: bleManager.sendTrackpadData)
                .frame(maxWidth: 48, maxHeight: .infinity)
                .background(.thinMaterial)
                .clipShape(Capsule())
            
            VStack {
                Image(systemName: "arrow.up")
                Spacer()
                Image(systemName: "arrow.down")
            }
            .foregroundColor(.secondary)
            .fontWeight(.bold)
            .padding()
        }
    }
    
    private var horizontalScrollView: some View {
        ZStack {
            ScrollBarView(sendData: bleManager.sendTrackpadData)
                .frame(maxWidth: .infinity, maxHeight: 48)
                .background(.thinMaterial)
                .clipShape(Capsule())
            
            HStack {
                Image(systemName: "arrow.left")
                Spacer()
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.secondary)
            .fontWeight(.bold)
            .padding()
        }
    }
    
    private var buttonGrid: some View {
        Grid {
            GridRow {
                actionButton(title: "Spaces", icon: "display", overlayType: .spaces)
                actionButton(title: "Switch Apps", icon: "app.connected.to.app.below.fill", overlayType: .switchApps)
            }
            GridRow {
                actionButton(title: "Media", icon: "play.fill", overlayType: .media)
                HStack {
                    actionButton(icon: "sun.max.fill", overlayType: .brightness)
                    actionButton(icon: "speaker.wave.2.fill", overlayType: .volume)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func actionButton(title: String? = nil, icon: String, overlayType: OverlayType) -> some View {
        Button {
            presentOverlay(overlayType)
        } label: {
            Label {
                if let title = title {
                    Text(title)
                }
            } icon: {
                Image(systemName: icon)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
    
    private func presentOverlay(_ type: OverlayType) {
        activeOverlay = type
        withAnimation {
            isOverlayPresented = true
        }
    }
        
    private func dismissOverlay() {
        withAnimation {
            isOverlayPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activeOverlay = nil
        }
    }
    
    @ViewBuilder
    private func overlayView(for type: OverlayType) -> some View {
        switch type {
        case .spaces:
            SpacesOverlay(sendData: bleManager.sendTrackpadData)
        case .switchApps:
            SwitchAppsOverlay(bleManager: bleManager)
        case .media:
            MediaOverlay()
        case .brightness:
            BrightnessOverlay()
        case .volume:
            VolumeOverlay()
        }
    }
}

enum OverlayType {
    case spaces, switchApps, media, brightness, volume
}

struct SpacesOverlay: View {
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

struct SwitchAppsOverlay: View {
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

struct MediaOverlay: View {
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

struct BrightnessOverlay: View {
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

struct VolumeOverlay: View {
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


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
