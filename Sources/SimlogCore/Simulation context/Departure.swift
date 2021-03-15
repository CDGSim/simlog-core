//
//  Departure.swift
//  SimEdit
//
//  Created by Axel Péju on 21/11/2020.
//

import Foundation

struct Departure: Codable, Hashable, Identifiable {
    var id = UUID()
    
    var name: String
    var route: [Leg] = []
    
    private enum CodingKeys : String, CodingKey {
        case name, route
    }
}

// Flight route according to departure route
extension Departure {
    func flightRoute() -> [Leg] {
        // Build the route according to the departure
        return self.route.map({ leg in
            return Leg(fix: leg.fix, speed: leg.maximumSpeed, altitude: leg.minimumAltitude)
        })
    }
}
