//
//  Encoder.swift
//  SDK
//
//  Created by Christoph Scherbeck on 15.03.23.
//

import Foundation


 class Encoder {
    
    let logger = Logger()

  // TODO put encodeByte and encodeBytes together

     
     // Encode single byte
     // CRC Checksum included
     
         static func encodeByte(_ byte: UInt8) -> Data {
             var encBytes = [UInt8]()

             if byte == ProtocolConstants.startByte ||
                 byte == ProtocolConstants.stopByte ||
                 byte == ProtocolConstants.escapeByte {
                 encBytes.append(ProtocolConstants.escapeByte)
                 encBytes.append(ProtocolConstants.xorByte ^ byte)
             } else {
                 encBytes.append(byte)
             }
             let checksum = calcChecksum([byte])
             encBytes.append(contentsOf: checksum)
             encBytes.insert(ProtocolConstants.startByte, at: 0)
             encBytes.append(ProtocolConstants.stopByte)
             return Data(encBytes)
         }
     
     
     
     
  // Encode single byte - Not i use in API
// NO CRC!
     
     
   static func encodeByte_old(_ byte: UInt8) -> Data {
    if byte == ProtocolConstants.startByte ||
        byte == ProtocolConstants.stopByte ||
        byte == ProtocolConstants.escapeByte {
      let encodedByte = UInt64(ProtocolConstants.startByte) |
                        UInt64(ProtocolConstants.escapeByte) << 8 |
                        UInt64(ProtocolConstants.xorByte ^ byte) << 16 |
                        UInt64(ProtocolConstants.stopByte) << 24
      return withUnsafeBytes(of: encodedByte) { Data($0) }
    } else {
      let encodedByte = UInt64(ProtocolConstants.startByte) |
                        UInt64(byte) << 8 |
                        UInt64(ProtocolConstants.stopByte) << 16
      return withUnsafeBytes(of: encodedByte) { Data($0) }
    }
  }
     
     
     
     

  // Encode byte array
    // NO CRC Yet
     // Maybe not even needed for tracelet
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
       
    let checksum = calcChecksum(bytes)
    
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
     
     
     
     
     
     
     static func calcChecksum(_ bytes: [UInt8]) -> [UInt8] {
         var sum: UInt16 = 0
         for byte in bytes {
             sum += UInt16(byte)
         }
         let checksum = withUnsafeBytes(of: sum.littleEndian, Array.init)
         return checksum
     }
     
}

    

