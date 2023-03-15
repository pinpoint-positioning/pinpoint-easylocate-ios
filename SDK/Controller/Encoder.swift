//
//  Encoder.swift
//  SDK
//
//  Created by Christoph Scherbeck on 15.03.23.
//

import Foundation


public class Encoder {
    
    public init() {
        
    }
    
   public  func encodeBytes(cmdByte:UInt8) -> Data {
        let startByte:UInt8 = 0x7F
        let endByte:UInt8 = 0x8F
        var byteArray = [UInt8]()
        byteArray.append(startByte)
        byteArray.append(cmdByte)
        // Handle XOR and Escape byte here!
        byteArray.insert(endByte, at: byteArray.count)
        return Data(byteArray)
    }
}
