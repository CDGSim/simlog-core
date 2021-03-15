//
//  DistanceCalculator.swift
//  SimEdit
//
//  Created by Axel Péju on 23/11/2020.
//

import Foundation

struct Coordinates: Equatable {
    var latitude: Double
    var longitude: Double
}

protocol GeographicalPosition {
    var coordinates: Coordinates { get }
}

struct DistanceCalculator {
    // Distance in nautical miles
    static func distance(from origin:GeographicalPosition, to destination:GeographicalPosition) -> Double {
        guard origin.coordinates != destination.coordinates else {
            return 0
        }
        let λA = origin.coordinates.longitude * .pi/180 // in radians
        let λB = destination.coordinates.longitude * .pi/180 // in radians
        let φA = origin.coordinates.latitude * .pi/180 // in radians
        let φB = destination.coordinates.latitude * .pi/180 // in radians
        return 60*acos(sin(φA)*sin(φB) + cos(φA)*cos(φB)*cos(λA - λB)) * 180 / .pi
    }
}

extension Airfield: GeographicalPosition {
    var coordinates: Coordinates {
        Coordinates(latitude: self.latitude ?? 0, longitude: self.longitude ?? 0)
    }
}

extension Fix: GeographicalPosition {
    var coordinates: Coordinates {
        Coordinates(latitude: self.latitude ?? 0, longitude: self.longitude ?? 0)
    }
}
