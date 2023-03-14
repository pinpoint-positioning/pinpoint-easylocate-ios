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
            
            let validatedMessage = TagValidateMessage(of: data).byteArray
            let localPosition = TagPositionResponse(of: validatedMessage)
            
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
## TagValidateMessage(of:Data)

Validate the completeness of the message by checking the Start- and End-byte and remove them from the array.

## TagPositionResponse

Checks the validated array for the Position-Command-Byte and extracts the local position values in dm (?) vom it.



