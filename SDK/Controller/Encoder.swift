//
//  Encoder.swift
//  SDK
//
//  Created by Christoph Scherbeck on 15.03.23.
//

import Foundation

 class Encoder {
    
     // Encode single byte
     // CRC Checksum included
     
     static func encodeByte(_ data: Data) -> Data {
         var encBytes = [UInt8]()

         for byte in data {
             if byte == ProtocolConstants.startByte ||
                 byte == ProtocolConstants.stopByte ||
                 byte == ProtocolConstants.escapeByte {
                 encBytes.append(ProtocolConstants.escapeByte)
                 encBytes.append(ProtocolConstants.xorByte ^ byte)
             } else {
                 encBytes.append(byte)
             }
         }

         let checksum = calcChecksum(data)
         encBytes.append(contentsOf: checksum)
         encBytes.insert(ProtocolConstants.startByte, at: 0)
         encBytes.append(ProtocolConstants.stopByte)
         return Data(encBytes)
     }

   
 
     // Encode byte array

   static func encodeBytes(_ bytes: [UInt8]) -> Data {
 
    var bytesAsHex = ""
    bytes.forEach { bytesAsHex.append(String(format: "%02hhx", $0)) }
    print("Data package to encode: \(bytesAsHex)")

    if bytes.isEmpty {
      return Data()
    }

    var encBytes = [UInt8]()
    encBytes.append(ProtocolConstants.startByte)
    bytes.forEach {
      if $0 == ProtocolConstants.startByte ||
          $0 == ProtocolConstants.stopByte ||
          $0 == ProtocolConstants.escapeByte {
        encBytes.append(ProtocolConstants.escapeByte)
        encBytes.append(ProtocolConstants.xorByte ^ $0)
      } else {
        encBytes.append($0)
      }
    }
       
    let checksum = calcChecksum(Data(bytes))
    
    encBytes.append(contentsOf: checksum)
    encBytes.append(ProtocolConstants.stopByte)

    bytesAsHex = ""
    encBytes.forEach { bytesAsHex.append(String(format: "%02hhx", $0)) }
    print("Encoded data package: \(bytesAsHex)")

    let encodedData = Data(encBytes)
       print ("sent")
       print (encodedData)
    return encodedData
  }
     

     static func calcChecksum(_ data: Data) -> Data {
         var sum: UInt16 = 0
         for byte in data {
             sum += UInt16(byte)
         }
         let checksumBytes = withUnsafeBytes(of: sum.littleEndian, Array.init)
         return Data(checksumBytes)
     }

     
}


// Valid vom Firmware 11.4

class UCIEncoder {
    let logger = Logging()
    
    func encodeBytes(_ data: Data) -> Data {
        var encBytes = [UInt8]()
        logger.log(type: .info, "Data package to encode:  \(data.hexEncodedString())")
        
        if data.isEmpty {
            return Data()
        }
        
        var pbf: Int = 0
        let payloadList = data.slices(size: Int(UCIProtocolConstants.maxPayloadSize))
        let totalCount = payloadList.count
        var currentCount = 0
        
        for payload in payloadList {
            currentCount += 1
            if payload != payloadList.last {
                pbf = 1
            } else {
                pbf = 0
            }
            logger.log(type:.info, "Encoding payload \(currentCount) of \(totalCount)...")
            encBytes.append(contentsOf: UCIEncoder.encodePayload(payload: payload, pbf: pbf))
        }
        print("Encoded data package: \(encBytes)")
        return Data(encBytes)
    }
    
    
    static func encodePayload(payload: Data, pbf: Int) -> Data {
        let octet0:UInt8 = (UCIProtocolConstants.msgTypeCtrlCmd << 5) | (UInt8(pbf) << 4) | UCIProtocolConstants.gidVendEasylocateLegacy
        let octet1:UInt8 = (UCIProtocolConstants.oidVendEasylocateLegacy)
        let octet2:UInt8 = 0
        let octet3:UInt8 = UInt8(payload.count)
        let header = Data([octet0, octet1,octet2, octet3])
        let encodedPacket = header + payload.map { UInt8($0) }

        print("Encoded packet: \(encodedPacket)")

        return Data(encodedPacket)
    }
}

extension Data {
    func slices(size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            let startIndex = self.index(self.startIndex, offsetBy: $0)
            let endIndex = self.index(startIndex, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            return self[startIndex..<endIndex]
        }
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

extension Array {
    func slices(size: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, self.count)])
        }
    }
}
