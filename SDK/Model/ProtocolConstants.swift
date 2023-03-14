//
//  ProtocolConstants.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 13.03.23.
//

import Foundation

public struct ProtocolConstants {
    
      /// Protocol start byte
    public static let startByte = 0x7F

      /// Protocol stop byte
    public static let stopByte = 0x8F

      /// Protocol escape byte
    public static let  escapeByte = 0x1B

      /// Protocol xor byte
    public static let  xorByte = 0x20
    
    /// cmcCode: Position
    public static let cmdCodePosition = 0x97
    }




//        Byte0: 7F // START_BYTE
//        Byte1: 97 // cmdByte -> 97 Position
//        Byte2: 55
//        Byte3: 00
//        Byte4: 1D
//        Byte5: 00
//        Byte6: 0A
//        Byte7: 00
//        Byte8: 00
//        Byte9: 00
//        Byte10: 00
//        Byte11: 00
//        Byte12: 00
//        Byte13: 00
//        Byte14: 00
//        Byte15: 00
//        Byte16: 00
//        Byte17: 00
//        Byte18: 00
//        Byte19: 00
//        Byte20: 7E
//        Byte21: 51
//        Byte22: FD
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
            
