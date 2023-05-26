//
//  GeoTools.swift
//  SDK
//
//  Created by Christoph Scherbeck on 25.04.23.
//

import Foundation
import Combine

// In progress

// WGS 84 parameters: see http://www.jpz.se/Html_filer/wgs_84.html
let RADIUS_EQUATORIAL = 6378137.0; // in meters
let RADIUS_POLAR = 6356752.3142; // in meters
let RADIUS_MEAN = (RADIUS_EQUATORIAL + RADIUS_POLAR) / 2;
let M_PER_DEGREE = 110000; // meters per 1 degree WGS

/// This class encapsulate a reference point in WGS 84 coordinate that can be used for
/// coordinate transformation from and to WGS 84 coordinates.
 public class Wgs84Reference: ObservableObject {
    
    public static let shared = Wgs84Reference()
    lazy var latRef = Double()
    lazy var lonRef = Double()
    lazy var aziRef = Double()
    lazy var aziRadians = deg2rad(aziRef);
    lazy var radiusLat = 1 / sqrt(1 / pow(RADIUS_EQUATORIAL, 2) +
                                  pow(tan(deg2rad(latRef)), 2) / pow(RADIUS_POLAR, 2));
    
    
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    /// Constructs the [Wgs84Reference]
    ///
    /// [latRef] latitude of the reference point
    /// [lonRef] longitude of the reference point
    /// [aziRef] azimuth of the reference point. This describes the angle in degrees between
    
    
    /// Converts the given [LocalPosition] with the [Wgs84Reference] to a [Wgs84Position]
    ///
    /// Returns a position as [Wgs84Position] object
     func convertToWgs84(position: TL_PositionResponse ) -> Wgs84Position {
        var deltaX =
        position.xCoord * cos(aziRadians) + position.yCoord * sin(aziRadians);
        var deltaY =
        -position.xCoord * sin(aziRadians) + position.yCoord * cos(aziRadians);
        
        var deltaLon = 360.0 * deltaX / (2 * .pi * radiusLat);
        var deltaLat = 360.0 * deltaY / (2 * .pi * RADIUS_MEAN);
        
        return Wgs84Position(lat: latRef + deltaLat, lon: lonRef + deltaLon, alt: position.zCoord,
                             covXx: position.covXx, covXy: position.covXy, covYy: position.covYy, siteID: position.siteID);
    }
    

    /// Converts the given [Wgs84Position] with the [Wgs84Reference] to a [LocalPosition]
    ///
    /// Returns a position as [LocalPosition] object
    //  LocalPosition convertToLocal(Wgs84Position wgs84Position) {
    //    var deltaX = (wgs84Position.lon - lonRef) / 360.0 * (2 * pi * radiusLat);
    //    var deltaY = (wgs84Position.lat - latRef) / 360.0 * (2 * pi * RADIUS_MEAN);
    //
    //    var x = deltaX * cos(-aziRadians) + deltaY * sin(-aziRadians);
    //    var y = -deltaX * sin(-aziRadians) + deltaY * cos(-aziRadians);
    //
    //    return LocalPosition(x, y, wgs84Position.z,
    //        wgs84Position.covXx, wgs84Position.covXy, wgs84Position.covYy, wgs84Position.siteId);
    //  }
    //
    //}
}
