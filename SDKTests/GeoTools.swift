//
//  GeoTools.swift
//  SDKTests
//
//  Created by Christoph Scherbeck on 12.12.23.
//

import Foundation
import XCTest



@testable import SDK

/// Finish Test Case from Android sdk



class YourTestCase: XCTestCase {

    let DIFF_TOLERANCE = 0.1 // difference as casting tolerance in meters
    let DIFF_TOLERANCE_DEGREE = 0.1 / 110000 // the tolerance in WGS84 degrees

    func testLocalToWorld() {
        let wgs84reference = WGS84Position(refLatitude: 50.8416552, refLongitude: 12.9260823, refAzimuth: 20.0)
        let localPosition = TL_PositionResponse(xCoord: 0.0, yCoord: 24.03, zCoord: 1, siteID: "0x1234")
        // expected
        let wgs84PosExp = WGS84Position(refLatitude: 50.8418581, refLongitude: 12.926199, refAzimuth: 20.0)

        let wgs84PosAct = wgs84reference.getWGS84Position(uwbPosition: CGPoint(x: localPosition.xCoord, y: localPosition.yCoord))

        let latDiff = abs(wgs84PosExp.refLatitude - wgs84PosAct.latitude)
        let lonDiff = abs(wgs84PosExp.refLongitude - wgs84PosAct.longitude)

        // Check if the differences are within tolerance
        if latDiff >= DIFF_TOLERANCE_DEGREE {
            XCTFail("Latitude difference exceeds tolerance by \(latDiff - DIFF_TOLERANCE_DEGREE) degrees. Expected: \(wgs84PosExp.refLatitude), Actual: \(wgs84PosAct.latitude)")
        }

        if lonDiff >= DIFF_TOLERANCE_DEGREE {
            XCTFail("Longitude difference exceeds tolerance by \(lonDiff - DIFF_TOLERANCE_DEGREE) degrees. Expected: \(wgs84PosExp.refLongitude), Actual: \(wgs84PosAct.longitude)")
        }
    }
}

    
//    func testWorldToLocal() {
//        let wgs84reference = WGS84Position(refLatitude: 50.8416552, refLongitude: 12.9260823, refAzimuth: 20.0)
//        
//        let localPosition = TL_PositionResponse(xCoord: 0, yCoord: 24.03, zCoord: 1, siteID: "0x1234")
//        let wgs84Pos = WGS84Position(refLatitude: 50.8418581, refLongitude: 12.926199, refAzimuth: 20.0)
//        
//        let localPositionAct = wgs84reference.convertToLocal(wgs84Pos)
//        
//        let xDiff = abs(localPositionAct.x - localPosition.x)
//        let yDiff = abs(localPositionAct.y - localPositionAct.y)
//        
//        XCTAssertTrue(xDiff < DIFF_TOLERANCE)
//        XCTAssertTrue(yDiff < DIFF_TOLERANCE)
//    }



