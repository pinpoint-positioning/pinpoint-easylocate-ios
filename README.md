# iOS-tracelet-reader



## Getting started


# Import SDK

`import SDK`


# UUIDs
- Find/adjust UUIDs in `UUIDs.swift`.

# ProtocolConstants
- All neccessary protocol commands are store in `ProtocolConstants.swift`.



# Usage
`// Import the SDK and instantiate the API`
  
`import SDK`
`@EnvironmentObject var api:API`


# Observable vars

If the API-class is observed, the following variables are published:

## Usage
e.g.: `api.allResponses`, `api.status`


* allResponses:String
* generalState:STATE
    - .IDLE
    - .SCANNING
    - .CONNECTING
    - .CONNECTED
    - .DISCONNECTED
    - .WAITING_FOR_POSITION
    - .WAITING_FOR_STATUS
    - .WAITING_FOR_VERSION
    - .WAITING_FOR_RESPONSE
* scanState:STATE
    - .IDLE
    - .SCANNING
* localPosition: TL_PositionResponse
* status: TL_StatusResponse
* version: TL_VersionResponse
* discoveredTracelets: [CBPeripheral]
* connectedTracelet: CBPeripheral?


## API-Methods


```
scan(timeout: Double)
 
func stopScan() 

connect(device: CBPeripheral)
  
func disconnect() 

    
showMe(tracelet: CBPeripheral) 

startPositioning()     

stopPositioning() 
```



```
requestStatus(completion: @escaping ((TL_StatusResponse) -> Void)) 
        
getStatusString(completion: @escaping ((String) -> Void)) 
    
getLocalPosition(data:Data) -> TL_PositionResponse 

requestVersion(completion: @escaping  ((String) -> Void)) 
```
