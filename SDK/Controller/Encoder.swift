//
//  Encoder.swift
//  SDK
//
//  Created by Christoph Scherbeck on 15.03.23.
//

import Foundation


public class Encoder {

  // TODO put encodeByte and encodeBytes together

  /// Encode byte
  public static func encodeByte(_ byte: UInt8) -> Data {
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

  /// Encode byte array
  public static func encodeBytes(_ bytes: [UInt8]) -> Data {
 
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
    encBytes.append(ProtocolConstants.stopByte)

    bytesAsHex = ""
    encBytes.forEach { bytesAsHex.append(String(format: "%02hhx", $0)) }
    print("Encoded data package: \(bytesAsHex)")

    let encodedData = Data(encBytes)
    return encodedData
  }
}

    

