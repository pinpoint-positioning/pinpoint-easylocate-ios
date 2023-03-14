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
            
            textOutput = "X: \(xPos) Y: \(yPos) Z: \(zPos) siteID: \(siteId)\n\n"
            
        }
    }
    
