# iOS-tracelet-reader



## Getting started


# Import SDK

`import SDK`


# UUIDs
- Find/adjust UUIDs in `UUIDs.swift`.

# ProtocolConstants
- All neccessary protocol commands are store in `ProtocolConstants.swift`.

# Get Position data via Bluetooth connection to tracelet

```
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,error: Error?) {
                
        guard let data = characteristic.value else {
            // no data transmitted, handle if needed
            print("no data")
            return
        }

        // Get TX  value
        if characteristic.uuid == UUIDs.traceletTxChar {
            // Set State
            recievingData = true
            
            let validatedMessage = TagValidateMessage(byteArray: data).byteArray
            let localPosition = TagPositionResponse(byteArray: validatedMessage)
            
            let xPos = localPosition.xCoord
            let yPos = localPosition.yCoord
            let zPos = localPosition.zCoord
            let covXx = localPosition.covXx
            let covXy = localPosition.covXy
            let covYy = localPosition.covYy
            let siteId = localPosition.siteID   
 
        }
    }

```




# Get ByteArray from UART-Message
```
let byteArray = decoder.getByteArray(from: data)
```

# Get Tracelet Position

```
let xPos = decoder.getTraceletPosition(from: byteArray).0
let yPos = decoder.getTraceletPosition(from: byteArray).1
let zPos = decoder.getTraceletPosition(from: byteArray).2
```
