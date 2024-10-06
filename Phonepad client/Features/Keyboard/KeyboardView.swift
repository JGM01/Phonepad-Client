import SwiftUI

struct KeyboardView: View {
    @State private var text = ""
    @ObservedObject var bleManager: BLEManager
    
    @FocusState var focused: Bool?
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                TextField("Type here", text: $text)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .frame(maxWidth: .infinity, maxHeight: 48)
                    .padding([.leading, .trailing])
                    .overlay(
                        Capsule()
                            .stroke(.primary, style: StrokeStyle(lineWidth: 1))
                    )
                    .focused($focused, equals: true)
                    .onAppear {
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.focused = true
                      }
                    }

                Button {
                    bleManager.sendTextToMac(text)
                    text = ""
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: 48, maxHeight: 48)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
            }
            .padding()
        }
        
    }
}

#Preview("Empty") {
    KeyboardView(bleManager: MockBLEManager())
}

