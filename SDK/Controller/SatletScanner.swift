import Foundation
import CoreBluetooth

class SatletScanner: NSObject, ObservableObject {
    private let logger = Logging.shared
    
    private var centralManager: CBCentralManager
    private var discoveredSatlets: [CBPeripheral] = []
    private var configFrequency: [String: (channel: UInt8, preamble: UInt8, siteID: UInt16, count: Int)] = [:]
    private var completion: ((channel: UInt8, preamble: UInt8, siteID: UInt16)?) -> Void = { _ in }
    private var scanTimeout: TimeInterval = 3.0
    
    init(centralManager: CBCentralManager) {
        self.centralManager = centralManager
        super.init()
    }
    
    func scanForConfig(timeout: TimeInterval = 3.0, completion: @escaping ((channel: UInt8, preamble: UInt8, siteID: UInt16)?) -> Void) {
        guard centralManager.state == .poweredOn else {
            print("Central Manager is not powered on.")
            completion(nil)
            return
        }
        
        self.completion = completion
        self.scanTimeout = timeout
        self.configFrequency.removeAll()
        
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        print("Scanning started...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + scanTimeout) {
            self.stopScanning()
        }
    }
    
    private func stopScanning() {
        centralManager.stopScan()
        print("Scanning stopped.")
        
        // Log all collected configurations
        if configFrequency.isEmpty {
            print("No valid configurations were collected.")
            completion(nil)
            return
        }
        
        print("Collected configurations:")
        for (key, config) in configFrequency {
            logger.log(type: .info, "- Config \(key): Channel \(config.channel), Preamble \(config.preamble), SiteID \(config.siteID), Count \(config.count)")
        }
        
        // Determine the most common configuration
        let mostFrequentConfig = configFrequency.max { a, b in
            a.value.count < b.value.count
        }?.value
        
        if let config = mostFrequentConfig {
            let totalCount = configFrequency.values.reduce(0) { $0 + $1.count }
            let ratio = Double(config.count) / Double(totalCount) * 100
            logger.log(type: .info, """
                Most frequent configuration:
                - Channel: \(config.channel)
                - Preamble: \(config.preamble)
                - SiteID: \(String(format: "%04X", config.siteID))
                - Count: \(config.count)
                - Ratio: \(String(format: "%.2f", ratio))%
            """)
            completion((config.channel, config.preamble, config.siteID))
        } else {
            print("No valid configuration found.")
            completion(nil)
        }
        
        configFrequency.removeAll()
    }
    
    func processAdvertisementData(peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data else {
            print("No manufacturer data found in advertisement.")
            return
        }
        
        guard manufacturerData.count >= 11 else {
            print("Manufacturer data has insufficient length: \(manufacturerData.count) bytes")
            return
        }
        
        let payloadBytes = [UInt8](manufacturerData.dropFirst(5))
        guard payloadBytes.count >= 11 else {
            print("Payload data has insufficient length: \(payloadBytes.count) bytes")
            return
        }
        
        let advIdx = payloadBytes[0]
        
        if advIdx == ProtocolConstants.uwbConfigIndex {
            let uwbConfigDataBytes = [UInt8](payloadBytes.dropFirst(1))
            guard uwbConfigDataBytes.count >= 10 else {
                print("UWB Config data has insufficient length: \(uwbConfigDataBytes.count) bytes")
                return
            }
            
            let channel = uwbConfigDataBytes[0]
            let preamble = uwbConfigDataBytes[1]
            let siteID = UInt16(uwbConfigDataBytes[9]) | (UInt16(uwbConfigDataBytes[10]) << 8)
            
            let configKey = "\(channel)-\(preamble)-\(String(format: "%04X", siteID))"
            if let existingConfig = configFrequency[configKey] {
                configFrequency[configKey] = (channel, preamble, siteID, existingConfig.count + 1)
            } else {
                configFrequency[configKey] = (channel, preamble, siteID, 1)
            }
        }
        
        if !discoveredSatlets.contains(peripheral) {
            discoveredSatlets.append(peripheral)
            print("Discovered new satlet: \(peripheral.identifier)")
        }
    }
}
