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



public class API: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    public static let shared = API()
    let logger = Logger.shared
    
    
    // Properties
    @Published public var allResponses = String()
    
    // Published vars
    // ### Debug only ###
    public var positionLog = String()
    /// ### Debug End ###
    
    @Published public var generalState:STATE = .DISCONNECTED
    @Published public var scanState:STATE = .IDLE
    @Published public var comState:STATE = .IDLE
    @Published public var bleState = BLE_State.UNKNOWN
    
    @Published public var localPosition = TL_PositionResponse()
    @Published public var status = TL_StatusResponse()
    @Published public var version = TL_VersionResponse()
    var discoveredTracelets = [CBPeripheral]()
    @Published public var connectedTracelet: CBPeripheral?
    
    private var response:Data?
    // Buffer
    public var messageBuffer = [BufferElement]()
    
    var centralManager: CBCentralManager!
    
    let decoder = Decoder()
    var rxCharacteristic: CBCharacteristic?
    
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
        logger.log(type: .Info, "SDK initiated: \n  BT-state: \(centralManager.state)")
    }
    
    
    
    
    //    // MARK: - ScanForDevices()
    //
    //    public func scanForBluetoothDevices() -> [CBPeripheral] {
    //        var discoveredPeripherals: [CBPeripheral] = []
    //       // let centralManager = CBCentralManager()
    //
    //        centralManager.scanForPeripherals(withServices: nil, options: nil)
    //
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
    //            self.centralManager.stopScan()
    //        }
    //
    //        while centralManager.isScanning {
    //            RunLoop.current.run(mode: .default, before: .distantFuture)
    //        }
    //
    //        discoveredPeripherals = centralManager.retrievePeripherals(withIdentifiers: [])
    //        return discoveredPeripherals
    //    }
    //
    //
    //    // MARK: - Scan()
    //
    //
    //    public func scanForBluetoothDevices() async throws -> [CBPeripheral] {
    //        let manager = CBCentralManager()
    //
    //
    //        return try await withCheckedThrowingContinuation { continuation in
    //            let peripherals = manager.retrievePeripherals(withIdentifiers:[])
    //            continuation.resume(returning: peripherals)
    //        }
    //    }
    //
    
    
    
    
    
    // MARK: - Scan()
    
    /// Initiate a scan for nearby tracelets
    /// - Parameters:
    ///   - timeout: timeout for the scan in seconds
    ///   - completion: returns a list of nearby tracelets as [CBPeripheral]
    public func scan(timeout: Double, completion: @escaping (([CBPeripheral]) -> Void))
    {
        logger.log(type: .Info, "Scan started (State: \(generalState))")
        
        guard bleState == .BT_OK else {
            logger.log(type: .Error, "Bluetooth not available: \(bleState)")
            return
        }
        
        guard !centralManager.isScanning else {
            logger.log(type: .Error, "Scan not started: Scan already running")
            return
        }
        guard generalState == STATE.DISCONNECTED else {
            
            logger.log(type: .Error, "Scan not started: State was: \(generalState)")
            return
        }
        discoveredTracelets = []
        
        // Set State
        changeScanState(changeTo: .SCANNING)
        
        //Set to true, to continously searching for devices. Helpful when device is out of range and getting closer (RSSI)
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: false)]
        
        //Initiate BT Scan
        centralManager.scanForPeripherals(withServices: nil, options: options)
        
        // Stop scan after timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.stopScan()
            
            if self.discoveredTracelets == [] {
                self.logger.log(type: .Warning, "No tracelets discovered")
                completion([])
            } else {
                self.logger.log(type: .Info, "Discovered tracelets: \(self.discoveredTracelets)")
            }
            completion(self.discoveredTracelets)
        }
    }
    
    
    
    
    // MARK: - StopScan()
    
    /// Stops the scaning process for nearby tracelets
    public func stopScan() {
        centralManager.stopScan()
        changeScanState(changeTo: .IDLE)
        logger.log(type: .Info, "Scan stopped")
    }
    
    

    
    // MARK: - Connect()

    

    public enum ConnectionSource {
        case regularConnect
        case connectAndStartPositioning
    }
    
    public var connectionSource: ConnectionSource?
    private var connectContinuation: CheckedContinuation<Bool, any Error>? = nil
    
    /// Starts a connection attempt to a nearby tracelet
    /// - Parameter device: Pass a discovered tracelet-object
    public func connect(device: CBPeripheral) async throws -> Bool{
        connectionSource = .regularConnect
 
        logger.log(type: .Info, "Connection attempt initiated")
        guard generalState != STATE.CONNECTED else {
            logger.log(type: .Warning, "Already connected")
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
        connectionSource = .connectAndStartPositioning
 
        logger.log(type: .Info, "Connection attempt initiated")
        guard generalState != STATE.CONNECTED else {
            logger.log(type: .Warning, "Already connected")
            return false
        }
        
        return try await withCheckedThrowingContinuation { cont in
            self.connectContinuation = cont
            centralManager.connect(device, options: nil)
        }
    }
    
    
    
    // MARK: - Disconnect()
    
    /// Disconnects from a tracelet
    public func disconnect() {
        logger.log(type: .Info, "start disconnecting")
        if let tracelet = connectedTracelet {
            centralManager.cancelPeripheralConnection(tracelet)
        }
        
        connectedTracelet = nil
    }
    
    
    // MARK: - Send()
    // Send write command to BT device
    /// Sents a command to a tracelet
    /// - Parameters:
    ///   - tracelet: tracelet object
    ///   - data: command content
    /// - Returns: bool
    func send(to tracelet: CBPeripheral, data: Data) -> Bool {
        var success = false
        guard generalState == STATE.CONNECTED else {
            logger.log(type: .Error, "State must be CONNECTED to use send()")
            return success
        }
        if let rxCharacteristic = rxCharacteristic {
            tracelet.writeValue(data as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
            success = true
        }
        return success
    }
    
    
    
    
    
    func sendWithResponse(to tracelet: CBPeripheral, data: Data) {
        guard generalState == STATE.CONNECTED else {
            logger.log(type: .Error, "State must be CONNECTED to use send()")
            return
        }
        
        if let rxCharacteristic = rxCharacteristic {
            tracelet.writeValue(data as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withResponse)
            
        }
    }
    
    
    
    // MARK: - ShowMe()
    
    /// Sends a ShowMe -command to the tracelet
    /// - Parameter tracelet: pass a connected tracelet object
    public func showMe(tracelet: CBPeripheral) {
        let cmdByte = ProtocolConstants.cmdCodeShowMe
        let data = Encoder.encodeByte(cmdByte)
        let result = send(to: tracelet, data: data)
        logger.log(type: .Info, "ShowMe - \(result) ")
    }
    
    // MARK: - startPositioning()
    
    /// Sends the command to start the UWB-positioning to the tracelet
    public func startPositioning() {
        guard let tracelet = connectedTracelet else {
            logger.log(type: .Error, "No tracelet connected")
            return
        }
        let cmdByte = ProtocolConstants.cmdCodeStartPositioning
        let data = Encoder.encodeByte(cmdByte)
        let result = send(to: tracelet, data: data)
        logger.log(type: .Info, "Start Positioning - \(result)")
    }
    
    
    // MARK: - stopPositioning()
    /// Sends the command to stop the UWB-positioning to the tracelet
    public func stopPositioning() {
        
        guard let tracelet = connectedTracelet else {
            // handle missing tracelet or characteristic
            return
        }
        let cmdByte = ProtocolConstants.cmdCodeStopPositioning
        let data = Encoder.encodeByte(cmdByte)
        let result = send(to: tracelet, data: data)
        logger.log(type: .Info,"Stop Positioning - \(result)")
    }
    
    
    /// Sets the Channel to 5 or 9
    /// - Parameter channel: channel 5 or 9
    public func setChannel(channel:Int8) async -> Bool {
        let Uint8Channel: UInt8 = UInt8(bitPattern: channel)
        let dataArray:[UInt8] = [ProtocolConstants.cmdCodeSetChannel, Uint8Channel]
        var success = false
        
        if let tracelet = connectedTracelet {
            success = send(to: tracelet, data: Encoder.encodeBytes(dataArray))
            
            logger.log(type: .Info, "Channel set to:  \(channel), Success:\(success)")
        }
        
        return success
    }
    
    
    
    
    /// Sets a positioning interval
    /// - Parameter interval: interval in n x 250ms
    public func setPositioningInterval(interval:Int8) {
        let Uint8Interval: UInt8 = UInt8(bitPattern: interval)
        let dataArray:[UInt8] = [ProtocolConstants.cmdCodeSetPositioningInterval, Uint8Interval]
        
        if let tracelet = connectedTracelet {
            let result = send(to: tracelet, data: Encoder.encodeBytes(dataArray))
            logger.log(type: .Info, "Interval set to:  \(interval) - \(result)")
        }
    }
    
    
    // MARK: - changeStates
    
    func changeGeneralState(changeTo:STATE) {
        DispatchQueue.main.async {
            self.generalState = changeTo
        }
    }
    
    func changeComState(changeTo:STATE) {
        DispatchQueue.main.async {
            self.comState = changeTo
        }
    }
    
    
    func changeScanState(changeTo:STATE) {
        DispatchQueue.main.async {
            self.scanState = changeTo
        }
    }
    
    // MARK: - getStatus()
    
    
    /// Get the status of a connected tracelet
    /// - Returns: status object
    public func getStatus() async -> TL_StatusResponse? {
        guard generalState == STATE.CONNECTED else {
            logger.log(type: .Error, "State is \(generalState)")
            return nil
        }
        logger.log(type: .Info, "Status requested")
        let cmdByte = ProtocolConstants.cmdCodeGetStatus
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            sendWithResponse(to: tracelet, data: data)
            changeComState(changeTo: .WAITING_FOR_RESPONSE)
        }
        
        let status = await getStatusFromBuffer()
        logger.log(type: .Info, "Status response: \(String(describing: status))")
        return status
    }
    
    
    
    func getStatusFromBuffer() async -> TL_StatusResponse? {
        
        let buffer = await freezeBuffer()
        var messageFound = false
        for message in buffer {
            if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodeStatus)  {
                messageFound = true
                let response = TraceletResponse().GetStatusResponse(from: message.message)
                self.logger.log(type: .Info, "Message found in \n Buffer: [\(TraceletResponse().GetStatusResponse(from: message.message))]")
                self.messageBuffer.removeAll()
                return response
            }
        }
        if !messageFound {
            self.logger.log(type: .Warning, "Message not found in buffer\n Buffer: [\(buffer.description)]")
            return nil
        }
    }
    
    // MARK: - getPosition()
    
    public func requestPosition() {
        
        logger.log(type: .Info, "Position requested")
        guard generalState == STATE.CONNECTED else {
            logger.log(type: .Error, "State is \(generalState)")
            return
        }
        
        let cmdByte = ProtocolConstants.cmdCodeStartPositioning
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            sendWithResponse(to: tracelet, data: data)
        }
        
        changeComState(changeTo: .WAITING_FOR_RESPONSE)
        
    }
    
    
    
    // Use RSSI to connect only when close ( > -50 db).
    // Sometimes RSSI returns max value 127. Excluded it for now.
    // Maybe include PowerTX Level- -> TBD
    
    private func inProximity(_ RSSI: NSNumber) -> Bool {
        if (RSSI.intValue > -50 && RSSI != 127){
            return true
        } else {
            return false
        }
    }

    
    
    
    // MARK: - getVersion()
    
    /// Requests the firmware version from the tracelet (async)
    /// - Returns: String
    public func getVersion() async -> String? {
        guard generalState == STATE.CONNECTED else {
            logger.log(type: .Error, "State is \(generalState)")
            return nil
        }
        let cmdByte = ProtocolConstants.cmdCodeGetVersion
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            sendWithResponse(to: tracelet, data: data)
            changeComState(changeTo: .WAITING_FOR_RESPONSE)
        }
        let version = await getVersionFromBuffer()
        logger.log(type: .Info, "Version response: \(String(describing: version))")
        return version
    }
    
    
    
    func getVersionFromBuffer() async -> String? {
        
        let buffer = await freezeBuffer()
        var messageFound = false
        for message in buffer {
            if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodeVersion)  {
                messageFound = true
                let response = TraceletResponse().getVersionResponse(from: message.message)
                self.logger.log(type: .Info, "Message found in \n Buffer: [\(TraceletResponse().getVersionResponse(from: message.message))]")
                self.messageBuffer.removeAll()
                return response.version
            }
        }
        if !messageFound {
            self.logger.log(type: .Warning, "Message not found in buffer\n Buffer: [\(buffer.description)]")
            return nil
        }
    }
    
    
    
    // MARK: - Buffer handling
    
    public func storeInBuffer(data:BufferElement) {
        
        if (messageBuffer.count > 10)
        {
            messageBuffer.removeFirst()
        }
        messageBuffer.append(data)
        
    }
    
    
    // ZEIT????
    // Delay until buffer is frozen when requested
    
    public func freezeBuffer() async -> [BufferElement]  {
        do {
            try await Task.sleep(nanoseconds: 500_000_000)
        } catch {
            self.logger.log(type: .Warning, "Waiting time was cancelled.")
        }
        
        let buffer = self.messageBuffer
        
        return buffer
    }
    
    
    // MARK: - Debug - Logger
    // ###################### DEBUG #########################
    // Only for Debug -> Save logged data to file
    
    public func openDir() {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = getDocumentsDirectory().appendingPathComponent("positionLog\(Date()).txt")
        
        if let sharedUrl = URL(string: "shareddocuments://\(documentsUrl.path)") {
            if UIApplication.shared.canOpenURL(sharedUrl) {
                UIApplication.shared.open(filename, options: [:])
            }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    public func clearLogFile () {
        logger.clearLogFile()
    }
    
    
    // ###################### DEBUG END #########################
    

    
    // MARK: - ClassifyResponse()

    public func ClassifyResponse (from byteArray: Data)

    {
        let valByteArray = Decoder().ValidateMessage(of: byteArray)
        
        if (valByteArray[0] == ProtocolConstants.cmdCodePosition)
        {
            localPosition = TraceletResponse().GetPositionResponse(from: byteArray)
            allResponses = "X: \(localPosition.xCoord) Y: \(localPosition.yCoord) Z: \(localPosition.zCoord) \n"
            
            // Uncomment to log all positions
            //logger.log(type: .Info, "Pos \(localPosition.xCoord) \(localPosition.yCoord)")
        }
        
        if (valByteArray[0] == ProtocolConstants.cmdCodeStatus)
        {
            status =  TraceletResponse().GetStatusResponse(from: byteArray)
            allResponses = "role: \(status.role) panID: \(status.panID) site: \(status.siteIDe)\n"
        }
        
        if (valByteArray[0] == ProtocolConstants.cmdCodeVersion)
        {
            version =  TraceletResponse().getVersionResponse(from: byteArray)
            allResponses = "version: \(version.version)\n\n"
        }
        
    }
    
    
    
    public func getCmdByte(from data: Data) -> UInt8 {
        
        let valMesssage = Decoder().ValidateMessage(of: data)
        return valMesssage[0]
        
    }
    
    
    //MARK: - Delegate Functions
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bleState = BLE_State.BT_OK
            logger.log(type: .Info, "BT changed to \(bleState)")
            break
        case .poweredOff:
            bleState = BLE_State.BT_NA
            logger.log(type: .Info, "BT changed to \(bleState)")
            break
        case .resetting:
            logger.log(type: .Info, "BT changed to \(bleState)")
            break
        case .unauthorized:
            logger.log(type: .Info, "BT changed to \(bleState)")
            break
        case .unsupported:
            logger.log(type: .Info, "BT changed to \(bleState)")
            break
        case .unknown:
            logger.log(type: .Info, "BT changed to \(bleState)")
            break
        default:
            break
        }
    }
    
    
    
    // Scantime ??
    
    // Delegate - Called when scan has results
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        peripheral.delegate = self
        // Needs to be improved -> This should return a list of devices!
        // Connect either to Dummy(df2b) or "black Tracelet" (6ec6)
        
        if (peripheral.name?.contains("dwTag") ?? false || peripheral.name?.contains("dw3kTag") ?? false) {
            if discoveredTracelets.contains(peripheral)
            {
                logger.log(type: .Info, "Tracelet \(peripheral.name ?? "") already in list")
            } else {
                logger.log(type: .Info, "Tracelet \(peripheral.name ?? "") discovered")
                if inProximity(RSSI) {
                    logger.log(type: .Info, "Tracelet \(peripheral.name ?? "") in range. RSSI: \(RSSI)")
                    discoveredTracelets.append(peripheral)
                }
                
            }
            
 
            
        }
        
    }
    
    
    
    // Delegate - Called when connection was successful
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Set State
        generalState = STATE.CONNECTED
        stopScan()
        
        logger.log(type: .Info, "Connected to: \(String(describing: peripheral.name))")
        connectedTracelet = peripheral
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
                    logger.log(type: .Info, "Services discovered: \(service.uuid), \(service.description)")
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
                    logger.log(type: .Info, "Discovered characteristic: \(characteristic.uuid)")

                    if characteristic.properties.contains(.notify) {
                        
                        // Moved to StartPositioning()
                        peripheral.setNotifyValue(true, for: characteristic)
                        changeComState(changeTo: .WAITING_FOR_RESPONSE)
                        
                        
                    }
                }
                else if characteristic.uuid == UUIDs.traceletRxChar {
                    
                    
                    logger.log(type: .Info, "Discovered characteristic: \(characteristic.uuid)")
                    rxCharacteristic = characteristic
                    
                    switch connectionSource {
                    case .regularConnect:

                        logger.log(type: .Info, "Regular connect action")

                        // If the RX Char is found, then continue the cont to return true to the connect-function
                            if let cont = connectContinuation {
                                cont.resume(returning: true)
                                self.connectContinuation = nil
                            }
                        //StopPos on regular connect
                        stopPositioning()
                        
                        
                    case .connectAndStartPositioning:
                        logger.log(type: .Info, "Connect and start positioning action")
                        // If the TX Char is found, then continue the cont to return true to the connect-function
                            if let cont = connectContinuation {
                                cont.resume(returning: true)
                                self.connectContinuation = nil
                            }
                        //StartPos on ConnectAndStartPositioning
                        
                        startPositioning()
                        
                        
                    case .none:
                        logger.log(type: .Warning, "Unkown connection action")
                    }
                    // Reset connection source
                    connectionSource = nil
  
                }
            }
        }
    }
    
    
    
    
    // Delegate - Called when char value has updated for defined char
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,error: Error?) {
        guard let data = characteristic.value else {
            // no data transmitted, handle if needed
            logger.log(type: .Warning, "No data received")
            return
        }
        
        // Get TX  value

        if characteristic.uuid == UUIDs.traceletTxChar {
            
            switch comState {
            case .WAITING_FOR_RESPONSE:
                storeInBuffer(data: BufferElement(message: data))
                ClassifyResponse(from: data)
            default:
                logger.log(type: .Warning, "Unknown message: \(data)")
            }
        }
    }
    
    
    
    // Delegate - Called when disconnected
    // Improve: Reset all states
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.log(type: .Info, "Disconnected tracelet: \(peripheral)")
        changeGeneralState(changeTo: .DISCONNECTED)
        
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
        
        
        allResponses = Strings.CONNECTION_FAILED
        logger.log(type: .Warning, "failed to connect")
        changeGeneralState(changeTo: .DISCONNECTED)
        
    }
    
}



public protocol ConnectionDelegate: AnyObject {
    func connectionDidSucceed()
    func connectionDidFail()
}


