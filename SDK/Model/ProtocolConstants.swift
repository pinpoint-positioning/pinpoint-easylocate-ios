//
//  ProtocolConstants.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation

public struct ProtocolConstants {
    
    // Protocol start byte
    public static let startByte:UInt8 = 0x7F

    // Protocol stop byte
    public static let stopByte:UInt8 = 0x8F

    // Protocol escape byte
    public static let  escapeByte:UInt8 = 0x1B

    // Protocol xor byte
    public static let  xorByte:UInt8 = 0x20
    
    // BLE Adv CompanyID
    public static let COMPANY_ID: UInt16 = 0x0E07
    

    // Commands
    public static let cmdCodeShowMe:UInt8 = 0x19
    public static let cmdCodeGetStatus:UInt8 = 0x12
    public static let cmdCodeGetVersion:UInt8 = 0x14
    public static let cmdCodeStartPositioning:UInt8 = 0x05
    public static let cmdCodeStopPositioning:UInt8 = 0x00
    public static let cmdCodeSetMotionCheckIntervalResponse:UInt8 = 0xa4
    public static let cmdCodeSetPositioningInterval:UInt8 = 0x23
    public static let cmdCodeSetChannel:UInt8 = 0x27
    public static let cmdCodeSetSiteID:UInt8 = 0x25
    
    // Message Indicators
    public static let cmdCodePosition:UInt8 = 0x97
    public static let cmdCodeStatus:UInt8 =  0x92
    public static let cmdCodeVersion:UInt8 = 0x94
    }


    public struct UCIProtocolConstants {
    static let maxPayloadSize: UInt8 = 255
    static let packetHeaderSize: UInt8 = 4
    static let packetSize: UInt8 = maxPayloadSize + packetHeaderSize
    static let messageSize: Int = 512

    static let msgTypeData: UInt8 = 0
    static let msgTypeCtrlCmd: UInt8 = 1
    static let msgTypeCtrlResp: UInt8 = 2
    static let msgTypeCtrlNtfy: UInt8 = 3

    static let gidVendEasylocateLegacy: UInt8 = 0xA
    static let oidVendEasylocateLegacy: UInt8 = 0x25
}

