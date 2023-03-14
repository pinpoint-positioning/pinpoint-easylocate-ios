//
//  Decoder.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation


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
    
    // Input: Byte array without start and stop byte
    public func getTraceletPosition(from byteArray: [UInt8]) -> (Int, Double, Double, Double) {
        
        if (byteArray[0] == ProtocolConstants.cmdCodePosition)
        {
            let xPostion = byteArray[1...2]
            let yPostion = byteArray[3...4]
            let zPostion = byteArray[5...6]
            
            // Read Bytes
            // Extract X-Postion
            
            let byteLength = byteArray.count
            let xPos = xPostion.withUnsafeBytes {
                Array($0.bindMemory(to: Int16.self)).map(Int16.init(littleEndian:))
            }
            
            // Extract Y-Postion
            
            let yPos = yPostion.withUnsafeBytes {
                Array($0.bindMemory(to: Int16.self)).map(Int16.init(littleEndian:))
            }
            
            // Extract Z-Postion
            
            let zPos = zPostion.withUnsafeBytes {
                Array($0.bindMemory(to: Int16.self)).map(Int16.init(littleEndian:))
            }
            // Return local position in dm (?)
            return (byteLength, Double(xPos[0]) / 10.0, Double(yPos[0]) / 10.0, Double (zPos[0]) / 10.0)
            
        }else{
            print("Received message is not a position")
            return (0,0,0,0)
        }
        
    }
    
}
