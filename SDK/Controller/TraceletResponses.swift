//
//  TraceletResponses.swift
//  SDK
//
//  Created by Christoph Scherbeck on 20.03.23.
//

import Foundation


public class TraceletResponse {
    
    public init () {}
    
    let logger = Logger()
    
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
        
        
        let a = ((covXx + covYy) / 2);
        let b = ((covXx  * covYy) - (covXy  * covXy));
        let var1 = a + sqrt(a*a - b);
        let var2 = a - sqrt(a*a - b);
        let acc = sqrt(max(var1, var2)) / 10;

        
        let response = TL_PositionResponse(xCoord: xCoord, yCoord: yCoord, zCoord: zCoord, covXx: covXx, covXy: covXy, covYy: covYy, siteID: siteID, signature: signature, accuracy: acc)
        
        //This will log all positions in the log file
        //logger.log(type: .Info, String(describing: response))
        return response
        
    }
    
    
    
    //MARK: - Get Satus Response
    
    
     func GetStatusResponse (from byteArray: Data) -> TL_StatusResponse {
        
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
             return "0x\(String(format: "%04X", rawPtr.load(as: UInt16.self).littleEndian))"})
//         let siteID = siteIDRange.withUnsafeBytes({
//             (rawPtr: UnsafeRawBufferPointer) in
//             return "0x\(String(format: "%04X", rawPtr.load(as: UInt16.self).littleEndian))"})
//         let panID = panRange.withUnsafeBytes({
//             (rawPtr: UnsafeRawBufferPointer) in
//             return "0x\(String(format: "%04X", rawPtr.load(as: UInt16.self).littleEndian))"})
         
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
        
        
        let response = TL_StatusResponse(role: String(roleByte),
                                         address: String(address),
                                         siteIDe: String(siteID),
                                         panID: String(panID),
                                         posX: String(posX),
                                         posY: String(posY),
                                         posZ: String(posZ),
                                         stateByte: String(stateByte),
                                         syncStateByte: String(syncStateBytes),
                                         syncSlot: String(syncSlot),
                                         syncModeByte: String(syncModeByte),
                                         motionStateByte: String(motionStateByte),
                                         batteryState: String(batStateByte),
                                         batteryLevel: String(batLevelBytes),
                                         txLateCnt: String(txLateCnt),
                                         flagsByte: String(flagsByte))
        
        return response
        
    }
    func littleEndianUInt16(from bytes: Array<UInt8>) -> UInt16 {
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }

    
    
    
    
    public func getVersionResponse(from byteArray: Data) -> TL_VersionResponse {
        
        let valByteArray = Decoder().ValidateMessage(of: byteArray)
        if (valByteArray[0] == ProtocolConstants.cmdCodeVersion) {
            
            let versionString = String(decoding: valByteArray, as: UTF8.self)
            return TL_VersionResponse(version: versionString)
        } else {
            logger.log(type: .Warning, "Received unknown response to version request")
            return TL_VersionResponse(version: "")
        }
        
    }
    
}


// Response Protocol conformance
public protocol Response {
    var postion:TL_PositionResponse { get }
    var status: TL_StatusResponse { get }
    var version: TL_VersionResponse { get }
    // and whatever else is common to these classes
}





