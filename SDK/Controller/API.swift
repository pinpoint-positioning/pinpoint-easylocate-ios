//
//  BluetoothManager.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 09.03.23.
//

import Foundation
import CoreBluetooth



// ToDo:

// 1. Scan() should return a list of devices
// Send StopPos after connect

// 2. States with Rebecca
// 3. Buffer logic is not good. (Messages are lost)
// 4. Clarify method usage
// 5. How to return API-Object, when connected?
// Exceptions?
// Logging

// Rebecca Buffer
// Local position



public class API: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    
    
    
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
    @Published public var discoveredTracelets = [CBPeripheral]()
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
        
    }
    
    
    
    
    // MARK: - Scan()
    // TBD -> Return list of compatible devices
    public func scan(timeout: Double)
    {
        guard generalState == STATE.DISCONNECTED else {
            
            print ("Can only start scan from DISCONNECTED")
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
        }
    }
    
    func getCharacteristicsForDiscoveredTracelets(tracelets:[CBPeripheral]) {
        for device in tracelets {
            device.discoverServices([UUIDs.traceletNordicUARTService])
        }
    }
    
    
    // MARK: - StopScan()
    
    public func stopScan() {
        centralManager.stopScan()
        changeScanState(changeTo: .IDLE)
    }
    
    // MARK: - Connect()
    
    public func connect(device: CBPeripheral) {
        
        guard generalState != STATE.CONNECTED else {
            print ("already connected")
            return
        }
        centralManager.connect(device, options: nil)
    }
    
    // MARK: - Disconnect()
    
    public func disconnect() {
        if let tracelet = connectedTracelet {
            centralManager.cancelPeripheralConnection(tracelet)
        }
        
        connectedTracelet = nil
    }
    
    
    // MARK: - Send()
    // Send write command to BT device
     func send(to tracelet: CBPeripheral, data: Data) {
        
        if let rxCharacteristic = rxCharacteristic {
            tracelet.writeValue(data as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    
    
    
     func sendWithResponse(to tracelet: CBPeripheral, data: Data) {
        guard generalState == STATE.CONNECTED else {
            print ("State must be CONNECTED to send command")
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
    }
    
    // MARK: - startPositioning()
    
    public func startPositioning() {
        
        let cmdByte = ProtocolConstants.cmdCodeStartPositioning
        let data = Encoder.encodeByte(cmdByte)
        if let tracelet = connectedTracelet {
            send(to: tracelet, data: data)
        }
        
    }
    
    // MARK: - stopPositioning()
    
    public func stopPositioning() {
        
        let cmdByte = ProtocolConstants.cmdCodeStopPositioning
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            send(to: tracelet, data: data)
        }
    }
    
    
    
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
    
    public func requestStatus(completion: @escaping ((TL_StatusResponse) -> Void)) {
        
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
    
    
    
    // MARK: - getStatusString()
    
    public func getStatusString(completion: @escaping ((String) -> Void)) {
        
        requestStatus { status in
            let statusString =  """
                                SiteID: \(status.siteIDe)\n \
                                Battery Level: \(status.batteryLevel)\n \
                                PosX: \(status.posX)
                                """
            print("statusString")
            completion(statusString)
        }
    }
    
    
    
    // MARK: - GetPosition()
    
    public func getLocalPosition(data:Data) -> TL_PositionResponse {
        
        let localPosition = TraceletResponse().GetPositionResponse(from: data)
        allResponses = "X: \(localPosition.xCoord) Y: \(localPosition.yCoord) Z: \(localPosition.zCoord) site: \(localPosition.siteID)\n\n"
        return localPosition
        
    }
    
    
    
    
    // MARK: - RSSI()
    
    
    // Use RSSI to connect only when close ( > -50 db).
    // Sometimes RSSI returns max value 127. Excluded it for now.
    // Maybe include PowerTX Level- -> TBD
    
     func inProximity(_ RSSI: NSNumber) -> Bool {
        if (RSSI.intValue > -50 && RSSI != 127){
            return true
        } else {
            return false
        }
    }
    
    
    
    
    // MARK: - getVersion()
    
    public func requestVersion(completion: @escaping  ((String) -> Void)) {
        guard generalState == STATE.CONNECTED else {
            print ("State must be CONNECTED to send command")
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
        print(messageBuffer)
        
    }
    
    
    public func readFromBuffer() -> BufferElement {
        // TBD -> Forced unwrap!
        let firstElementInBuffer = messageBuffer.first!
        messageBuffer.removeFirst()
        return firstElementInBuffer
    }
    
    
    // Delay until buffer is frozen when requested
    func freezeBuffer(completion: @escaping (([BufferElement]) -> Void)) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let buffer = self.messageBuffer
            print("buffer frozen: \(buffer)")
            completion(buffer)
        }
    }
    
    
    // MARK: - Debug - Save Logs
    // ###################### DEBUG #########################
    // Only for Debug -> Save logged data to file
    func saveData() {
        
        let filename = getDocumentsDirectory().appendingPathComponent("positionLog\(Date()).txt")
        
        do {
            
            try positionLog.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
            print("saved: \(positionLog)")
            
        } catch {
            allResponses = "save error"
            // failed to write file
        }
    }
    
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // ###################### DEBUG END #########################
    
    
    // MARK: - ClassifyResponse()
    
    public func ClassifyResponse (from byteArray: Data)
    
    {
        let valByteArray = Decoder().ValidateMessage(of: byteArray)
        
        if (valByteArray[0] == ProtocolConstants.cmdCodePosition)
        {
            localPosition = TraceletResponse().GetPositionResponse(from: byteArray)
            allResponses = "X: \(localPosition.xCoord) Y: \(localPosition.yCoord) Z: \(localPosition.zCoord) \n\n"
            
            // Debug - Log to File"!!!!!!
            positionLog.append(allResponses)
        }
        
        if (valByteArray[0] == ProtocolConstants.cmdCodeStatus)
        {
            status =  TraceletResponse().GetStatusResponse(from: byteArray)
            allResponses = "role: \(status.role) panID: \(status.panID) site: \(status.siteIDe)\n\n"
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
            break
        case .poweredOff:
            bleState = BLE_State.BT_NA
            break
        case .resetting:
            break
        case .unauthorized:
            break
        case .unsupported:
            break
        case .unknown:
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
            discoveredTracelets.append(peripheral)
            //Set State
            traceletInRange = true
            // Discover UART Service
            
        }

    }
    
    
    
    // Delegate - Called when connection was successful
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

            // Set State
            generalState = STATE.CONNECTED
            stopScan()
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
                    
                }
                
                peripheral.discoverCharacteristics([UUIDs.traceletRxChar,UUIDs.traceletTxChar], for: service)
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
                    
                    if characteristic.properties.contains(.notify) {
                        peripheral.setNotifyValue(true, for: characteristic)
                        changeComState(changeTo: .WAITING_FOR_RESPONSE)
                        print ("notify set")
                    }
                }
                else if characteristic.uuid == UUIDs.traceletRxChar {
                    print ("rxfound")
                   // stopPositioning()
                    rxCharacteristic = characteristic
                }
            }
        }
    }
    

    
    
    // Delegate - Called when char value has updated for defined char
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,error: Error?) {
        
        guard let data = characteristic.value else {
            // no data transmitted, handle if needed
            print("no data")
            return
        }
        
        // Get TX  value
        if characteristic.uuid == UUIDs.traceletTxChar {
            
            switch comState {
            case .WAITING_FOR_RESPONSE:
                ClassifyResponse(from: data)
            default:
                print ("unkown message")
            }
        }
    }
    
    
    
    // Delegate - Called when disconnected
    // Improve: Reset all states
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("diddisconnect")
        changeGeneralState(changeTo: .DISCONNECTED)
        
        // #### Debug vars -> Only for testing ####
        traceletInRange = false
        deviceName = ""
        saveData()
        // #### Debug vars end ####
        
        
        
    }
    
    
    //Failsafe Delegate Functions
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        allResponses = Strings.CONNECTION_FAILED
        print("didfail")
        changeGeneralState(changeTo: .DISCONNECTED)
        
    }
    
}



