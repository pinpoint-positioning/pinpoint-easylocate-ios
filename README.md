# iOS-tracelet-reader



## Getting started


# Import SDK

`import SDK`


# Usage
Import the SDK and instantiate the API
  
`import SDK`

`@EnvironmentObject var api:API`


# Observable vars

If the API-class is observed, the following variables are published:

* `allResponses:String`
* `generalState:STATE`
    - .IDLE
    - .SCANNING
    - .CONNECTING
    - .CONNECTED
    - .DISCONNECTED
    - .WAITING_FOR_RESPONSE
* `scanState:STATE`
    - .IDLE
    - .SCANNING
* `localPosition: TL_PositionResponse`
* `status: TL_StatusResponse`
* `version: TL_VersionResponse`
* `discoveredTracelets: [CBPeripheral]`
* `connectedTracelet: CBPeripheral?`

## Usage
e.g.: 
`api.allResponses`

`api.status`



## API-Methods


### scan(timeout: Double)
Scans for Pinpoint tracelets and publishes it in `discoveredTracelets: [CBPeripheral]`
 
### func stopScan() 
Stops a running scan

### connect(device: CBPeripheral)
Connects to a passed Pinpoint tracelet 
  
### func disconnect() 
Disconnects from a tracelet

### showMe(tracelet: CBPeripheral) 
Sents a "ShowMe"-command the the passed tracelet.
The tracelet light up a blue LED.

### startPositioning()   
Puts tracelet in positioning mode  

### stopPositioning() 
Stops positioning mode  

### requestStatus() 
Requests the current Status from the connected tracelet.

The answer is published in `status: TL_StatusResponse`

#### Structure of `TL_StatusResponse()`

```
struct TL_StatusResponse {    
    public var role = Int8()
    public var address = Int16()
    public var siteIDe = String()
    public var panID = UInt16()
    public var posX = Int16()
    public var posY = Int16()
    public var posZ = Int16()
    public var stateByte = Int8()
    public var syncStateByte = Int8()
    public var syncSlot = Int16() //?
    public var syncModeByte = Int8()
    public var motionStateByte = Int8()
    public var batteryState = UInt8()
    public var batteryLevel = UInt16()
    public var txLateCnt = Int16()
    public var flagsByte = UInt8()
}
```
  
    
### requestVersion() 
Requests the current Status from the connected tracelet and returns a string in the completionj handler.

The answer is published in ` version: TL_VersionResponse`

#### Structure of `TL_VersionResponse`
```
struct TL_VersionResponse {    
    public var version = String()
}
```


### requestPosition()
Requests the current Status from the connected tracelet and returns a string in the completionj handler.

The answer is published in ` localPosition: TL_PositionResponse`

#### Structure of `TL_VersionResponse`

```
struct TL_VersionResponse {    
    public var xCoord = Double()
    public var yCoord = Double()
    public var zCoord = Double()
    public var covXx =  Double()
    public var covXy =  Double()
    public var covYy =  Double()
    public var siteID =  String()
    public var signature = String()    
}
```



