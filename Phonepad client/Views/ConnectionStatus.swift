//
//  ConnectionStatus.swift
//  Phonepad client
//
//  Created by Jacob Germana-Mccray on 9/25/24.
//

import SwiftUI

struct ConnectionStatusView: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(status == .connected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(status.rawValue)
        }
    }
}


#Preview("ConnectionStatusView - Disconnected") {
    ConnectionStatusView(status: .disconnected)
}

#Preview("ConnectionStatusView - Scanning") {
    ConnectionStatusView(status: .scanning)
}

#Preview("ConnectionStatusView - Connecting") {
    ConnectionStatusView(status: .connecting)
}

#Preview("ConnectionStatusView - Connected") {
    ConnectionStatusView(status: .connected)
}

#Preview("ConnectionStatusView - All States") {
    VStack(spacing: 20) {
        ConnectionStatusView(status: .disconnected)
        ConnectionStatusView(status: .scanning)
        ConnectionStatusView(status: .connecting)
        ConnectionStatusView(status: .connected)
    }
    .padding()
}
