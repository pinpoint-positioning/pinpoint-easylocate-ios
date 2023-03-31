//
//  BluetoothManager.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 09.03.23.
//

import Foundation
import CoreBluetooth


public class Commands: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    
    
    
    // Properties
    @Published public var textOutput = String()
    
    //States -- Really false in init?
    @Published public var isConnected = false
    @Published public var isScanning = false
    @Published public var powerOn = false
    @Published public var traceletInRange = false
    @Published public var serviceFound = false
    @Published public var recievingData = false
    @Published public var deviceName = ""
    @Published public var subscribedToNotifiy = false
    @Published public var bleState = BLE_State.UNKNOWN
    @Published public var localPosition = TL_PositionResponse()
    @Published public var status = TL_StatusResponse()
    public var positionLog = String()
    
    // Buffer
    public var messageBuffer = [BufferElement]()
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var connectedTracelet: CBPeripheral? = nil
    let decoder = Decoder()
    var rxCharacteristic: CBCharacteristic? = nil
    var isRequestingStatus = false
    
    // Variables for Scan-Timeout-Timer
    var timer: Timer?
    var runCount = 0
    var timeout = 30
    @Published public var remainingTimer = 0
    
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
        
    }
    
    
    
    
    // MARK: - Scan()
    // TBD -> Return list of devices
    public func scan()
    {
        // Set State
        bleState = BLE_State.INIT
        isScanning = true
        //Set to true, to continously searching for devices. Helpful when device is out of range and getting closer (RSSI)
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)]
        
        //Initiate BT Scan
        centralManager.scanForPeripherals(withServices: nil, options: options)
        
        
        //Start Timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        
    }
    
    
    
    // MARK: - StopScan()
    
    public func stopScan() {
        
        centralManager.stopScan()
        isScanning = false
    }
    
    // MARK: - Connect()
    
    public func connect() {
        
        // Make sure the device the should be connected is the identified tracelet
        if let foundTracelet = connectedTracelet{
            centralManager.connect(foundTracelet, options: nil)
        }
    }
    
    // MARK: - Disconnect()
    
    public func disconnect() {
        centralManager.cancelPeripheralConnection(connectedTracelet!)
        peripheral = nil
        
        
        
        
    }
    
    enum CommError: Error
    {
        case sendError
    }
    
    
    // MARK: - Send()
    // Send write command to BT device
    // TBD -> Only possible when connected
    public func send(data: Data) {
        
        
        if let rxCharacteristic = rxCharacteristic {
            connectedTracelet!.writeValue(data as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    
    
    // MARK: - ShowMe()
    
    public func showMe() {
        
        if let rxCharacteristic = rxCharacteristic {
            let cmdShowMe = Encoder.encodeByte(ProtocolConstants.cmdCodeShowMe)
            connectedTracelet!.writeValue(cmdShowMe as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    // MARK: - startPositioning()
    
    public func startPositioning() {
        
        if let rxCharacteristic = rxCharacteristic {
            let cmdShowMe = Encoder.encodeByte(ProtocolConstants.cmdCodeStartPositioning)
            connectedTracelet!.writeValue(cmdShowMe as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    // MARK: - stopPositioning()
    
    public func stopPositioning() {
        
        if let rxCharacteristic = rxCharacteristic {
            let cmdShowMe = Encoder.encodeByte(ProtocolConstants.cmdCodeStopPositioning)
            connectedTracelet!.writeValue(cmdShowMe as Data, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    // MARK: - getStatus()
    
    public func getStatus(completion: @escaping ((TL_StatusResponse) -> Void)) {

        let cmdByte = ProtocolConstants.cmdCodeGetStatus
        let data = Encoder.encodeByte(cmdByte)
        send(data: data)
        

        freezeBuffer { buffer in
            for message in buffer {
                print(self.getCmdByte(from: message.message))
                if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodeStatus)  {
                    completion(TraceletResponse().GetStatusResponse(from: message.message))
                    // If there are two status messages in the buffer, only the first will be returned.
                    // Not sure if this is fine
                    print("found status:  \(TraceletResponse().GetStatusResponse(from: message.message))")
                    self.messageBuffer.removeAll()
                }
            }
        }
    }
    

 
    // MARK: - getStatusString()
    
    public func getStatusString(completion: @escaping ((String) -> Void)) {

        getStatus { status in
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

        textOutput = "X: \(localPosition.xCoord) Y: \(localPosition.yCoord) Z: \(localPosition.zCoord) site: \(localPosition.siteID)\n\n"
        
        return localPosition
        
    }
    
    
    
    
    // MARK: - getOneTimePosition()
    
    public func getOneTimePostion(completion: @escaping ((TL_PositionResponse) -> Void)) {

        let cmdByte = ProtocolConstants.cmdCodeStartPositioning
        let data = Encoder.encodeByte(cmdByte)
        send(data: data)
        
        freezeBuffer { buffer in
            for message in buffer {
                print(self.getCmdByte(from: message.message))
                if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodePosition)  {
                    completion(TraceletResponse().GetPositionResponse(from: message.message))
                    // If there are two status messages in the buffer, only the first will be returned.
                    // Not sure if this is fine
                    print("Position found:  \(TraceletResponse().GetPositionResponse(from: message.message))")
                    self.messageBuffer.removeAll()
                }
            }
        }
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
    
    
    
    
    // MARK: - getVersion()
    
    public func getVersion(completion: @escaping  ((String) -> Void)) {
        
        let cmdByte = ProtocolConstants.cmdCodeGetVersion
        let data = Encoder.encodeByte(cmdByte)
        send(data: data)
        
        freezeBuffer { buffer in
            for message in buffer {
                print(self.getCmdByte(from: message.message))
                if (self.getCmdByte(from: message.message) == ProtocolConstants.cmdCodeVersion)  {
                    completion(TraceletResponse().getVersionResponse(from: message.message))
                    // If there are two status messages in the buffer, only the first will be returned.
                    // Not sure if this is fine
                    print("found status:  \(TraceletResponse().GetStatusResponse(from: message.message))")
                    self.messageBuffer.removeAll()
                }
            }
        }
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
            textOutput = "save error"
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
    
    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // ###################### DEBUG END #########################
    
    
    // MARK: - ClassifyResponse()
    
    public func ClassifyResponse (from byteArray: Data) -> Response?
    
    {
        let valByteArray = Decoder().ValidateMessage(of: byteArray)
        
        if (valByteArray[0] == ProtocolConstants.cmdCodePosition)
        {
            localPosition = TraceletResponse().GetPositionResponse(from: byteArray)
            
            
            textOutput = "X: \(localPosition.xCoord) Y: \(localPosition.yCoord) Z: \(localPosition.zCoord) siteID: \(localPosition.siteID) time: \(Date()) \n\n"
            
            // Log to File"!!!!!!
            positionLog.append(textOutput)
            return localPosition as? Response
        }
        
        if (valByteArray[0] == ProtocolConstants.cmdCodeStatus)
        {
            status =  TraceletResponse().GetStatusResponse(from: byteArray)
            textOutput = "role: \(status.role) panID: \(status.panID) site: \(status.siteIDe)\n\n"
            return status as? Response
        } else {
            return nil
        }
        
    }
    
    
    public func getCmdByte(from data: Data) -> UInt8 {
        
        let valMesssage = Decoder().ValidateMessage(of: data)
        return valMesssage[0]
        
    }

    
    // Scan-Timeout Timer settings
    
    @objc func fireTimer() {
        runCount += 1
        remainingTimer = timeout - runCount
        
        //1 Run = 1 sec.  30 runs = 30 secs
        if (runCount == timeout || !isScanning) {
            timer?.invalidate()
            remainingTimer = timeout
            stopScan()
            if (!isScanning) {runCount = 0}
        }
    }
    
    
    
    
    //MARK: - Delegate Functions
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            powerOn = true
            bleState = BLE_State.BT_OK
            break
        case .poweredOff:
            powerOn = false
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
        
        
        
        
        // Needs to be improved!!
        // Connect either to Dummy(df2b) or "black Tracelet" (6ec6)
        if (peripheral.name?.contains("df2b") ?? false && inProximity(RSSI) || peripheral.name?.contains("6ec6") ?? false && inProximity(RSSI))
        {
            
            //Set State
            traceletInRange = true
            bleState = BLE_State.APPROACHED
            
            // / If tracelet is found,save object in "peripheral"
            connectedTracelet = peripheral
            
            //Stop Scan
            centralManager.stopScan()
            isScanning = false
            
            //Attempt to connect
            connect()
            
        }
    }
    
    
    
    // Delegate - Called when connection was successful
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == connectedTracelet {
            // Set State
            isConnected = true
            bleState = BLE_State.CONNECTED
            
            deviceName = peripheral.name ?? "unkown"
            
            // Discover UART Service
            peripheral.discoverServices([UUIDs.traceletNordicUARTService])
            
            
        }
    }
    
    
    // Delegate - Called when services are discovered
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                
                // Discover UART Service
                if service.uuid == UUIDs.traceletNordicUARTService{
                    //Set State
                    serviceFound = true
                    
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
                
                // Subscribe to notify of charateristic
                if characteristic.uuid == UUIDs.traceletTxChar {
                    
                    if characteristic.properties.contains(.notify) {
                        peripheral.setNotifyValue(true, for: characteristic)
                        subscribedToNotifiy = true
                        bleState = BLE_State.GOT_CHARACTERISTICS
                    }else{
                        print("Characteristic has no notify property")
                    }
                }
                else if characteristic.uuid == UUIDs.traceletRxChar {
                    print ("rxfound")
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
            // Set State
            recievingData = true
            
            storeInBuffer(data: BufferElement(message: data))
            
            
            // Filter Message
            ClassifyResponse(from: data) 

            
        }
    }
    
    
    
    // Delegate - Called when disconnected
    // Improve: Reset all states
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        traceletInRange = false
        serviceFound = false
        recievingData = false
        subscribedToNotifiy = false
        deviceName = ""
        saveData()
    }
    
    
    //Failsafe Delegate Functions
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        textOutput = Strings.CONNECTION_FAILED
    }
    
}



