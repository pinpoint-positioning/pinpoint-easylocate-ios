# iOS-tracelet-reader



## Getting started


# Import SDK

`import SDK`


# UUIDs
- Find/adjust UUIDs in `UUIDs.swift`.

# ProtocolConstants
- All neccessary protocol commands are store in `ProtocolConstants.swift`.

# Get Position data from connected tracelet

## Instantiate Decoder()

```
let decoder = Decoder()

```
do {

    let localPosition = try TagPositionResponse(of: data)

    / Example - Get dosition data
    let xPos = localPosition.xCoord
    let yPos = localPosition.yCoord
    let zPos = localPosition.zCoord
    let covXx = localPosition.covXx
    let covXy = localPosition.covXy
    let covYy = localPosition.covYy
    let siteId = localPosition.siteID
    let signature = localPosition.signature


    }catch{

        print(error)
    }

```
## TagValidateMessage(of:Data)

Validate the completeness of the message by checking the Start- and End-byte and remove them from the array.

## TagPositionResponse

Checks the validated array for the Position-Command-Byte and extracts the local position values in dm (?) vom it.




Left at:

Misaligned Pointer error in Status Decoder
Parsing of Status Data
chaging moving pointer to byteRange
Should the stream of data be automatically identifed for the message type? (Classifier)
Buffer with all messages or register listener event
