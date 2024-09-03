//
//  DataModels.swift
//  SDK
//
//  Created by Christoph Scherbeck on 20.03.23.
//

import Foundation


public struct TraceletPosition:Equatable {
    
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


public struct TraceletStatus {
    public var role: String
    public var address: String
    public var siteIDe: String
    public var panID: String
    public var posX: Int16
    public var posY: Int16
    public var posZ: Int16
    public var stateByte: UInt8
    public var syncStateByte: UInt8
    public var syncSlot: UInt8
    public var syncModeByte: UInt8
    public var motionStateByte: UInt8
    public var batteryState: UInt8
    public var batteryLevel: UInt8
    public var txLateCnt: Int16
    public var flagsByte: UInt8
    public var uwbChannel: UInt8
    public var preambleRxCode: UInt8
    public var preambleTxCode: UInt8


    public init(role: String = "", address: String = "", siteIDe: String = "", panID: String = "", posX: Int16 = 0, posY: Int16 = 0, posZ: Int16 = 0, stateByte: UInt8 = 0, syncStateByte: UInt8 = 0, syncSlot: UInt8 = 0, syncModeByte: UInt8 = 0, motionStateByte: UInt8 = 0, batteryState: UInt8 = 0, batteryLevel: UInt8 = 0, txLateCnt: Int16 = 0, flagsByte: UInt8 = 0, uwbChannel: UInt8 = 0, preambleRxCode: UInt8 = 0, preambleTxCode: UInt8 = 0) {
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
        self.uwbChannel = uwbChannel
        self.preambleRxCode = preambleRxCode
        self.preambleTxCode = preambleTxCode
    }
}



public struct TraceletVersion {
    
    public var version = String()
}


public struct BufferElement

{
    public var timestamp = NSDate().timeIntervalSince1970
    public var message:Data
}


public struct SiteData: Codable, Equatable {

    
    public var map = Map()
    public var satlets = [Satlet]()
    public var sitefileScheme = SitefileScheme()
    
    public init() {
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
        public var originLatitude:Double?
        public var originLongitude:Double?
        public var originAzimuth:Double?
        public var uwbChannel:Int?

    }

    public struct Satlet: Codable, Equatable {
        public var address = ""
        public var isActive:Bool?
        public var name = ""
        public var panId = ""
        public var slot:Double?
        public var xCoordinate = 0.0
        public var yCoordinate = 0.0
        public var zCoordinate = 0.0
    }

    public struct SitefileScheme: Codable, Equatable {
        public var version = 0.0
    }
   
}

public enum ConnectionSource {
    case regularConnect
    case connectAndStartPositioning
}

public protocol ConnectionDelegate: AnyObject {
    func connectionDidSucceed()
    func connectionDidFail()
}

enum UCIDecoderState {
    case initial, running
}

public enum LogType {
   case info
   case warning
   case error
   
}
