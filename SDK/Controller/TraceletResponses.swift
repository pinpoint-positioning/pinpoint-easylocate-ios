//
//  TraceletResponses.swift
//  SDK
//
//  Created by Christoph Scherbeck on 20.03.23.
//

import Foundation
import SwiftUI


public class TraceletResponse {
    
    public init () {}
    
    let logger = Logging.shared
    @ObservedObject var config = Config.shared
    
    
    //MARK: - Get Position Response
    
    public func GetPositionResponse (from byteArray: Data) -> TraceletPosition {
        
        let valByteArray = (config.uci ? UCIDecoder().decode(data: byteArray) : Decoder().validateMessage(of: byteArray))
        
        if (valByteArray[0] != ProtocolConstants.cmdCodePosition)
        {
            print ("Message is not a position")
        }
        // Position Byte-Ranges
        
        let xPosRange = Array(valByteArray[1...2])          // 2 Byte
        let yPosRange = Array(valByteArray[3...4])          // 2 Byte
        let zPosRange = Array(valByteArray[5...6])          // 2 Byte
        let covXxRange = Array(valByteArray[7...10])        // 4 Byte
        let covXyRange = Array(valByteArray[11...14])       // 4 Byte
        let covYyRange = Array(valByteArray[15...18])       // 4 Byte
        let siteIdRange = Array(valByteArray[19...20])      // 2 Byte
        let signatureRange = Array(valByteArray[21...28])   // 8 Byte
        
        // if no signature, return string of 0
        var signature = "0"
        
        // Get Raw bytes from ByteRanges and convert to dm in Double
        
        
        let xCoord = xPosRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int16.self).littleEndian) / 10.0 })
        let yCoord = yPosRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int16.self).littleEndian) / 10.0 })
        let zCoord = zPosRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int16.self).littleEndian) / 10.0 })
        let covXx = covXxRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int32.self).littleEndian) / 10.0 })
        let covXy = covXyRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int32.self).littleEndian) / 10.0 })
        let covYy = covYyRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int32.self).littleEndian) / 10.0 })
        let siteID = siteIdRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return "0x\(String(rawPtr.load(as: UInt16.self).littleEndian, radix: 16))"})
        
        if (byteArray.count > 21) {
            signature = signatureRange.withUnsafeBytes({
                (rawPtr: UnsafeRawBufferPointer) in
                return String (rawPtr.load(as: Int64.self).littleEndian)})
        }
        
        
        let a = ((covXx + covYy) / 2);
        let b = ((covXx  * covYy) - (covXy  * covXy));
        let var1 = a + sqrt(a*a - b);
        let var2 = a - sqrt(a*a - b);
        let acc = sqrt(max(var1, var2)) / 10;
        
        
        let response = TraceletPosition(xCoord: xCoord, yCoord: yCoord, zCoord: zCoord, covXx: covXx, covXy: covXy, covYy: covYy, siteID: siteID, signature: signature, accuracy: acc)
        return response
        
    }
    
    
    
    //MARK: - Get Satus Response
    
    
    func GetStatusResponse (from byteArray: Data) -> TraceletStatus {
        
        var valByteArray = (config.uci  ? UCIDecoder().decode(data: byteArray) : Decoder().validateMessage(of: byteArray))
        
        if (valByteArray[0] != ProtocolConstants.cmdCodeStatus)
        {
            print ("Message is not a status")
        }
        valByteArray.remove(at: 0)
        
        // Range definition
        
        let roleByteRange = valByteArray[0]                 // 1 Byte
        let addressRange = Array(valByteArray[1...2])       // 2 Byte
        let siteIDRange = Array(valByteArray[3...4])        // 2 Byte
        let panRange = Array(valByteArray[5...6])           // 2 Byte
        let posXRange = Array(valByteArray[7...8])          // 2 Byte
        let posYRange = Array(valByteArray[9...10])         // 2 Byte
        let posZRange = Array(valByteArray[11...12])        // 2 Byte
        let stateByteRange = valByteArray[13]               // 1 Byte
        let syncStateBytesRange = valByteArray[14]          // 1 Byte
        let syncSlotRange = valByteArray[15]
        let syncModeBytesRange = valByteArray[16]
        let motionStateBytesRange = valByteArray[17]
        let batStateByteRange = valByteArray[18]
        let batLevelBytesRange = valByteArray[19]
        let txLateCntRange = Array(valByteArray[20...21])   // 2 Byte
        let _ = valByteArray[23] // one byte, 23 fHndRange
        let _ = valByteArray[24]   // one byte, 24 cHndRange
        let flagsByteRange = Array(valByteArray[20...28]) // four bytes, 25, 26, 27, 28
        let uwbChannelRange = valByteArray[29]  // one byte, 26
        let preambleTxCodeRange = valByteArray[30]   // one byte, 27
        let preambleRxCodeRange  = valByteArray[31]  // one byte, 28
        
        
        // Get Bytes from Range
        let roleByte = Int8 (roleByteRange.littleEndian)
        let address = addressRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return "0x\(String(format: "%04X", rawPtr.load(as: UInt16.self).littleEndian))"})
        let siteID = "0x\(String(format: "%04X", littleEndianUInt16(from: siteIDRange)))"
        let panID = "0x\(String(format: "%04X", littleEndianUInt16(from: panRange)))"
        
        let posX = posXRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let posY = posYRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let posZ = posZRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let stateByte = UInt8 (stateByteRange.littleEndian)
        let syncStateBytes = UInt8 (syncStateBytesRange.littleEndian)
        let syncSlot = UInt8 (syncSlotRange.littleEndian)
        let syncModeByte = UInt8 (syncModeBytesRange.littleEndian)
        let motionStateByte = UInt8 (motionStateBytesRange.littleEndian)
        let batStateByte = UInt8 (batStateByteRange.littleEndian)
        let batLevelBytes = UInt8 (batLevelBytesRange.littleEndian)
        let txLateCnt = txLateCntRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let flagsByte = flagsByteRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })

        let uwbChannel = UInt8(uwbChannelRange.littleEndian)
        let preambleTxCode = UInt8(preambleTxCodeRange.littleEndian)
        let preambleRxCode  = UInt8(preambleRxCodeRange.littleEndian)
        
        
        let response = TraceletStatus(role: String(roleByte),
                                      address: address,
                                      siteIDe: siteID,
                                      panID: panID,
                                      posX: posX,
                                      posY: posY,
                                      posZ: posZ,
                                      stateByte: stateByte,
                                      syncStateByte: syncStateBytes,
                                      syncSlot: syncSlot,
                                      syncModeByte: syncModeByte,
                                      motionStateByte: motionStateByte,
                                      batteryState: batStateByte,
                                      batteryLevel: batLevelBytes,
                                      txLateCnt: txLateCnt,
                                      flagsByte: flagsByte,
                                      uwbChannel:uwbChannel,
                                      preambleRxCode:preambleRxCode,
                                      preambleTxCode:preambleTxCode
                                      
        )
        
        
        return response
        
    }
    func littleEndianUInt16(from bytes: Array<UInt8>) -> UInt16 {
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }
    
    
    
    
    public func getVersionResponse(from byteArray: Data) -> TraceletVersion {
        
        let valByteArray = (config.uci  ? UCIDecoder().decode(data: byteArray) : Decoder().validateMessage(of: byteArray))
        
        if (valByteArray[0] == ProtocolConstants.cmdCodeVersion) {
            let startIndex = 1 // Skip the first byte
            let versionData = Data(valByteArray[startIndex...])
            if let versionString = String(data: versionData, encoding: .utf8) {
                return TraceletVersion(version: versionString)
            } else {
                logger.log(type: .warning, "Failed to decode version string")
                return TraceletVersion(version: "")
            }
        } else {
            logger.log(type: .warning, "Received unknown response to version request")
            return TraceletVersion(version: "unkown")
        }
        
    }
    
}


// Response Protocol conformance
public protocol Response {
    var postion:TraceletPosition { get }
    var status: TraceletStatus { get }
    var version: TraceletVersion { get }
}





