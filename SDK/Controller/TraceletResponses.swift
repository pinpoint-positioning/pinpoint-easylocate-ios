//
//  TraceletResponses.swift
//  SDK
//
//  Created by Christoph Scherbeck on 20.03.23.
//

import Foundation


public class TraceletResponse {
    
    public init () {}
    
    
    //MARK: - Get Position Response
    
    public func GetPositionResponse (from byteArray: Data) -> TL_PositionResponse {
        
        // Remove?
        let valByteArray = Decoder().ValidateMessage(of: byteArray)
        
        
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
        // For siteID: Important to use UInt16 not Int16
        // Check if correct
        // Signature is available in tracelet?
        
        if (byteArray.count > 21) {
            signature = signatureRange.withUnsafeBytes({
                (rawPtr: UnsafeRawBufferPointer) in
                return String (rawPtr.load(as: Int64.self).littleEndian)})
        }
        
        
        let response = TL_PositionResponse(xCoord: xCoord, yCoord: yCoord, zCoord: zCoord, covXx: covXx, covXy: covXy, covYy: covYy, siteID: siteID, signature: signature)
        
        return response
        
    }
    
    
    
    //MARK: - Get Satus Response
    
    
    public func GetStatusResponse (from byteArray: Data) -> TL_StatusResponse {
        
        // Validate the message and remove start/endbyte
        var valByteArray = Decoder().ValidateMessage(of: byteArray)
        
        
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
        let flagsByteRange = valByteArray[23]               // 1 Byte
        
        
        
        
        // Get Bytes from Range
        
        let roleByte = Int8 (roleByteRange.littleEndian)
        let address = addressRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let siteID = siteIDRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return "0x\(String(rawPtr.load(as: UInt16.self).littleEndian,radix: 16))"})
        let panID = panRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: UInt16.self).littleEndian })
        let posX = posXRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let posY = posYRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let posZ = posZRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let stateByte = Int8 (stateByteRange.littleEndian)
        let syncStateBytes = Int8 (syncStateBytesRange.littleEndian)
        let syncSlot = Int16 (syncSlotRange.littleEndian)
        let syncModeByte = Int8 (syncModeBytesRange.littleEndian)
        let motionStateByte = Int8 (motionStateBytesRange.littleEndian)
        let batStateByte = UInt8 (batStateByteRange.littleEndian)
        let batLevelBytes = UInt16 (batLevelBytesRange.littleEndian)
        let txLateCnt = txLateCntRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return rawPtr.load(as: Int16.self).littleEndian })
        let flagsByte = UInt8(flagsByteRange.littleEndian)
        
        
        let response = TL_StatusResponse(role: roleByte,
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
                                         flagsByte: flagsByte)
        
        return response
        
    }
    

    
    
    
    
    public func getVersionResponse(from byteArray: Data) -> String {
        
        let valByteArray = Decoder().ValidateMessage(of: byteArray)
        if (valByteArray[0] == ProtocolConstants.cmdCodeVersion) {
            
            let version = Array(valByteArray[0...1]).withUnsafeBytes({
                (rawPtr: UnsafeRawBufferPointer) in

                return "0x\(String(rawPtr.load(as: UInt16.self).littleEndian, radix: 16))"})
        
            return version
        }else {
            let msg = "Received unknown response to version request with command code 0x${commandCode.toRadixString(16)}.";
        }
        
        
        return "get version"
    }
    
    
    
}


// Response Protocol conformance
public protocol Response {
    var postion:TL_PositionResponse { get }
    var status: TL_StatusResponse { get }
    var version: TL_VersionResponse { get }
    // and whatever else is common to these classes
}





