//
//  Decoder.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation


class Decoder {
    
    init() {}
    lazy var byteArray = Data()
    lazy var decByteArray = [UInt8]()
    let logger = Logging.shared
    
    func validateMessage(of byteArray: Data) -> [UInt8] {
        //Reset array every run
        if !decByteArray.isEmpty {
            decByteArray.removeAll()
        }
        if byteArray.isEmpty {
            return [UInt8]()
        }
        // Check if array has start byte
        if byteArray[0] != ProtocolConstants.startByte {
            logger.log(type: .warning, "No Start Byte")
        }
        // Check if array has end byte
        // CAREFUL: Is forced unwrapped - TBD
        if byteArray.last! != ProtocolConstants.stopByte {
            logger.log(type: .warning, "No Stop Byte")
        }
        
        // Remove start byte
        var strippedByteArray = byteArray
        strippedByteArray.removeFirst()
        // Remove end byte
        strippedByteArray.removeLast()
        
        // Iterate through message and XOR the byte after the escape byte, if there is one
        var byteIt = strippedByteArray.makeIterator()
        while var byte = byteIt.next() {
            if byte == ProtocolConstants.escapeByte {
                byte = byteIt.next() ?? 0
                byte ^= UInt8(ProtocolConstants.xorByte)
            }
            decByteArray.append(byte)
        }
        
        // CRC Checksum - Release 11.2
        let checksumMsg = decByteArray.suffix(2).reduce(0) { result, value in
            let (sum, overflow) = result.addingReportingOverflow(Int(value))
            if overflow {
                logger.log(type: .warning, "Arithmetic Overflow")
            }
            return sum
        }
        
        let checksumCalc = Encoder.calcChecksum(Data(decByteArray.dropLast(2))).reduce(0) { result, value in
            let (sum, overflow) = result.addingReportingOverflow(Int(value))
            if overflow {
                logger.log(type: .warning, "Arithmetic Overflow")
            }
            return sum
        }
        
        guard checksumCalc == checksumMsg else {
            logger.log(type: .error, "Checksums are not matching!")
            return [0]
            // test to avoid crash
        }
        
        decByteArray.removeLast(2)
        return decByteArray
    }
}



class UCIDecoder {
    var decodingState: UCIDecoderState = .initial
    
    /// Checks if a list([byteList]) of [UCIProtocolConstants.packetHeaderSize] bytes qualifies as a header.
    func isHeader(byteList: [UInt8]) -> Bool {
        let mt = byteList[0] >> 5
        if ![UInt8(UCIProtocolConstants.msgTypeCtrlNtfy), UInt8(UCIProtocolConstants.msgTypeCtrlResp)].contains(UInt8(mt)) {
            
            return false
        }
        let gid = byteList[0] & 0xF
        if gid != UCIProtocolConstants.gidVendEasylocateLegacy {
            return false
        }
        let oid = byteList[1] & 0x3f
        if oid != UCIProtocolConstants.oidVendEasylocateLegacy {
            return false
        }
        return true
    }
    
    /// Decode incoming serial data and extract pinpoint messages
    /// Usage advices:
    /// - use this only in a Device API object when you expect a certain message
    func decode(data: Data) -> [UInt8] {
        var pbf = 0
        var currentPayloadLength = 0
        var payloadLength = 0
        var decodedByteBuffer = [UInt8]()
        var currentHeader = [UInt8]()
        
      //  print("Received raw data package: \(data)")
        
        // Convert data to an array of UInt8
        let dataUInt8 = [UInt8](data)
        
        // take each byte chunk and decode
        for byte in dataUInt8 {
            switch decodingState {
                // header is not yet complete
            case .initial:
                currentHeader.append(byte)
                // check if the header is complete
                if currentHeader.count == UCIProtocolConstants.packetHeaderSize {
                    let validHeader = isHeader(byteList: currentHeader)
                    if validHeader {
                        pbf = Int(currentHeader[0] >> 4 & 0x1)
                        payloadLength = Int(currentHeader[3])
                        currentPayloadLength = 0
                        decodingState = .running
                    } else {
                        print("\(currentHeader) is not a valid header! Received bytes of an incomplete message.")
                        currentHeader.removeAll()
                        decodedByteBuffer.removeAll()
                    }
                }
                // header is complete, receiving payload
            case .running:
                currentPayloadLength += 1
                decodedByteBuffer.append(byte)
                // check if the payload is complete
                if payloadLength == currentPayloadLength {
                    decodingState = .initial
                    if pbf == 0 { // the last packet of the message was received
           //             print("Decoded data package: \(decodedByteBuffer)")
                        return decodedByteBuffer // Return decodedByteBuffer
                    }
                }
            }
        }
        
        return decodedByteBuffer
    }
}




struct SerialDataPackageError: Error {
    var localizedDescription: String
}

class SerialDataPackage {
    var timestamp: Int
    var data: [UInt8]
    
    init(timestamp: Int, data: [UInt8]) {
        self.timestamp = timestamp
        self.data = data
    }
    
    /// Get command code (message type) from received data.
    func getCommandCode() throws -> Int {
        guard !data.isEmpty else {
            throw SerialDataPackageError(localizedDescription: "Cannot get command code from received data package.")
        }
        return Int(data[0])
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

