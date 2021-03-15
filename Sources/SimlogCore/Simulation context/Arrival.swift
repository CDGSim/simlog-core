//
//  Arrival.swift
//  SimEdit
//
//  Created by Axel Péju on 21/11/2020.
//

import Foundation

struct Arrival: Codable, Hashable, Identifiable {
    var id = UUID()
    
    var name: String
    var runways: [String]
    var route: [Leg] = []
    
    private enum CodingKeys : String, CodingKey {
        case name, runways, route
    }
}
