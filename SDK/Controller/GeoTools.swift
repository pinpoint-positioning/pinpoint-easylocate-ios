import Foundation
import CoreLocation
import SwiftUI

public class WGS84Position {
    
    var refLatitude: Double
    var refLongitude: Double
    var refAzimuth: Double
    let equatorialRadius: Double = 6378137.0
    let polarRadius: Double = 6356752.3142
    let meanRadius: Double
    let refAzimuthRadians: Double
    let refLatitudeRadians: Double

    public init(refLatitude: Double, refLongitude: Double, refAzimuth: Double) {
        self.refLatitude = refLatitude
        self.refLongitude = refLongitude
        self.refAzimuth = refAzimuth
        self.meanRadius = (equatorialRadius + polarRadius) / 2
        self.refAzimuthRadians = refAzimuth * Double.pi / 180.0
        self.refLatitudeRadians = refLatitude * Double.pi / 180.0
    }

    public func getWGS84Position(uwbPosition: CGPoint) -> CLLocationCoordinate2D {
        let radiusLat = 1 / sqrt(1 / pow(equatorialRadius, 2) +
                                 pow(tan(Double(refLatitudeRadians)), 2) / pow(polarRadius, 2))
        let deltaX = uwbPosition.x * cos(Double(refAzimuthRadians)) + uwbPosition.y  * sin(Double(refAzimuthRadians))
        let deltaY = -uwbPosition.x * sin(Double(refAzimuthRadians)) + uwbPosition.y * cos(Double(refAzimuthRadians))
        let deltaLon = 360.0 * deltaX / (2 * Double.pi * radiusLat)
        let deltaLat = 360.0 * deltaY / (2 * Double.pi * meanRadius)

        let newLatitude = refLatitude + deltaLat
        let newLongitude = refLongitude + deltaLon

        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
}
