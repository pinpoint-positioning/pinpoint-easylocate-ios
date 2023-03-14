//
//  Decoder.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation



public class TagValidateMessage {
    
    public var byteArray:Data
    
    
    public init(of byteArray:Data ) {
        
        self.byteArray = byteArray
        print ("byte array: \(byteArray)")
        
        // Check if array has start byte
        if (byteArray[0] == ProtocolConstants.startByte)
        {
            print ("start byte found")
            //Remove start byte
            self.byteArray.remove(at: 0)
            //Check if array has end byte
            //CAREFUL: Is forced unwrapped - TBD
            if (byteArray.last! == ProtocolConstants.stopByte)
            {
                print ("end byte found")
                //Remove Ende byte
                self.byteArray.removeLast()
            }
        }
    }
}



public class TagPositionResponse {
    
    // Input: Byte array without start and stop byte
    public var byteArray:Data
    public var xCoord = Double()
    public var yCoord = Double()
    public var zCoord = Double()
    public var covXx = Double()
    public var covXy = Double()
    public var covYy = Double()
    public var siteID = String()
    
    public init (of byteArray: Data) {
        
        
        self.byteArray = byteArray
        
        if (byteArray[0] == ProtocolConstants.cmdCodePosition)
        {
            
            // Position Byte-Ranges
            
            let xPosRange = Array(byteArray[1...2])         // 2 Byte
            let yPosRange = Array(byteArray[3...4])         // 2 Byte
            let zPosRange = Array(byteArray[5...6])         // 2 Byte
            let covXxRange = Array(byteArray[7...10])       // 4 Byte
            let covXyRange = Array(byteArray[11...14])      // 4 Byte
            let covYyRange = Array(byteArray[15...18])      // 4 Byte
            let siteIdRange = Array(byteArray[19...20])     // 2 Byte
            
            
            
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
                    return "0x\(String(rawPtr.load(as: Int16.self),radix: 16))"
                
            })
  
        }
    }
}










public class Decoder
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
            print (byteArray[0] )
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
