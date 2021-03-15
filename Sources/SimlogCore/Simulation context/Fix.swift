//
//  Fix.swift
//  SimEdit
//
//  Created by Axel Péju on 25/11/2020.
//

import Foundation

struct Fix: Identifiable, Codable, Hashable {
    var id = UUID()
    
    var name: String
    var latitude: Double?
    var longitude: Double?
    
    private enum CodingKeys : String, CodingKey {
        case name, latitude, longitude
    }
}
