# Installation via CocoaPods

# Usage


# pinpoint-easylocate-ios Pod

## Installation

To integrate the `pinpoint-easylocate-ios` pod into your Xcode project using CocoaPods, specify it in your `Podfile`:



```ruby
# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'YourAppTargetName' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for YourAppTargetName
  pod 'pinpoint-easylocate-ios', '~> 11.4.1.5'

end
```


Then, run the following command in your terminal:

```sh
pod install
```

## Usage

To use the `pinpoint-easylocate-ios` pod in your iOS project, follow the steps below to integrate and utilize the API class provided by the pod.

### Importing the Module

First, import the module at the top of your Swift file:

```swift
import pinpoint_easylocate_ios
```

### API Class Overview

The `API` class provides various functions to interact with nearby tracelets using Bluetooth. Below are the main functions available for public use:

### Singleton Instance

Access the singleton instance of the `API` class:

```swift
let api = API.shared
```

### Scanning for Tracelets

Start scanning for nearby tracelets with a specified timeout. The completion handler returns a list of discovered tracelets.

```swift
api.scan(timeout: 10.0) { tracelets in
    print("Discovered tracelets: \(tracelets)")
}
```

Stop the scanning process:

```swift
api.stopScan()
```

### Connecting to a Tracelet

Connect to a discovered tracelet asynchronously. The function returns a `Bool` indicating success.

```swift
let discoveredTracelets = [...] // This is obtained from the scan() completion handler
if let tracelet = discoveredTracelets.first {
    do {
        let success = try await api.connect(device: tracelet)
        print("Connection success: \(success)")
    } catch {
        print("Connection failed with error: \(error)")
    }
}
```

Connect to a tracelet and start positioning:

```swift
if let tracelet = discoveredTracelets.first {
    do {
        let success = try await api.connectAndStartPositioning(device: tracelet)
        print("Connection and positioning success: \(success)")
    } catch {
        print("Connection and positioning failed with error: \(error)")
    }
}
```

Disconnect from a tracelet:

```swift
api.disconnect()
```

### Listen to local position stream

```swift

let xPos = api.localPosition.xCoord
let yPos = api.localPosition.yCoord
```

Example for SwiftUI:

```swift

        .onAppear {
            // Set initial position
            xPos = api.localPosition.xCoord
            yPos = api.localPosition.yCoord
        }
        .onChange(of: api.localPosition) { newPosition in
            // Update position when localPosition changes
            xPos = newPosition.xCoord
            yPos = newPosition.yCoord
        }

```

### Tracelet Commands

Send a "ShowMe" command to a connected tracelet:

```swift
api.showMe()
```

Start UWB-positioning on a connected tracelet:

```swift
api.startPositioning()
```

Stop UWB-positioning on a connected tracelet:

```swift
api.stopPositioning()
```

Set the communication channel (5 or 9):

```swift
let success = api.setChannel(channel: 5)
print("Channel set success: \(success)")
```

Set the SiteID for the tracelet:

```swift
let success = await api.setSiteID(siteID: 0x0001)
print("SiteID set success: \(success)")
```

Set the positioning interval:

```swift
api.setPositioningInterval(interval: 1) // Interval in n x 250ms, Default: 1 (update every 1 x 259ms)
```

### Retrieving Tracelet Information

Request the status of a connected tracelet:

```swift
if let status = await api.getStatus() {
    print("Tracelet status: \(status)")
}
```


Request the firmware version of a connected tracelet:

```swift
if let version = await api.getVersion() {
    print("Tracelet firmware version: \(version)")
}
```

### Known issues

If you get an error of rsync missing permissions, make sure to update your Xcode project build option ENABLE_USER_SCRIPT_SANDBOXING to 'No'.

![XCode Settings Image](https://i.stack.imgur.com/vqk8D.png)




