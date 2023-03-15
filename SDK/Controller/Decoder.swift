//
//  Decoder.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation


public class Decoder {
    
    public init() {
        
    }
    
    lazy var byteArray = Data()
    lazy var decByteArray = [UInt8]()
    
    
    public func ValidateMessage(of byteArray:Data ) throws -> [UInt8]   {
        
        //Reset array every run
        if (!decByteArray.isEmpty)
        {
            decByteArray.removeAll()
        }
        enum RuntimeError: Error {
            case validationError(String)
        }
        
        
        // Check if array has start byte
        if (byteArray[0] != ProtocolConstants.startByte)
        {
            throw RuntimeError.validationError("No Start Byte")
        }
        //Check if array has end byte
        //CAREFUL: Is forced unwrapped - TBD
        if (byteArray.last! != ProtocolConstants.stopByte)
        {
            throw RuntimeError.validationError("No Stop Byte")
        }
        
        print ("FullArray: \(byteArray)")
        //Remove start byte
        var strippedByteArray = byteArray
        strippedByteArray.remove(at: 0)
        //Remove Ende byte
        strippedByteArray.removeLast()
        print ("strippedArray: \(strippedByteArray)")
        
        // Iterate trough message and XOR the byte after the escape byte, if there is one
        var byteIt = strippedByteArray.makeIterator()
        while var byte = byteIt.next(){
            if (byte == ProtocolConstants.escapeByte) {
                byte = byteIt.next()!;
                byte = byte ^ UInt8(ProtocolConstants.xorByte);
            }
            decByteArray.append(byte);
            print ("decDyn: \(decByteArray)")
        }
        print ("decoded: \(decByteArray)")
        
        return decByteArray
        
    }
}






public class TagPositionResponse {
    //Error types -> Move to seperate file
    enum RuntimeError: Error {
        case validationError(String)
    }
    
    // Input: Byte array without start and stop byte
    public var byteArray:[UInt8]
    public var xCoord = Double()
    public var yCoord = Double()
    public var zCoord = Double()
    public var covXx = Double()
    public var covXy = Double()
    public var covYy = Double()
    public var siteID = String()
    public var signature = ""
    
    public init (of byteArray: [UInt8]) throws {
        
        
        self.byteArray = byteArray
        
        if (byteArray[0] != ProtocolConstants.cmdCodePosition)
        {
            throw RuntimeError.validationError("Message is not a position")
        }
        // Position Byte-Ranges

        let xPosRange = Array(byteArray[1...2])         // 2 Byte
        let yPosRange = Array(byteArray[3...4])         // 2 Byte
        let zPosRange = Array(byteArray[5...6])         // 2 Byte
        let covXxRange = Array(byteArray[7...10])       // 4 Byte
        let covXyRange = Array(byteArray[11...14])      // 4 Byte
        let covYyRange = Array(byteArray[15...18])      // 4 Byte
        let siteIdRange = Array(byteArray[19...20])     // 2 Byte
        let  signatureRange = Array(byteArray[21...28])       // 8 Byte
        
        // Get Raw bytes from ByteRanges and convert to dm in Double
        
        xCoord = xPosRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int16.self)) / 10.0 })
        yCoord = yPosRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int16.self)) / 10.0 })
        zCoord = zPosRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int16.self)) / 10.0 })
        covXx = covXxRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int32.self)) / 10.0 })
        covXy = covXyRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int32.self)) / 10.0 })
        covYy = covYyRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return Double (rawPtr.load(as: Int32.self)) / 10.0 })
        siteID = siteIdRange.withUnsafeBytes({
            (rawPtr: UnsafeRawBufferPointer) in
            return "0x\(String(rawPtr.load(as: Int16.self),radix: 16))"})
        
        // Check if correct
        // Signature is available in tracelet?
        
        if (byteArray.count > 21) {
            signature = signatureRange.withUnsafeBytes({
                (rawPtr: UnsafeRawBufferPointer) in
                return String (rawPtr.load(as: Int64.self))})
        }
    
    }
    
}










public class Decoder2
{
    public init() {}
    
    public func getByteArray(from data: Data) -> [UInt8]?
    {
        
        var byteArray = [UInt8] (data)
        print ("byte array: \(byteArray)")
        
        // Check if array has start byte
        if (byteArray[0] == ProtocolConstants.startByte)
        {
            print ("start byte found")
            //Remove start byte
            byteArray.remove(at: 0)
            //Check if array has end byte
            //CAREFUL: Is forced unwrapped - TBD
            if (byteArray.last! == ProtocolConstants.stopByte)
            {
                print ("end byte found")
                //Remove Ende byte
                byteArray.removeLast()
                
                return byteArray
            }else {
                print ("no end byte")
                return nil
                
            }
        }else{
            print("no start byte")
            return nil
        }
    }
    
    
    
}

//
//
//
//public class TagPositionResponse {
//
//    // Input: Byte array without start and stop byte
//    var byteArray:[UInt8]
//    let cmdCode = 0x97;
//    let xCoord:Double
//    let yCoord:Double
//    let zCoord:Double
//    let covXx:Double
//    let covXy:Double
//    let covYy:Double
//    let siteId:String
//    let signature:String
//
//
//    public init (byteArray: [UInt8]) {
//
//        self.byteArray = byteArray
//
//
//        if (byteArray[0] == ProtocolConstants.cmdCodePosition)
//        {
//            // Read Bytes
//
//            let xPostion = byteArray[1...2]
//            let yPostion = byteArray[3...4]
//            let zPostion = byteArray[5...6]
//
//            // Extract X-Postion
//
//            let bytesCopied = withUnsafeMutableBytes(of: &xCoord, { xPostion.copyBytes(to: $0)} )
//            assert(bytesCopied == MemoryLayout.size(ofValue: xCoord))
//            print(xCoord) // 42.13
//
//
//
//
//            let byteLength = byteArray.count
//            let xPos = xPostion.withUnsafeBytes {
//                Array($0.bindMemory(to: Int16.self)).map(Int16.init(littleEndian:))
//            }
//
//            // Extract Y-Postion
//
//            let yPos = yPostion.withUnsafeBytes {
//                Array($0.bindMemory(to: Int16.self)).map(Int16.init(littleEndian:))
//            }
//
//            // Extract Z-Postion
//
//            let zPos = zPostion.withUnsafeBytes {
//                Array($0.bindMemory(to: Int16.self)).map(Int16.init(littleEndian:))
//            }
//            // Return local position in dm (?)
//            return (byteLength, Double(xPos[0]) / 10.0, Double(yPos[0]) / 10.0, Double (zPos[0]) / 10.0)
//
//        }else{
//            print("Received message is not a position")
//
//        }
//
//    }
//}
//
//
//
