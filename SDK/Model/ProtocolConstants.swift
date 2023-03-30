//
//  ProtocolConstants.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation

public struct ProtocolConstants {
    
      /// Protocol start byte
    public static let startByte:UInt8 = 0x7F

      /// Protocol stop byte
    public static let stopByte:UInt8 = 0x8F

      /// Protocol escape byte
    public static let  escapeByte:UInt8 = 0x1B

      /// Protocol xor byte
    public static let  xorByte:UInt8 = 0x20
    

    // Commands
    public static let cmdCodeShowMe:UInt8 = 0x19
    public static let cmdCodeGetStatus:UInt8 = 0x12
    public static let cmdCodeGetVersion:UInt8 = 0x14
    
    
    
    // Message Indicators
    public static let cmdCodePosition:UInt8 = 0x97
    public static let cmdCodeStatus:UInt8 =  0x92
    public static let cmdCodeVersion:UInt8 = 0x94
    }






//        Byte0: 7F    // START_BYTE
//        Byte1: 97    // cmdByte -> 97 Position
//        Byte2: 55    // PosX 1
//        Byte3: 00    // PosX 2
//        Byte4: 1D    // PosY 1
//        Byte5: 00    // PosY 2
//        Byte6: 0A    // PosZ 1
//        Byte7: 00    // PosZ 1
//        Byte8: 00    // PosZ 2
//        Byte9: 00    // CovXx 1
//        Byte10: 00   // CovXx 2
//        Byte11: 00   // CovXx 3
//        Byte12: 00   // CovXx 4
//        Byte13: 00   // CovXy 1
//        Byte14: 00   // CovXy 2
//        Byte15: 00   // CovXy 3
//        Byte16: 00   // CovXy 4
//        Byte17: 00   // CovYy 1
//        Byte18: 00   // CovYy 2
//        Byte19: 00   // CovYy 3
//        Byte20: 7E   // CovYy 4
//        Byte21: 51   // siteID 1
//        Byte22: FD   // siteID 2
//        Byte23: BB
//        Byte24: 01
//        Byte25: B2
//        Byte26: 38
//        Byte27: 4D
//        Byte28: 21
//        Byte29: 53
//        Byte30: 8F // END_BYTE
//      PREFIX_BYTE: 1B
            
//      XOR_BYTE_MASK = 0x20
//     COMMAND_ACTIVATE(0x01),
//     COMMAND_DEACTIVATE(COMMAND_ACTIVATE.hexValue),

//     COMMAND_ACTIVATE_TAG30(0x05),

//     COMMAND_GET_STATUS(0x12),
//     COMMAND_GET_STATUS_RESPONSE(0x92.toByte()),

//     COMMAND_DISTANCE(0x81.toByte()),
//     COMMAND_POSITION(0x97.toByte())
            
