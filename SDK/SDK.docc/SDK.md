# ``SDK``

<!--@START_MENU_TOKEN@-->Summary<!--@END_MENU_TOKEN@-->

## Overview

This SDK can be imported as a Framework for XCode.
The SDK contains the identifiers and decoding functions for Pinpoint Tracelets

You can find an example for intgration in the `ios-tracelet-reader`-app


<!--@START_MENU_TOKEN@-->Text<!--@END_MENU_TOKEN@-->

## Topics

### Import SDK

`import SDK`

### UUIDs
- Find/adjust UUIDs in `UUIDs.swift`.

### ProtocolConstants
- All neccessary protocol commands are store in `ProtocolConstants.swift`.

### Get ByteArray from UART-Message
```
let byteArray = decoder.getByteArray(from: data)
```

### Get Tracelet Position

```
let xPos = decoder.getTraceletPosition(from: byteArray).0
let yPos = decoder.getTraceletPosition(from: byteArray).1
let zPos = decoder.getTraceletPosition(from: byteArray).2
```






### <!--@START_MENU_TOKEN@-->Group<!--@END_MENU_TOKEN@-->

- <!--@START_MENU_TOKEN@-->``Symbol``<!--@END_MENU_TOKEN@-->










