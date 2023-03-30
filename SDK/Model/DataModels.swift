//
//  DataModels.swift
//  SDK
//
//  Created by Christoph Scherbeck on 20.03.23.
//

import Foundation


// Positin Model
public struct TL_PositionResponse {
    
    public var xCoord = Double()
    public var yCoord = Double()
    public var zCoord = Double()
    public var covXx =  Double()
    public var covXy =  Double()
    public var covYy =  Double()
    public var siteID =  String()
    public var signature = String()
    
}


public struct TL_StatusResponse {
    
    public var role = Int8()
    public var address = Int16()
    public var siteIDe = String()
    // Check if UInt is correct for panID
    public var panID = UInt16()
    public var posX = Int16()
    public var posY = Int16()
    public var posZ = Int16()
    public var stateByte = Int8()
    public var syncStateByte = Int8()
    public var syncSlot = Int16() //?
    public var syncModeByte = Int8()
    public var motionStateByte = Int8()
    public var batteryState = UInt8()
    public var batteryLevel = UInt16() //?
    public var txLateCnt = Int16()
    public var flagsByte = UInt8()

}

public struct BufferElement

{
    public var timestamp = NSDate().timeIntervalSince1970
    public var message:Data
}
