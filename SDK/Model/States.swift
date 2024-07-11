//
//  States.swift
//  SDK
//
//  Created by Christoph Scherbeck on 16.03.23.
//

import Foundation


public enum ConnectionState {
    case CONNECTING
    case CONNECTED
    case DISCONNECTED
}

public enum BLEState {
    case BT_OK
    case BT_NA
    case UNKNOWN
    
}

public enum ScanState {
    case IDLE
    case SCANNING
}



enum ComState {
    case IDLE
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






// MARK: - Role Parser

public enum Role {
  case NR_MONITOR
  case NR_NODE30
  case NR_TAG30
  case NR_SATLET30
  case NR_UNDEFINED
}

    
    public func parseRole(byte:Int8) -> String {
    switch(byte) {
      case 1:
        return "MONITOR"
      case 2:
        return "NODE30"
      case 3:
        return "TAG30"
      case 4:
        return "SATLET30"
      default:
        return "UNDEFINED"
    }

  }
    
public func parseRoleToString(role:Role) -> String {
        return String(describing: role)
    }



// MARK: - Battery Parser



public enum BatteryStatus {
  case BAT_UNKNOWN
  case BAT_EXTERNAL_SOURCE
  case BAT_LEVEL
  case BAT_CHARGING
}


public func parseBatteryStatus(byte:UInt8) -> BatteryStatus {
    if(byte == 0xff) {
      return BatteryStatus.BAT_UNKNOWN
    } else if(byte == 0x80) {
      return BatteryStatus.BAT_EXTERNAL_SOURCE
    } else if(byte > 0 && byte < 101) {
      return BatteryStatus.BAT_LEVEL
    } else {
      return BatteryStatus.BAT_CHARGING;
    }
  }


public enum BatteryState {
  case NBS_EMPTY
  case NBS_LOW
  case NBS_MED
  case NBS_HIGH
  case NBS_FULL
  case NBS_CHARGING
  case NBS_UNKNOWN
  case UNDEFINED
}



public func  parseBatteryState (byte: UInt8) -> BatteryState {
    switch(byte) {
      case 0:
        return BatteryState.NBS_EMPTY
      case 1:
        return BatteryState.NBS_LOW
      case 2:
        return BatteryState.NBS_MED
      case 3:
        return BatteryState.NBS_HIGH
      case 4:
        return BatteryState.NBS_FULL
        case 5:
        return BatteryState.NBS_CHARGING
      case 6:
        return BatteryState.NBS_UNKNOWN
      default:
        return BatteryState.UNDEFINED
    }
  }

