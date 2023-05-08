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
    let logger = Logger()
    
    
    // Properties
    @Published public var allResponses = String()
    
    // Published vars
    // ### Debug only ###
    @Published public var traceletInRange = false
    @Published public var deviceName = ""
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
    
    public func stopScan() {
        centralManager.stopScan()
        changeScanState(changeTo: .IDLE)
        logger.log(type: .Info, "Scan stopped")
    }
    
    // MARK: - Connect()
    
    public func connect(device: CBPeripheral) {
        
        logger.log(type: .Info, "Start connection")
        
        guard generalState != STATE.CONNECTED else {
            logger.log(type: .Warning, "Already connected")
            return
        }
        centralManager.connect(device, options: nil)
    }
    
    // MARK: - Disconnect()
    
    public func disconnect() {
        logger.log(type: .Info, "start disconnecting")
        if let tracelet = connectedTracelet {
            centralManager.cancelPeripheralConnection(tracelet)
        }
        
        connectedTracelet = nil
    }
    
    
    // MARK: - Send()
    // Send write command to BT device
    func send(to tracelet: CBPeripheral, data: Data) {
        guard generalState == STATE.CONNECTED else {
            logger.log(type: .Error, "State must be CONNECTED to use send()")
            return
        }
        if let rxCharacteristic = rxCharacteristic {
            tracelet.writeValue(data as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
            
        }
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
    
    public func showMe(tracelet: CBPeripheral) {
        let cmdByte = ProtocolConstants.cmdCodeShowMe
        let data = Encoder.encodeByte(cmdByte)
        send(to: tracelet, data: data)
        logger.log(type: .Info, "ShowMe")
    }
    
    // MARK: - startPositioning()
    
    public func startPositioning() {
        
        let cmdByte = ProtocolConstants.cmdCodeStartPositioning
        let data = Encoder.encodeByte(cmdByte)
        if let tracelet = connectedTracelet {
            send(to: tracelet, data: data)
            logger.log(type: .Info, tracelet.name ?? "unknown tracelet")
        }
        
        
    }
    
    // MARK: - stopPositioning()
    
    public func stopPositioning() {
        
        let cmdByte = ProtocolConstants.cmdCodeStopPositioning
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            send(to: tracelet, data: data)
            logger.log(type: .Info, tracelet.name ?? "unknown tracelet")
        }
    }
    
    
    
    
    /// Sets a positioning interval
    /// - Parameter interval: interval in n x 250ms
    ///
    public func setPositioningInterval(interval:Int8) {
        let Uint8Interval: UInt8 = UInt8(bitPattern: interval)
        let dataArray:[UInt8] = [ProtocolConstants.cmdCodeSetPositioningInterval, Uint8Interval]
        
        if let tracelet = connectedTracelet {
            send(to: tracelet, data: Encoder.encodeBytes(dataArray))
            logger.log(type: .Info, "Interval set to:  \(interval)")
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
    //removed: completion: @escaping ((TL_StatusResponse) -> Void)
    public func requestStatus() {
        logger.log(type: .Info, "Status requested")
        
        let cmdByte = ProtocolConstants.cmdCodeGetStatus
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            sendWithResponse(to: tracelet, data: data)
        }
        
        changeComState(changeTo: .WAITING_FOR_RESPONSE)
        
        
        //        freezeBuffer { buffer in
        //            for message in buffer {
        //                print(self.getCmdByte(from: message.message))
        //                if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodeStatus)  {
        //                    completion(TraceletResponse().GetStatusResponse(from: message.message))
        //                    // If there are two status messages in the buffer, only the first will be returned.
        //                    // Not sure if this is fine
        //                    print("found status:  \(TraceletResponse().GetStatusResponse(from: message.message))")
        //                    self.messageBuffer.removeAll()
        //                }
        //            }
        //        }
    }
    
    
    
    
    //     public func getStatusString(completion: @escaping ((String) -> Void)) {
    //
    //        requestStatus { status in
    //            let statusString =  """
    //                                SiteID: \(status.siteIDe)\n \
    //                                Battery Level: \(status.batteryLevel)\n \
    //                                PosX: \(status.posX)
    //                                """
    //            print("statusString")
    //            completion(statusString)
    //        }
    //    }
    
    // MARK: - getPosition()
    
    //removed:  completion: @escaping ((TL_PositionResponse) -> Void)
    
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
        
        //        freezeBuffer { buffer in
        //            for message in buffer {
        //                print(self.getCmdByte(from: message.message))
        //                if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodePosition)  {
        //                    completion(TraceletResponse().GetPositionResponse(from: message.message))
        //                    // If there are two status messages in the buffer, only the first will be returned.
        //                    // Not sure if this is fine
        //                    print("Position found:  \(TraceletResponse().GetPositionResponse(from: message.message))")
        //                    self.messageBuffer.removeAll()
        //                }
        //            }
        //        }
    }
    
    
    
    // Use RSSI to connect only when close ( > -50 db).
    // Sometimes RSSI returns max value 127. Excluded it for now.
    // Maybe include PowerTX Level- -> TBD
    
    public func inProximity(_ RSSI: NSNumber) -> Bool {
        if (RSSI.intValue > -50 && RSSI != 127){
            return true
        } else {
            return false
        }
    }
    
    
    
    /// Get the WGS84 Reference
    /// - Returns: Wgs84Position
    public func getWgs84Position() async -> Double {
        
        let wgsRef = Wgs84Reference().convertToWgs84(position: localPosition)
        
        return wgsRef.lat
    }
    
    
    
    // MARK: - getVersion()
    // removed completion: @escaping  ((String) -> Void)
    
    public func requestVersion() {
        logger.log(type: .Info, "Version requested")
        
        guard generalState == STATE.CONNECTED else {
            logger.log(type: .Error, "State is \(generalState)")
            return
        }
        
        let cmdByte = ProtocolConstants.cmdCodeGetVersion
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            sendWithResponse(to: tracelet, data: data)
        }
        
        changeComState(changeTo: .WAITING_FOR_RESPONSE)
        
        //        freezeBuffer { buffer in
        //            for message in buffer {
        //                print(self.getCmdByte(from: message.message))
        //                if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodeVersion)  {
        //                    completion(TraceletResponse().getVersionResponse(from: message.message))
        //                    // If there are two status messages in the buffer, only the first will be returned.
        //                    // Not sure if this is fine
        //                    print("found status:  \(TraceletResponse().GetStatusResponse(from: message.message))")
        //                    self.messageBuffer.removeAll()
        //                }
        //            }
        //        }
    }
    
    
    
    
    // MARK: - Buffer handling
    
    public func storeInBuffer(data:BufferElement) {
        
        if (messageBuffer.count > 10)
        {
            messageBuffer.removeFirst()
        }
        messageBuffer.append(data)
        
        
    }
    
    
    public func readFromBuffer() -> BufferElement {
        // TBD -> Forced unwrap!
        let firstElementInBuffer = messageBuffer.first!
        messageBuffer.removeFirst()
        return firstElementInBuffer
    }
    
    
    // Delay until buffer is frozen when requested
    public func freezeBuffer(completion: @escaping (([BufferElement]) -> Void)) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let buffer = self.messageBuffer
            completion(buffer)
        }
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
    
    var location = AsyncLocationStream.shared
    public func ClassifyResponse (from byteArray: Data)
    
    {
        let valByteArray = Decoder().ValidateMessage(of: byteArray)
        
        if (valByteArray[0] == ProtocolConstants.cmdCodePosition)
        {
            location.continuation?.yield(TraceletResponse().GetPositionResponse(from: byteArray))
            localPosition = TraceletResponse().GetPositionResponse(from: byteArray)
            allResponses = "X: \(localPosition.xCoord) Y: \(localPosition.yCoord) Z: \(localPosition.zCoord) \n"
            
            // Debug - Log to File"!!!!!!
            positionLog.append(allResponses)
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
        
        if (peripheral.name?.contains("dwTag") ?? false) {
            if discoveredTracelets.contains(peripheral)
            {
                print ("already in list")
            } else {
                logger.log(type: .Info, "Tracelet discovered")
                discoveredTracelets.append(peripheral)
            }
            
            //Set State
            traceletInRange = true
            
        }
        
    }
    
    
    
    // Delegate - Called when connection was successful
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        // Set State
        generalState = STATE.CONNECTED
        stopScan()
        
        logger.log(type: .Info, "Connected to: \(String(describing: peripheral.name))")
        
        deviceName = peripheral.name ?? "unkown"
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
                        peripheral.setNotifyValue(true, for: characteristic)
                        changeComState(changeTo: .WAITING_FOR_RESPONSE)
                        
                        
                    }
                }
                else if characteristic.uuid == UUIDs.traceletRxChar {
                    logger.log(type: .Info, "Discovered characteristic: \(characteristic.uuid)")
                    stopPositioning()
                    rxCharacteristic = characteristic
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
        
        // #### Debug vars -> Only for testing ####
        traceletInRange = false
        deviceName = ""
        // #### Debug vars end ####
        
        
        
    }
    
    
    //Failsafe Delegate Functions
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        allResponses = Strings.CONNECTION_FAILED
        logger.log(type: .Warning, "failed to connect")
        changeGeneralState(changeTo: .DISCONNECTED)
        
    }
    
}



