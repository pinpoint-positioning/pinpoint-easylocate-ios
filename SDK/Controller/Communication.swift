//
//  Communication.swift
//  SDK
//
//  Created by Christoph Scherbeck on 24.04.24.
//

import Foundation
import SwiftUI
import CoreBluetooth



class Commnunication: ObservableObject {
    
    public static let shared = EasylocateAPI()
    let logger = Logging.shared
    @Published public var config = Config.shared
    var rxCharacteristic: CBCharacteristic?
    
    // MARK: - Send()
    /// Sents a command to a tracelet
    /// - Parameters:
    ///   - tracelet: tracelet object
    ///   - data: command content
    /// - Returns: bool
    private func send(to tracelet: CBPeripheral, data: [UInt8]) -> Bool {
        var success = false
        let encData = (config.uci ?  UCIEncoder().encodeBytes(Data(data)): Encoder.encodeByte(Data(data)))
        if let rxCharacteristic = rxCharacteristic {
            tracelet.writeValue(encData, for: rxCharacteristic,type: CBCharacteristicWriteType.withoutResponse)
            success = true
        }
        return success
    }
    
}
