//
//  AirfieldConfiguration.swift
//  SimEdit
//
//  Created by Axel Péju on 15/11/2020.
//

import Foundation

enum AirfieldConfiguration : String, Codable {
    case west = "west"
    case east = "east"
}

struct AirfieldConfigurationChange : Codable, Equatable {
    var id = UUID()
    var date: Date
    var configuration: AirfieldConfiguration
    
    // Do not encode id, as it is used only by the application to uniquely identify configurations
    private enum CodingKeys : String, CodingKey {
        case date, configuration
    }
}
