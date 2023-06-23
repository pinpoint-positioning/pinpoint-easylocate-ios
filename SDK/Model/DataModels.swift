//
//  DataModels.swift
//  SDK
//
//  Created by Christoph Scherbeck on 20.03.23.
//

import Foundation
import Combine


// Positin Model
public struct TL_PositionResponse:Equatable {
    
    public var xCoord = Double()
    public var yCoord = Double()
    public var zCoord = Double()
    public var covXx =  Double()
    public var covXy =  Double()
    public var covYy =  Double()
    public var siteID =  String()
    public var signature = String()
    public var accuracy = Double()
    
}


public struct TL_StatusResponse {
    
    public var role:String
    public var address : String
    public var siteIDe : String
    public var panID :String
    public var posX : String
    public var posY : String
    public var posZ : String
    public var stateByte : String
    public var syncStateByte : String
    public var syncSlot : String
    public var syncModeByte : String
    public var motionStateByte :String
    public var batteryState : String
    public var batteryLevel : String
    public var txLateCnt : String
    public var flagsByte : String
    
    
    public init(role:String = "",
                address : String = "",
                siteIDe:String = "",
                panID: String = "",
                posX:String = "",
                posY: String = "",
                posZ : String = "",
                stateByte : String = "",
                syncStateByte : String = "",
                syncSlot : String = "",
                syncModeByte : String = "",
                motionStateByte : String = "",
                batteryState :String = "",
                batteryLevel :String = "",
                txLateCnt : String = "",
                flagsByte :String = "")
    
    {
        self.role = role
        self.address = address
        self.siteIDe = siteIDe
        self.panID = panID
        self.posX = posX
        self.posY = posY
        self.posZ = posZ
        self.stateByte = stateByte
        self.syncStateByte = syncStateByte
        self.syncSlot = syncSlot
        self.syncModeByte = syncModeByte
        self.motionStateByte = motionStateByte
        self.batteryState = batteryState
        self.batteryLevel = batteryLevel
        self.txLateCnt = txLateCnt
        self.flagsByte = flagsByte
    }
    
}

public struct TL_VersionResponse {
    
    public var version = String()
}


public struct BufferElement

{
    public var timestamp = NSDate().timeIntervalSince1970
    public var message:Data
}

public struct Wgs84Position {
   var lat: Double
   var lon: Double
   var alt: Double
   var covXx:Double
   var covXy:Double
   var covYy:Double
   var siteID:String
}


public struct SiteData: Codable {
    public var map: Map
}

public struct Map:Codable {
    public var mapFile: String
    public var mapFileOriginX:Double
    public var mapFileOriginY: Double
    public var mapFileRes: Double
    public var mapName: String
    public var mapSiteId:String
    public var originLatitude: Double
    public var originLongitude: Double
    public var originAzimuth:Double
    public var uwbChannel: Int
}

