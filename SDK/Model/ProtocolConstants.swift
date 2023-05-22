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
    

    // Commands
    public static let cmdCodeShowMe:UInt8 = 0x19
    public static let cmdCodeGetStatus:UInt8 = 0x12
    public static let cmdCodeGetVersion:UInt8 = 0x14
    public static let cmdCodeStartPositioning:UInt8 = 0x05
    public static let cmdCodeStopPositioning:UInt8 = 0x00
    public static let cmdCodeSetMotionCheckIntervalResponse:UInt8 = 0xa4
    public static let cmdCodeSetPositioningInterval:UInt8 = 0x23
    public static let cmdCodeSetChannel:UInt8 = 0x27
    
    
    
    // Message Indicators
    public static let cmdCodePosition:UInt8 = 0x97
    public static let cmdCodeStatus:UInt8 =  0x92
    public static let cmdCodeVersion:UInt8 = 0x94
    }
