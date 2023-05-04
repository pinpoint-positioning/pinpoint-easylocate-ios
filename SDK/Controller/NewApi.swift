//
//  BluetoothManager.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 09.03.23.
//

import Foundation
import CoreBluetooth



public class NewApi: NSObject, ObservableObject, CBPeripheralDelegate {

    
    let device:CBPeripheral?
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
   
    init(device:CBPeripheral?) {
        self.device = device
    }
    
    // MARK: - Scan()

    
    /// Initiate a scan for nearby tracelets
    /// - Parameters:
    ///   - timeout: timeout for the scan in seconds
    ///   - completion: returns a list of nearby tracelets as [CBPeripheral]
    public func scan(timeout: Double, completion: @escaping (([CBPeripheral]) -> Void))
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
            completion(self.discoveredTracelets)
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
    
    public func showMe() {
        let cmdByte = ProtocolConstants.cmdCodeShowMe
        let data = Encoder.encodeByte(cmdByte)
        if let connectedTracelet = connectedTracelet {
            send(to: connectedTracelet, data: data)
        }
       
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
    //removed: completion: @escaping ((TL_StatusResponse) -> Void)
    public func requestStatus() {
        
        let cmdByte = ProtocolConstants.cmdCodeGetStatus
        let data = Encoder.encodeByte(cmdByte)
        
        if let tracelet = connectedTracelet {
            sendWithResponse(to: tracelet, data: data)
        }
        
        changeComState(changeTo: .WAITING_FOR_RESPONSE)

    }


    // MARK: - getPosition()
    
    //removed:  completion: @escaping ((TL_PositionResponse) -> Void)
    
    public func requestPosition() {
        guard generalState == STATE.CONNECTED else {
            print ("State must be CONNECTED to send command")
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
 
    
}



