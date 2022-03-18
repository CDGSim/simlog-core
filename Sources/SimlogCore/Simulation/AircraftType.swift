//
//  AircraftType.swift
//  SimEdit
//
//  Created by Axel Péju on 29/11/2021.
//

import Foundation

public typealias AircraftType = String

extension AircraftType {
    public enum WakeTurbulenceCategory {
        case superHeavy
        case upperHeavy
        case lowerHeavy
        case upperMedium
        case lowerMedium
        case light
    }
    
    // Private list of aircraft types according to their RECAT wake turbulence category
    // S : super heavy
    // G : upper heavy
    // H : lower heavy
    // K : upper medium, this list is not explicitely defined as this is considered the default case
    // M : lower medium
    // L : light
    private static let superHeavyAircraft: [AircraftType] = ["A388"]
    private static let upperHeavyAircraft: [AircraftType] = ["A332", "A333", "A339", "A342", "A343", "A345", "A346", "A359",
                                                             "B742", "B744", "B748", "B772", "B773", "B77L", "B77W", "B788", "B789", "B78X",
                                                             "C5", "C5M"]
    private static let lowerHeavyAircraft: [AircraftType] = ["A306", "A30B", "A310",
                                                            "B762", "B763", "B764",
                                                             "C17", "DC10", "K35R", "MD11"]
    private static let lowerMediumAircraft: [AircraftType] = ["AT43", "AT72", "CL60", "CRJ1", "CRJ2", "CRJ7", "CRJ9", "CRJX",
                                                              "DH8A", "DH8B", "DH8C", "E135", "E145", "E170", "E45X", "E75S",
                                                              "F16", "F900", "FA7X", "GLF2", "GLF3", "GLF4", "SB20", "SF34"]
    private static let lightAircraft: [AircraftType] = ["B190", "BE10", "BE20", "BE40", "BE58", "B350", "BE99",
                                                        "C560", "C56X", "C680", "C750", "CL30", "C208", "C210", "C25A", "C25B",
                                                        "C525", "C550", "E120", "F2TH", "FA50", "GALX", "H25B", "LJ31", "SW4",
                                                        "P180", "PA31", "PC12", "SR22", "SW3"]
    
    // Propellers
    public static let propellers = ["P180", "AT72", "AT43", "AT72", "AT73", "DH8D", "C172", "DA42", "P28T", "BE33", "PC12", "D228", "BE9L", "BE20"]
    
    public var isPropeller: Bool {
        Self.propellers.contains(self)
    }
    
    public var wtc: WakeTurbulenceCategory {
        if Self.superHeavyAircraft.contains(self) {
            // S
            return .superHeavy
        } else if Self.upperHeavyAircraft.contains(self) {
            // G
            return .upperHeavy
        } else if Self.lowerHeavyAircraft.contains(self) {
            // H
            return .lowerHeavy
        } else if Self.lowerMediumAircraft.contains(self) {
            // K
            return .lowerMedium
        }
        else if Self.lightAircraft.contains(self) {
            // L
            return .light
        }
        else {
            // Default is K
            return .upperMedium
        }
    }
    
    // Convenience properties for non RECAT WTC
    
    public var isSuper: Bool {
        self.wtc == .superHeavy
    }
    
    public var isHeavy: Bool {
        self.wtc == .upperHeavy || self.wtc == .lowerHeavy
    }
    
    public var isMedium: Bool {
        self.wtc == .upperMedium || self.wtc == .lowerMedium
    }
    
    public var isLight: Bool {
        self.wtc == .light
    }
}
