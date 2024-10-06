import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
        @Published var runningApps: [AppInfo] = []
        
        private var centralManager: CBCentralManager!
        private var peripheral: CBPeripheral?
        private var writeCharacteristic: CBCharacteristic?
        private var appUpdateCharacteristic: CBCharacteristic?
        private var appSwitchCharacteristic: CBCharacteristic?
        private var appListRequestCharacteristic: CBCharacteristic?
        private var chunkAckCharacteristic: CBCharacteristic?
        private var textTransferCharacteristic: CBCharacteristic?

        
        private let serviceUUID = CBUUID(string: "5FFB1810-2672-4FFE-B9B8-54122F7E4F99")
        private let characteristicUUID = CBUUID(string: "34722DA8-9E9A-44A3-BB59-9E8E3A41728E")
        private let appUpdateCharacteristicUUID = CBUUID(string: "481B51DC-5649-4F0F-B1EE-EC527E0B985B")
        private let appSwitchCharacteristicUUID = CBUUID(string: "D62D00F3-02ED-4005-B427-86B5E4881601")
        private let appListRequestCharacteristicUUID = CBUUID(string: "65E43765-0C73-4F52-85D3-C49D068AA5BF")
        private let chunkAckCharacteristicUUID = CBUUID(string: "C54DCF47-7708-40E9-90F9-013723282D14")
    
        private let textTransferCharacteristicUUID = CBUUID(string: "733E7C66-6D92-46F9-9EB3-276172C93C8A")
        
        private let sendQueue = DispatchQueue(label: "com.example.PhonepadClient.sendQueue", qos: .userInteractive)
        private var lastSentTime: Date = Date()
        private let minSendInterval: TimeInterval = 1.0 / 120 // 120 fps
        
        private var appDataBuffer: [Int: Data] = [:]
        
        override init() {
            super.init()
            print("BLEManager initialized")
            centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        }
        
        func startScanning() {
            print("startScanning called. Current state: \(centralManager.state.rawValue)")
            guard centralManager.state == .poweredOn else {
                print("Bluetooth is not powered on. Current state: \(centralManager.state.rawValue)")
                return
            }
            
            if connectionStatus == .disconnected {
                print("Starting to scan for peripherals")
                centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
                DispatchQueue.main.async {
                    self.connectionStatus = .scanning
                }
            } else {
                print("Not starting scan: already \(connectionStatus.rawValue)")
            }
        }
        
        func disconnect() {
            guard let peripheral = peripheral else {
                print("No peripheral to disconnect")
                return
            }
            print("Disconnecting from peripheral: \(peripheral.name ?? "Unknown")")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    
    func sendTrackpadData(deltaX: CGFloat, deltaY: CGFloat, gestureType: GestureType) {
        sendQueue.async { [weak self] in
            guard let self = self else { return }
            
            let currentTime = Date()
            let timeSinceLastSend = currentTime.timeIntervalSince(self.lastSentTime)
            
            if timeSinceLastSend < self.minSendInterval && gestureType == .move {
                // Skip this update to avoid overwhelming the server
                return
            }
            
            let data = self.encodeTrackpadData(deltaX: deltaX, deltaY: deltaY, gestureType: gestureType)
            print("Sending trackpad data: deltaX: \(deltaX), deltaY: \(deltaY), gestureType: \(gestureType)")
            self.peripheral?.writeValue(data, for: self.writeCharacteristic!, type: .withoutResponse)
            
            self.lastSentTime = currentTime
        }
    }
    
    private func encodeTrackpadData(deltaX: CGFloat, deltaY: CGFloat, gestureType: GestureType) -> Data {
        let scaleFactor: CGFloat = 1.5 // Increase this value to send larger delta values
        let scaledDeltaX = deltaX * scaleFactor
        let scaledDeltaY = deltaY * scaleFactor
        
        let clampedDeltaX = min(max(scaledDeltaX, -128), 127)
        let clampedDeltaY = min(max(scaledDeltaY, -128), 127)
        
        var data = Data(count: 3)
        data[0] = UInt8(bitPattern: Int8(clampedDeltaX))
        data[1] = UInt8(bitPattern: Int8(clampedDeltaY))
        data[2] = UInt8(gestureType.rawValue)
        
        return data
    }
    
    func switchToApp(bundleIdentifier: String) {
        guard let characteristic = appSwitchCharacteristic else {
            print("Error: appSwitchCharacteristic is nil")
            return
        }
        print("Sending app switch request for bundle identifier: \(bundleIdentifier)")
        let data = bundleIdentifier.data(using: .utf8)!
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func requestAppList() {
        guard let characteristic = appListRequestCharacteristic else {
            print("Error: appListRequestCharacteristic is nil")
            return
        }
        print("Requesting app list")
        let data = Data([0x01]) // You can use any data here, we just need to write something
        peripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func sendTextToMac(_ text: String) {
        print("Attempting to send text to Mac. Length: \(text.count) characters")
        
        guard let data = text.data(using: .utf8) else {
            print("Error: Unable to convert text to data")
            return
        }
        
        guard let peripheral = peripheral else {
            print("Error: No peripheral connected")
            return
        }
        
        guard let characteristic = textTransferCharacteristic else {
            print("Error: textTransferCharacteristic is nil")
            return
        }
        
        // Split the data into chunks if it's too large
        let maxLength = peripheral.maximumWriteValueLength(for: .withResponse)
        let chunks = data.chunked(into: maxLength)
        
        for (index, chunk) in chunks.enumerated() {
            peripheral.writeValue(chunk, for: characteristic, type: .withResponse)
            print("Sent chunk \(index + 1) of \(chunks.count)")
        }
        
        print("All text data sent to Mac")
    }

    func testConnection() {
        guard let peripheral = peripheral, let characteristic = textTransferCharacteristic else {
            print("Error: Unable to test connection. Peripheral or characteristic is nil.")
            return
        }
        
        let testData = "test".data(using: .utf8)!
        peripheral.writeValue(testData, for: characteristic, type: .withResponse)
        print("Sent test data")
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central manager state updated: \(central.state.rawValue)")
        DispatchQueue.main.async {
            switch central.state {
            case .poweredOn:
                print("Bluetooth is powered on, starting scan")
                self.startScanning()
            case .poweredOff:
                print("Bluetooth is powered off")
                self.connectionStatus = .disconnected
            case .resetting:
                print("Bluetooth is resetting")
                self.connectionStatus = .disconnected
            case .unauthorized:
                print("Bluetooth use is unauthorized")
                self.connectionStatus = .disconnected
            case .unknown:
                print("Bluetooth state is unknown")
                self.connectionStatus = .disconnected
            case .unsupported:
                print("Bluetooth is unsupported on this device")
                self.connectionStatus = .disconnected
            @unknown default:
                print("Unknown Bluetooth state")
                self.connectionStatus = .disconnected
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral.name ?? "Unknown"), RSSI: \(RSSI)")
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        centralManager.stopScan()
        print("Stopped scanning and attempting to connect")
        DispatchQueue.main.async {
            self.connectionStatus = .connecting
        }
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
        DispatchQueue.main.async {
            self.connectionStatus = .connected
        }
        print("Discovering services for peripheral")
        peripheral.discoverServices([serviceUUID])
        
        // Test the connection after a short delay to ensure characteristics are discovered
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.testConnection()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(peripheral.name ?? "Unknown"), Error: \(error?.localizedDescription ?? "No error description")")
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
        }
        startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown"), Error: \(error?.localizedDescription ?? "No error")")
        DispatchQueue.main.async {
            self.connectionStatus = .disconnected
            self.peripheral = nil
            self.writeCharacteristic = nil
            self.appUpdateCharacteristic = nil
            self.appSwitchCharacteristic = nil
            self.appListRequestCharacteristic = nil
            self.chunkAckCharacteristic = nil
            self.runningApps.removeAll()
        }
        print("Restarting scan after disconnection")
        startScanning()
    }
}


// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovered services for peripheral: \(peripheral.name ?? "Unknown")")
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found")
            return
        }
        
        for service in services {
            print("Discovered service: \(service.uuid)")
            if service.uuid == serviceUUID {
                print("Found matching service, discovering characteristics")
                peripheral.discoverCharacteristics([characteristicUUID, appUpdateCharacteristicUUID, appSwitchCharacteristicUUID, appListRequestCharacteristicUUID, chunkAckCharacteristicUUID, textTransferCharacteristicUUID], for: service)
            }
        }
    }
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered characteristics for service: \(service.uuid)")
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics found")
            return
        }
        
        for characteristic in characteristics {
            print("Found characteristic: \(characteristic.uuid)")
            switch characteristic.uuid {
            case characteristicUUID:
                self.writeCharacteristic = characteristic
                print("Set write characteristic")
            case appUpdateCharacteristicUUID:
                self.appUpdateCharacteristic = characteristic
                print("Set app update characteristic")
                peripheral.setNotifyValue(true, for: characteristic)
                print("Enabled notifications for app update characteristic")
            case appSwitchCharacteristicUUID:
                self.appSwitchCharacteristic = characteristic
                print("Set app switch characteristic")
            case appListRequestCharacteristicUUID:
                self.appListRequestCharacteristic = characteristic
                print("Set app list request characteristic")
            case chunkAckCharacteristicUUID:
                self.chunkAckCharacteristic = characteristic
                print("Set chunk acknowledgment characteristic")
            case textTransferCharacteristicUUID:
                self.textTransferCharacteristic = characteristic
                print("Set text transfer characteristic: \(characteristic.uuid)")
            default:
                print("Unknown characteristic: \(characteristic.uuid)")
            }
        }
        
        print("Finished discovering characteristics, requesting app list")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.requestAppList()
        }
    }
        
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
        } else {
            print("Notification state updated for characteristic: \(characteristic.uuid)")
            print("Is notifying: \(characteristic.isNotifying)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Value updated for characteristic: \(characteristic.uuid)")
        if let error = error {
            print("Error receiving data: \(error.localizedDescription)")
            return
        }
        
        guard characteristic.uuid == appUpdateCharacteristicUUID,
              let value = characteristic.value else {
            print("Received data for unexpected characteristic or nil value")
            return
        }
        
        print("Received app update data. Size: \(value.count) bytes")
        handleAppUpdateChunk(value)
    }
    
    private func handleAppUpdateChunk(_ chunkData: Data) {
        guard chunkData.count > 3 else {
            print("Received chunk data is too short")
            return
        }
        
        let appIndex = Int(chunkData[0])
        let chunkIndex = Int(chunkData[1])
        let totalChunks = Int(chunkData[2])
        let payload = chunkData.dropFirst(3)
        
        if appDataBuffer[appIndex] == nil {
            appDataBuffer[appIndex] = Data()
        }
        appDataBuffer[appIndex]?.append(payload)
        
        // Send acknowledgment
        sendChunkAcknowledgment(appIndex: appIndex, chunkIndex: chunkIndex)
        
        if chunkIndex == totalChunks - 1 {
            // All chunks received, process the app data
            if let completeAppData = appDataBuffer[appIndex] {
                processAppData(completeAppData)
                appDataBuffer.removeValue(forKey: appIndex)
            }
        }
    }
    
    private func sendChunkAcknowledgment(appIndex: Int, chunkIndex: Int) {
        guard let characteristic = chunkAckCharacteristic else {
            print("Error: chunkAckCharacteristic is nil")
            return
        }
        var ackData = Data()
        ackData.append(UInt8(appIndex))
        ackData.append(UInt8(chunkIndex))
        peripheral?.writeValue(ackData, for: characteristic, type: .withResponse)
    }
    
    private func processAppData(_ appData: Data) {
        guard appData.count > 1 else {
            print("Received app data is too short")
            return
        }
        
        let isRemoved = appData[0] == 1
        var index = 1
        
        guard let bundleIdentifier = appData[index...].split(separator: 0).first,
              let name = appData[(index + bundleIdentifier.count + 1)...].split(separator: 0).first else {
            print("Failed to parse app data")
            return
        }
        
        index += bundleIdentifier.count + name.count + 2
        let iconData = appData[index...]
        
        let bundleIdString = String(data: Data(bundleIdentifier), encoding: .utf8) ?? "Unknown"
        let nameString = String(data: Data(name), encoding: .utf8) ?? "Unknown"
        
        print("Received app update: \(isRemoved ? "Removed" : "Added/Updated") - \(nameString) (\(bundleIdString))")
        print("Icon data size: \(iconData.count) bytes")
        
        DispatchQueue.main.async {
            if isRemoved {
                self.runningApps.removeAll { $0.bundleIdentifier == bundleIdString }
                print("Removed app from list: \(nameString)")
            } else {
                let appInfo = AppInfo(
                    bundleIdentifier: bundleIdString,
                    name: nameString,
                    icon: UIImage(data: iconData) ?? UIImage(systemName: "app.fill")!
                )
                if !self.runningApps.contains(where: { $0.bundleIdentifier == appInfo.bundleIdentifier }) {
                    self.runningApps.append(appInfo)
                    print("Added new app to list: \(nameString)")
                } else {
                    if let index = self.runningApps.firstIndex(where: { $0.bundleIdentifier == appInfo.bundleIdentifier }) {
                        self.runningApps[index] = appInfo
                        print("Updated existing app in list: \(nameString)")
                    }
                }
            }
            print("Current number of running apps: \(self.runningApps.count)")
        }
    }
}
struct AppInfo: Identifiable {
    let id = UUID()
    let bundleIdentifier: String
    let name: String
    let icon: UIImage
}

enum ConnectionStatus: String {
    case disconnected = "Disconnected"
    case scanning = "Scanning"
    case connecting = "Connecting"
    case connected = "Connected"
}

enum GestureType: Int8 {
    case move = 0
    case leftClick = 1
    case rightClick = 2
    case scroll = 3
    case switchSpaceLeft = 4
    case switchSpaceRight = 5
}

struct TrackpadData {
    let deltaX: Int8
    let deltaY: Int8
    let gestureType: GestureType
}

extension Data {
    func chunked(into size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            subdata(in: $0 ..< Swift.min($0 + size, count))
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
class MockBLEManager: BLEManager {
    override init() {
        super.init()
        self.connectionStatus = .connected
        self.runningApps = [
            AppInfo(bundleIdentifier: "com.apple.Safari", name: "Safari", icon: UIImage(systemName: "safari")!),
            AppInfo(bundleIdentifier: "com.apple.Mail", name: "Mail", icon: UIImage(systemName: "envelope")!),
            AppInfo(bundleIdentifier: "com.apple.Notes", name: "Notes", icon: UIImage(systemName: "note.text")!)
        ]
    }
    
    override func sendTrackpadData(deltaX: CGFloat, deltaY: CGFloat, gestureType: GestureType) {
        print("Mock send: deltaX: \(deltaX), deltaY: \(deltaY), gestureType: \(gestureType)")
    }
    
    override func switchToApp(bundleIdentifier: String) {
        print("Mock switch to app: \(bundleIdentifier)")
    }
    
    override func requestAppList() {
        print("Mock request app list")
    }
    override func sendTextToMac(_ text: String) {
        print("Mock: Sending text to Mac: \(text)")
    }
}
#endif
