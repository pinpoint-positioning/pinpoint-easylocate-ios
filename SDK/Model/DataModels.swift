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


public struct SiteData: Codable, Equatable {

    
    public var map = Map()
    public var satlets = [Satlet]()
    public var sitefileScheme = SitefileScheme()
    
    public init() {
        // Initialize your properties here
        self.map = Map()
        self.satlets = []
        self.sitefileScheme = SitefileScheme()
    }

    public struct Map: Codable, Equatable {
        public var mapFile = ""
        public var mapFileOriginX = 0.0
        public var mapFileOriginY = 0.0
        public var mapFileRes = 0.0
        public var mapName = ""
        public var mapSiteId = ""
        public var originLatitude = 0.0
        public var originLongitude = 0.0
        public var originAzimuth = 0.0
        public var uwbChannel = 0
        

    }

    public struct Satlet: Codable, Equatable {
        public var address = ""
        public var isActive:Bool?
        public var name = ""
        public var panId = ""
        public var slot = 0.0
        public var xCoordinate = 0.0
        public var yCoordinate = 0.0
        public var zCoordinate = 0.0
    }

    public struct SitefileScheme: Codable, Equatable {
        public var version = 0.0
    }
}

