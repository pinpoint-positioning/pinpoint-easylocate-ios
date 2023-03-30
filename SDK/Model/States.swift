//
//  States.swift
//  SDK
//
//  Created by Christoph Scherbeck on 16.03.23.
//

import Foundation


public enum BLE_State {
    
    case BT_OK
    case BT_NA
    case INIT
    case APPROACHED
    case CONNECTED
    case GOT_RXSERVICE
    case GOT_CHARACTERISTICS
    case UNKNOWN
    
}
