//
//  Decoder.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation


public class Decoder {
    
    public init() {}
    
    lazy var byteArray = Data()
    lazy var decByteArray = [UInt8]()
    
    public func ValidateMessage(of byteArray:Data ) -> [UInt8]   {
        
        let bA = [UInt8](byteArray)
        //Reset array every run
        if (!decByteArray.isEmpty)
        {
            decByteArray.removeAll()
        }
        
        // Check if array has start byte
        if (byteArray[0] != ProtocolConstants.startByte)
        {
            print("No Start Byte")
        }
        //Check if array has end byte
        //CAREFUL: Is forced unwrapped - TBD
        if (byteArray.last! != ProtocolConstants.stopByte)
        {
            print ("No Stop Byte")
        }
        
        //Remove start byte
        var strippedByteArray = byteArray
        strippedByteArray.remove(at: 0)
        //Remove Ende byte
        strippedByteArray.removeLast()
        
        // Iterate trough message and XOR the byte after the escape byte, if there is one
        var byteIt = strippedByteArray.makeIterator()
        while var byte = byteIt.next(){
            if (byte == ProtocolConstants.escapeByte) {
                byte = byteIt.next()!;
                byte = byte ^ UInt8(ProtocolConstants.xorByte);
            }
            decByteArray.append(byte);
        }
        
        return decByteArray
        
    }
}













//MARK: - Extensions


// Extension to decode hex of type DATA
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

