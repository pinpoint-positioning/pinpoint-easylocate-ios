//
//  BluetoothManager.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 09.03.23.
//

import Foundation
import CoreBluetooth
import Combine
import UIKit
import SwiftUI


public class EasylocateAPI: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    public static let shared = EasylocateAPI()
    
    @Published public var connectionState:ConnectionState = .DISCONNECTED
    @Published public var bleState = BLEState.UNKNOWN
    @Published public var scanState:ScanState = .IDLE
    @Published public var localPosition = TraceletPosition()
    @Published public var connectedTracelet: CBPeripheral?
    @Published public var config = Config.shared
    
    private var comState:ComState = .IDLE
    private let logger = Logging.shared
    private var messageBuffer = [BufferElement]()
    private var discoveredTracelets = [CBPeripheral]()
    private var centralManager: CBCentralManager!
    private var rxCharacteristic: CBCharacteristic?
    private let traceletNames = ["dwTag", "dw3kTag", "Quad", "quad"]
    
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
        logger.log(type: .info, "SDK initiated: \n  BT-state: \(bleState)")
    }
    
    
    
    // MARK: - Exposed Public Functions
    
    /// Initiate a scan for nearby tracelets
    /// - Parameters:
    ///   - timeout: timeout for the scan in seconds
    ///   - completion: returns a list of nearby tracelets as [CBPeripheral]
    public func scan(timeout: Double, completion: @escaping (([CBPeripheral]) -> Void)) {
        guard bleState == .BT_OK else {
            logger.log(type: .error, "Bluetooth not available: \(bleState)")
            return
        }
        
        guard !centralManager.isScanning else {
            logger.log(type: .error, "Scan not started: Scan already running")
            return
        }
        guard connectionState == ConnectionState.DISCONNECTED else {
            
            logger.log(type: .error, "Scan not started: State was: \(connectionState)")
            return
        }
        
        discoveredTracelets = []
        
        // Set State
        changeScanState(newState: .SCANNING)
        // Added a delay so people have the chance to bring device closer to the phone before scanning starts
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            //Set to true, to continously searching for devices. Helpful when device is out of range and getting closer (RSSI)
            let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)]
            
            //Initiate BT Scan
            self.centralManager.scanForPeripherals(withServices: nil, options: options)
            self.logger.log(type: .info, "Scan started")
            
            // Stop scan after timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                self.stopScan()
                
                if self.discoveredTracelets == [] {
                    self.logger.log(type: .warning, "No tracelets discovered")
                    completion([])
                } else {
                    self.logger.log(type: .info, "Discovered tracelets: \(self.discoveredTracelets)")
                }
                completion(self.discoveredTracelets)
            }
        }
    }
    
    
    
    /// Stops the scaning process for nearby tracelets
    public func stopScan() {
        centralManager.stopScan()
        changeScanState(newState: .IDLE)
        logger.log(type: .info, "Scan stopped")
    }
    
    
    
    public var connectionSource: ConnectionSource?
    private var connectContinuation: CheckedContinuation<Bool, any Error>? = nil
    
    /// Starts a connection attempt to a nearby tracelet
    /// - Parameter device: Pass a discovered tracelet-object
    /// - Returns: Bool (Success)
    public func connect(device: CBPeripheral) async throws -> Bool{
        changeConnectionState(newState: .CONNECTING)
        connectionSource = .regularConnect
        
        logger.log(type: .info, "Connection attempt initiated")
        guard connectionState != ConnectionState.CONNECTED else {
            logger.log(type: .warning, "Already connected")
            return false
        }
        
        return try await withCheckedThrowingContinuation { cont in
            self.connectContinuation = cont
            centralManager.connect(device, options: nil)
        }
    }
    
    
    
    /// Starts a connection attempt to a nearby tracelet and starts positioning
    /// - Parameter device: Pass a discovered tracelet-object
    public func connectAndStartPositioning(device: CBPeripheral) async throws -> Bool{
        changeConnectionState(newState: .CONNECTING)
        connectionSource = .connectAndStartPositioning
        
        logger.log(type: .info, "Connection attempt initiated")
        guard connectionState != ConnectionState.CONNECTED else {
            logger.log(type: .warning, "Already connected")
            return false
        }
        
        return try await withCheckedThrowingContinuation { cont in
            self.connectContinuation = cont
            centralManager.connect(device, options: nil)
        }
    }
    
    
    
    
    /// Disconnects from a tracelet
    public func disconnect() {
        logger.log(type: .info, "Disconnecting")
        if let tracelet = connectedTracelet {
            centralManager.cancelPeripheralConnection(tracelet)
        }
        connectedTracelet = nil
    }
    
    
    
    /// Sends a ShowMe -command to the tracelet
    /// - Parameter tracelet: pass a connected tracelet object
    public func showMe(tracelet: CBPeripheral? = nil) {
        var device: CBPeripheral?
        
        if tracelet == nil {
            device = connectedTracelet
        } else {
            device = tracelet
        }
        
        guard let selectedDevice = device else {
            // Handle the case where no tracelet is available
            logger.log(type: .error, "No tracelet available.")
            return
        }
        
        let result = send(to: selectedDevice, data: [ProtocolConstants.cmdCodeShowMe])
        logger.log(type: .info, "ShowMe - \(result) ")
    }
    
    
    
    
    /// Sends the command to start the UWB-positioning to the tracelet
    public func startPositioning() {
        guard let tracelet = connectedTracelet else {
            logger.log(type: .error, "No tracelet connected")
            return
        }
        let result = send(to: tracelet, data:  [ProtocolConstants.cmdCodeStartPositioning])
        logger.log(type: .info, "Start Positioning - \(result)")
    }
    
    
    
    /// Sends the command to stop the UWB-positioning to the tracelet
    public func stopPositioning() {
        
        guard let tracelet = connectedTracelet else {
            // handle missing tracelet or characteristic
            return
        }
        let result = send(to: tracelet, data: [ProtocolConstants.cmdCodeStopPositioning])
        logger.log(type: .info,"Stop Positioning - \(result)")
    }
    
    
    /// Sets the Channel to 5 or 9
    /// - Parameter channel: channel 5 or 9
    public func setChannel(channel:Int8, preamble:Int8 = 9) -> Bool {
        let Uint8Channel: UInt8 = UInt8(bitPattern: channel)
        let Uint8preamble: UInt8 = UInt8(bitPattern: preamble)
        let dataArray:[UInt8] = [ProtocolConstants.cmdCodeSetChannel, Uint8Channel, Uint8preamble]
        var success = false
        
        if let tracelet = connectedTracelet {
            success = send(to: tracelet, data: dataArray)
            logger.log(type: .info, "Channel set to:  \(channel), Success:\(success)")
            return success
        } else {
            return false
        }
        
    }
    
    
    /// Sets the SiteID to listen to
    /// - Parameter channel: siteID eg. 0x0001
    public func setSiteID(siteID: UInt16) async -> Bool {
        var success = false
        // Ensure that siteID is within the range of UInt16
        guard siteID <= UInt16(Int16.max) else {
            logger.log(type: .error, "siteID is not a valid UInt16 value")
            return false  // Return false if siteID is out of range
        }
        
        let dataArray: [UInt16] = [UInt16(ProtocolConstants.cmdCodeSetSiteID), siteID]
        
        var uint8Array = [UInt8]()
        for value in dataArray {
            withUnsafeBytes(of: value) { uint8Array.append(contentsOf: $0) }
        }
        logger.log(type: .info, "Sent: \(uint8Array)")
        
        if let tracelet = connectedTracelet {
            success = send(to: tracelet, data: uint8Array)
            
            logger.log(type: .info, "SiteID set to: \(String(siteID, radix: 16)), Success: \(success)")
        } else {
            success = false
            logger.log(type: .error, "No Tracelet connected")
        }
        
        return success
    }
    
    
    /// Sets a positioning interval
    /// - Parameter interval: interval in n x 250ms
    public func setPositioningInterval(interval:UInt8) {
        
        let dataArray = [ProtocolConstants.cmdCodeSetPositioningInterval, interval]
        if let tracelet = connectedTracelet {
            let result = send(to: tracelet, data: dataArray)
            logger.log(type: .info, "Interval set to:  \(interval) - \(result)")
        }
    }
    
    
    
    /// Get the status of a connected tracelet
    /// - Returns: status object
    public func getStatus() async -> TraceletStatus? {
        guard connectionState == ConnectionState.CONNECTED else {
            logger.log(type: .error, "State is \(connectionState)")
            return nil
        }
        logger.log(type: .info, "Status requested")
        
        if let tracelet = connectedTracelet {
            let _ = send(to: tracelet, data: [ProtocolConstants.cmdCodeGetStatus])
            changeComState(newState: .WAITING_FOR_RESPONSE)
        }
        
        let response = await getResponseFromBuffer(cmdCode: ProtocolConstants.cmdCodeStatus)
        if let response = response {
            let status = await TraceletResponse().GetStatusResponse(from: response)
            logger.log(type: .info, "Status response: \(String(describing: status))")
            return status
        } else {
            return nil
        }
    }
    
    
    
    // Use RSSI to connect only when close ( > -50 db).
    // Sometimes RSSI returns max value 127. Excluded it for now.
    // Maybe include PowerTX Level- -> TBD
    
    private func inProximity(_ RSSI: NSNumber) -> Bool {
        if (RSSI.intValue > -60 && RSSI != 127){
            return true
        } else {
            return false
        }
    }
    
    

    
    /// Requests the firmware version from the tracelet (async)
    /// - Returns: String
    public func getVersion() async -> String? {
        guard connectionState == ConnectionState.CONNECTED else {
            logger.log(type: .error, "State is \(connectionState)")
            return nil
        }
        if let tracelet = connectedTracelet {
            let _ = send(to: tracelet, data: [ProtocolConstants.cmdCodeGetVersion])
            changeComState(newState: .WAITING_FOR_RESPONSE)
        }
        let response = await getResponseFromBuffer(cmdCode: ProtocolConstants.cmdCodeVersion)
        if let response = response {
            let version = await TraceletResponse().getVersionResponse(from: response)
            logger.log(type: .info, "Version response: \(String(describing: version))")
            return version.version
        } else {
            return nil
        }
        
    }
    
    
    
    private func getResponseFromBuffer(cmdCode:UInt8) async -> Data? {
        let buffer = await freezeBuffer()
        var messageFound = false
        for message in buffer {
            if (getCmdByte(from: message.message) == cmdCode)  {
                messageFound = true
                self.logger.log(type: .info, "Message found in \n Buffer: [\(await TraceletResponse().getVersionResponse(from: message.message))]")
                self.messageBuffer.removeAll()
                return message.message
            }
        }
        if !messageFound {
            self.logger.log(type: .warning, "Message not found in buffer\n Buffer: [\(buffer.description)]")
            return nil
        }
    }
    
    
    
    // MARK: - Private Functions
    
    /// Sents a command to a tracelet
    /// - Parameters:
    ///   - tracelet: tracelet object
    ///   - data: command content
    /// - Returns: bool
    private func send(to tracelet: CBPeripheral, data: [UInt8]) -> Bool {
        var success = false
        guard connectionState == ConnectionState.CONNECTED else {
            logger.log(type: .error, "State must be CONNECTED to use send()")
            return success
        }
        let encData = (config.uci ?  UCIEncoder().encodeBytes(Data(data)): Encoder.encodeByte(Data(data)))
        if let rxCharacteristic = rxCharacteristic {
            tracelet.writeValue(encData, for: rxCharacteristic,type: CBCharacteristicWriteType.withResponse)
            success = true
        }
        return success
    }
    
    private func storeInBuffer(data:BufferElement) {
        
        if (messageBuffer.count > 10)
        {
            messageBuffer.removeFirst()
        }
        messageBuffer.append(data)
        
    }
    
    
    private func freezeBuffer() async -> [BufferElement]  {
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            self.logger.log(type: .warning, "Waiting time was cancelled.")
        }
        
        let buffer = self.messageBuffer
        
        return buffer
    }
    
    
    
    
    private func ClassifyResponse (from byteArray: Data)
    
    {
        // UCI or Legacy
        let valByteArray = (config.uci ? UCIDecoder().decode(data: byteArray) : Decoder().validateMessage(of: byteArray))
        
        if byteArray.isEmpty {
            return
        }
        
        if (valByteArray[0] == ProtocolConstants.cmdCodePosition)
        {
            localPosition = TraceletResponse().GetPositionResponse(from: byteArray)
        }
        
        if (valByteArray[0] == ProtocolConstants.cmdCodeStatus)
        {
            logger.log(type: .info, "Received Status")
            //status =  TraceletResponse().GetStatusResponse(from: byteArray)
        }
        
        if (valByteArray[0] == ProtocolConstants.cmdCodeVersion)
        {
            logger.log(type: .info, "Received Version")
            //version =  TraceletResponse().getVersionResponse(from: byteArray)
        }
        
    }
    
    
    
    private func getCmdByte(from data: Data) -> UInt8? {
        let valMesssage = UCIDecoder().decode(data: data)
        //   let valMesssage = Decoder().ValidateMessage(of: data)
        
        // Check if the valMesssage array is not empty and the index is within bounds
        if !valMesssage.isEmpty{
            return valMesssage[0]
        } else {
            logger.log(type: .warning, "No command byte found")
            return nil
        }
    }
    
    
    private func changeConnectionState(newState:ConnectionState) {
        DispatchQueue.main.async {
            self.connectionState = newState
        }
    }
    
    private func changeComState(newState:ComState) {
        DispatchQueue.main.async {
            self.comState = newState
        }
    }
    
    
    private func changeScanState(newState:ScanState) {
        DispatchQueue.main.async {
            self.scanState = newState
        }
    }
    
    
    //MARK: - Delegate Functions
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bleState = BLEState.BT_OK
            logger.log(type: .info, "BT changed to \(bleState)")
            break
        case .poweredOff:
            bleState = BLEState.BT_NA
            logger.log(type: .info, "BT changed to \(bleState)")
            break
        case .resetting:
            logger.log(type: .info, "BT changed to \(bleState)")
            break
        case .unauthorized:
            logger.log(type: .info, "BT changed to \(bleState)")
            break
        case .unsupported:
            logger.log(type: .info, "BT changed to \(bleState)")
            break
        case .unknown:
            logger.log(type: .info, "BT changed to \(bleState)")
            break
        default:
            break
        }
    }
    
    
    
    func getDeviceTypeAndNamePrefixFromIdent(did: Int) -> (String, String) {
        var name = "unknown"
        var deviceType = "unknown"
        
        switch did & 0xE {
        case 0x0:
            name = "SATlet"
            deviceType = "satlet"
        case 0x2:
            name = "TRACElet"
            deviceType = "tracelet"
        case 0x4:
            name = "quadTag"
            deviceType = "tracelet" // Or another appropriate type
        case 0xC:
            name = "TRACEletDummy"
            deviceType = "tracelet"
        default:
            break
            // logger.log(type: .info, "Unknown device type from did & 0xE: \(String(format: "0x%02X", did & 0xE))")
        }
        
        switch did {
        case 0x25:
            name = "TRACElet"
            deviceType = "tracelet"
        case 0x75:
            name = "AnotherDevice" // Replace with correct name
            deviceType = "tracelet" // Replace with correct type
        default:
            break
            // logger.log(type: .info, "Unknown device type from did: \(String(format: "0x%02X", did))")
        }
        
        // Suffix mapping
        switch did >> 4 {
        case 0:
            name += "-Q1k"
        case 1:
            name += "-PP10"
        case 2:
            name += "-quadTag"
        case 3:
            name += "-Q3k"
        case 4:
            name += "-PP20"
        case 5:
            name += "-CarTag/SIO"
        case 7:
            name += "-SpecialSuffix" // Handle the specific case of 0x07
        default:
            break
           // logger.log(type: .info, "Unknown suffix for name from did >> 4: \(String(format: "0x%02X", did >> 4))")
        }

        return (deviceType, name)
    }

    // Called when discovered a device during BLE scan
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.delegate = self
        
        
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let bytes = [UInt8](manufacturerData)
            guard bytes.count >= 3 else {
              //  print("Manufacturer data too short: \(bytes)")
                return
            }
            
            let did = Int(bytes[0])
            let addr = Int(bytes[1]) << 8 | Int(bytes[2])
            let typeAndName = getDeviceTypeAndNamePrefixFromIdent(did: did)
            let name = "\(typeAndName.1)-\(String(format: "%02X%02X", bytes[2], bytes[1]))"
            
            if traceletNames.contains(where: { name.contains($0) }) {
                
                if discoveredTracelets.contains(peripheral) {
                    return
                }
                
                if inProximity(RSSI) {
                    logger.log(type: .info, "Tracelet \(name) in range. RSSI: \(RSSI)")
                    
                    var insertIndex = 0
                    for (index, existingPeripheral) in discoveredTracelets.enumerated() {
                        if let existingRSSI = existingPeripheral.value(forKey: "RSSI") as? NSNumber {
                            if RSSI.intValue > existingRSSI.intValue {
                                insertIndex = index + 1
                            }
                        }
                    }
                    discoveredTracelets.insert(peripheral, at: insertIndex)
                }
            }
        }
    }
    
    
    // Delegate - Called when connection was successful
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScan()
        connectedTracelet = peripheral
        logger.log(type: .info, "Connected to: \(peripheral.name ?? "unknown device")")
        changeConnectionState(newState: .CONNECTED)
        // Discover UART Service
        peripheral.discoverServices([UUIDs.traceletNordicUARTService])
        
        
    }
    
    
    // Delegate - Called when services are discovered
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                
                // Discover UART Service
                if service.uuid == UUIDs.traceletNordicUARTService{
                    peripheral.discoverCharacteristics([UUIDs.traceletRxChar,UUIDs.traceletTxChar], for: service)
                    logger.log(type: .info, "Services discovered: \(service.uuid), \(service.description)")
                }
                
                return
            }
        }
    }
    
    
    
    // Delegate - Called when chars are discovered
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                // Get Characteristics and store in vars
                if characteristic.uuid == UUIDs.traceletTxChar {
                    logger.log(type: .info, "Found TX-Char: \(characteristic.uuid)")
                    
                    if characteristic.properties.contains(.notify) {
                        
                        // Moved to StartPositioning()
                        peripheral.setNotifyValue(true, for: characteristic)
                        changeComState(newState: .WAITING_FOR_RESPONSE)
                        
                        
                    }
                }
                else if characteristic.uuid == UUIDs.traceletRxChar {
                    
                    logger.log(type: .info, "Found RX-Char: \(characteristic.uuid)")
                    rxCharacteristic = characteristic
                    
                    switch connectionSource {
                    case .regularConnect:
                        logger.log(type: .info, "Regular connect action")
                        
                        // If the RX Char is found, then continue the cont to return true to the connect-function
                        if let cont = connectContinuation {
                            cont.resume(returning: true)
                            self.connectContinuation = nil
                        }
                        //StopPos on regular connect
                        stopPositioning()
                        
                        
                    case .connectAndStartPositioning:
                        logger.log(type: .info, "Connect and start positioning action")
                        // If the TX Char is found, then continue the cont to return true to the connect-function
                        if let cont = connectContinuation {
                            cont.resume(returning: true)
                            self.connectContinuation = nil
                        }
                        //StartPos on ConnectAndStartPositioning
                        startPositioning()
                        
                        
                    case .none:
                        logger.log(type: .warning, "Unkown connection action")
                        // self.connectContinuation = nil
                    }
                    // Reset connection source
                    connectionSource = nil
                    
                }
            }
        }
    }
    
    
    // Delegate method to handle response
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Failed to write value: \(error.localizedDescription)")
        } else {
            print("Successfully wrote value to characteristic \(characteristic.uuid)")
        }
    }
    
    // Delegate - Called when char value has updated for defined char
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,error: Error?) {
        guard let data = characteristic.value else {
            // no data transmitted, handle if needed
            logger.log(type: .warning, "No data received")
            return
        }
        
        // Get TX  value
        if characteristic.uuid == UUIDs.traceletTxChar {
            
            switch comState {
            case .WAITING_FOR_RESPONSE:
                storeInBuffer(data: BufferElement(message: data))
                ClassifyResponse(from: data)
            default:
                logger.log(type: .warning, "Unknown message: \(data)")
            }
        }
    }
    
    
    
    // Delegate - Called when disconnected
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.log(type: .info, "Disconnected from TRACElet")
        changeConnectionState(newState: .DISCONNECTED)
        
    }
    
    
    //Failsafe Delegate Functions
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        
        if let cont = connectContinuation {
            if let error = error {
                cont.resume(throwing: error)
            } else {
                cont.resume(returning: false)
            }
            
            self.connectContinuation = nil
        }
        
        logger.log(type: .warning, "Failed to connect: \(error?.localizedDescription ?? "unknown error")")
        changeConnectionState(newState: .DISCONNECTED)
        
    }
    
}



