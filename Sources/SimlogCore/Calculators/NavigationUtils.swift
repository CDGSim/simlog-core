//
//  DistanceCalculator.swift
//  SimEdit
//
//  Created by Axel Péju on 23/11/2020.
//

import Foundation

struct Coordinates: Equatable, Hashable {
    var latitude: Double
    var longitude: Double
}

protocol GeographicalPosition {
    var coordinates: Coordinates { get }
}

struct DistanceCalculator {
    struct DistanceDefinition : Hashable {
        static func == (lhs: DistanceCalculator.DistanceDefinition, rhs: DistanceCalculator.DistanceDefinition) -> Bool {
            lhs.origin.coordinates == rhs.origin.coordinates && lhs.destination.coordinates == rhs.destination.coordinates
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.origin.coordinates)
            hasher.combine(self.destination.coordinates)
        }
        
        var origin: GeographicalPosition
        var destination: GeographicalPosition
    }
    
    // Cache
    static private var _distanceCache = [DistanceDefinition: Double]()
    
    // Distance in nautical miles
    static func distance(from origin:GeographicalPosition, to destination:GeographicalPosition) -> Double {
        let definition = DistanceDefinition(origin: origin, destination: destination)
        if let distance = _distanceCache[definition] {
            return distance
        }
        guard origin.coordinates != destination.coordinates else {
            return 0
        }
        let λA = origin.coordinates.longitude * .pi/180 // in radians
        let λB = destination.coordinates.longitude * .pi/180 // in radians
        let φA = origin.coordinates.latitude * .pi/180 // in radians
        let φB = destination.coordinates.latitude * .pi/180 // in radians
        let distance = 60*acos(sin(φA)*sin(φB) + cos(φA)*cos(φB)*cos(λA - λB)) * 180 / .pi
        //_distanceCache[definition] = distance
        return distance
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

struct TrackCalculator {
    static func track(from origin:GeographicalPosition, to destination:GeographicalPosition) -> Int {
        let λA = origin.coordinates.longitude * .pi/180 // in radians
        let λB = destination.coordinates.longitude * .pi/180 // in radians
        let φA = origin.coordinates.latitude * .pi/180 // in radians
        let φB = destination.coordinates.latitude * .pi/180 // in radians
        
        guard λA != λB else {
            return λA > λB ? 180 : 360
        }
        
        let cotanR0 = cos(φA)*tan(φB)/sin(λB-λA)-sin(φA)/tan(λB-λA)
        var R0 = Int(atan(1/cotanR0) * 180 / .pi)
        
        if φB-φA < -5*pow(10,-5) {
            R0 = R0 - 180
        }
        while R0 <= 0 {
            R0 = R0 + 360
        }
        while R0 > 360 {
            R0 = R0 - 360
        }
        return R0
    }
}
