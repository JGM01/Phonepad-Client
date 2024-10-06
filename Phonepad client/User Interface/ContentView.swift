import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @State private var activeOverlay: ControlType?
    @State private var isOverlayPresented = false
    
    var body: some View {
        ZStack {
            mainContent
                .scaleEffect(isOverlayPresented ? 0.8 : 1.0)
                .blur(radius: isOverlayPresented ? 10 : 0)
                .animation(.easeOut(duration: 0.2), value: isOverlayPresented)
            
            if let overlay = activeOverlay {
                Color.black.opacity(0.05)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismissControlView()
                    }
                
                controlView(for: overlay)
                    .padding()
                    .scaleEffect(isOverlayPresented ? 1.0 : 0.5)
                    .opacity(isOverlayPresented ? 1.0 : 0)
                    .animation(isOverlayPresented ? .bouncy(duration: 0.2, extraBounce: 0.25) : .easeOut(duration: 0.2), value: isOverlayPresented)
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
            HStack {
                Circle()
                    .fill(bleManager.connectionStatus == .connected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(bleManager.connectionStatus.rawValue)
            }
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
                
                Button {
                    presentControlView(.keyboard)
                } label: {
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
                controlToggleButton(title: "Spaces", icon: "display", overlayType: .spaces)
                controlToggleButton(title: "Switch Apps", icon: "app.connected.to.app.below.fill", overlayType: .apps)
            }
            GridRow {
                controlToggleButton(title: "Media", icon: "play.fill", overlayType: .media)
                HStack {
                    controlToggleButton(icon: "sun.max.fill", overlayType: .brightness)
                    controlToggleButton(icon: "speaker.wave.2.fill", overlayType: .volume)
                }
            }
        }
        .padding(.vertical)
    }
    
    private func controlToggleButton(title: String? = nil, icon: String, overlayType: ControlType) -> some View {
        Button {
            presentControlView(overlayType)
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
    
    private func presentControlView(_ type: ControlType) {
        activeOverlay = type
        withAnimation(.bouncy) {
            isOverlayPresented = true
        }
    }
    
    private func dismissControlView() {
        withAnimation(.easeOut) {
            isOverlayPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            activeOverlay = nil
        }
    }
    
    @ViewBuilder
    private func controlView(for type: ControlType) -> some View {
        switch type {
        case .spaces:
            SpacesView(sendData: bleManager.sendTrackpadData)
        case .apps:
            AppsView(bleManager: bleManager)
        case .media:
            MediaView()
        case .brightness:
            BrightnessView()
        case .volume:
            VolumeView()
        case .keyboard:
            KeyboardView(bleManager: bleManager)
        }
    }
}

enum ControlType {
    case spaces, apps, media, brightness, volume, keyboard
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
