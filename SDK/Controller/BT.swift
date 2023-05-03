//
//  BluetoothManager.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 09.03.23.
//

import Foundation
import CoreBluetooth




public class BT: NSObject, CBCentralManagerDelegate, ObservableObject {

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
    var connectedTracelet: CBPeripheral?
    
    // Buffer
    public var messageBuffer = [BufferElement]()
    
    var centralManager: CBCentralManager!
    
    let decoder = Decoder()
    var rxCharacteristic: CBCharacteristic?
    
    var scanDone = false

 
    
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
    }
    
    

    // MARK: - Scan()

    
    /// Initiate a scan for nearby tracelets
    /// - Parameters:
    ///   - timeout: timeout for the scan in seconds
    ///   - completion: returns a list of nearby tracelets as [CBPeripheral]
    public func scan(timeout: Double) async throws -> [CBPeripheral]?
    {
        scanDone = false
        
        guard generalState == STATE.DISCONNECTED else {
            
            print ("Can only start scan from DISCONNECTED")
            throw ConnectionErrors .badPassword
        }
        discoveredTracelets = []
      
        // Set State
       // changeScanState(changeTo: .SCANNING)
        
        //Set to true, to continously searching for devices. Helpful when device is out of range and getting closer (RSSI)
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: false)]
        
        //Initiate BT Scan
        centralManager.scanForPeripherals(withServices: nil, options: options)
   
            return discoveredTracelets
        
    }
    

    
    
    // MARK: - StopScan()
    
    public func stopScan() {
        centralManager.stopScan()
     //   changeScanState(changeTo: .IDLE)
    }
    
    // MARK: - Connect()
    
    enum ConnectionErrors: Error {
        case badUsername
        case badPassword
    }
    
    public func connect(device: CBPeripheral) async throws -> NewApi {
        
        guard generalState != STATE.CONNECTED else {
            print ("already connected")
           // return?
            throw ConnectionErrors.badPassword
        }
        centralManager.connect(device, options: nil)
        return NewApi(device: connectedTracelet)
    }
    
    
    
    // MARK: - Disconnect()
    
    public func disconnect() {
        if let tracelet = connectedTracelet {
            centralManager.cancelPeripheralConnection(tracelet)
        }
        
        connectedTracelet = nil
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
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        
       
        // Needs to be improved -> This should return a list of devices!
        // Connect either to Dummy(df2b) or "black Tracelet" (6ec6)
        
        if (peripheral.name?.contains("dwTag") ?? false) {
            discoveredTracelets.append(peripheral)
            //Set State
            traceletInRange = true
            
            // Discover UART Service
            scanDone = true
            
        }
        
        
        
    }
    
    
    
    // Delegate - Called when connection was successful
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

            // Set Delegate
            let deleg = NewApi(device: connectedTracelet)
            peripheral.delegate = deleg
        
            generalState = STATE.CONNECTED
            stopScan()
            deviceName = peripheral.name ?? "unkown"
            connectedTracelet = peripheral
            // Discover UART Service
            peripheral.discoverServices([UUIDs.traceletNordicUARTService])

    }
    
    
    
    // Delegate - Called when disconnected
    // Improve: Reset all states
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("diddisconnect")
       // changeGeneralState(changeTo: .DISCONNECTED)
        
        // #### Debug vars -> Only for testing ####
        traceletInRange = false
        deviceName = ""
      //  saveData()
        // #### Debug vars end ####
        
        
        
    }
    
    
    //Failsafe Delegate Functions
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        allResponses = Strings.CONNECTION_FAILED
        print("didfail")
     //   changeGeneralState(changeTo: .DISCONNECTED)
        
    }
    
}



