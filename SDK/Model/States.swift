//
//  States.swift
//  SDK
//
//  Created by Christoph Scherbeck on 16.03.23.
//

import Foundation



public enum STATE {
    
    // States accessible to enduser
    
    case IDLE
    case SCANNING
    case CONNECTING
    case CONNECTED
    case DISCONNECTED
    case WAITING_FOR_POSITION
    case WAITING_FOR_STATUS
    case WAITING_FOR_VERSION
    case WAITING_FOR_RESPONSE
    case SHOW_ME
    //Internal
    
    case APPROACHED
    case GOT_RXSERVICE
    case GOT_CHARACTERISTICS
    
    case UNKNOWN
    
    //States from Flutter
    case INITIALIZED
    case PAUSED
    case AWAIT_RESPONSE
    case NO_RESPONSE

    
}

public enum BLE_State {
    
    case BT_OK
    case BT_NA
    case UNKNOWN
    
}

