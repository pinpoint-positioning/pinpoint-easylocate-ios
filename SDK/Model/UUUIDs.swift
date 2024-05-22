//
//  BluetoothPeripheral.swift
//  minimalBT
//
//  Created by Christoph Scherbeck on 07.03.23.
//

import Foundation
import UIKit
import CoreBluetooth


public class UUIDs: NSObject {
    

    //Identifier Tracelets
    public static let traceletDummyUUID              = UUID(uuidString: "D5609BE9-8D39-AA51-57C3-29ADBDE995A0")
    public static let traceletIdentifierUUID         = UUID(uuidString: "C7D674B6-C262-67B6-946F-18CCF376E040")
    
    //Services
    public static let traceletBatteryService         = CBUUID.init(string: "0000180F-0000-1000-8000-00805F9B34FB")
    public static let traceletNordicUARTService      = CBUUID.init(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    //Characteristics
    public static let traceletRxChar                 = CBUUID.init(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    public static let traceletTxChar                 = CBUUID.init(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    public static let traceletBatteryLevelChar       = CBUUID.init(string: "00002A19-0000-1000-8000-00805F9B34FB")
    
    
}
