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
    
    //Services
    public static let traceletNordicUARTService      = CBUUID.init(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    
    //Characteristics
    public static let traceletRxChar                 = CBUUID.init(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    public static let traceletTxChar                 = CBUUID.init(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
  
}
