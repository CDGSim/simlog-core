//
//  AirfieldConfigurationPlan.swift
//  SimEdit
//
//  Created by Axel Péju on 15/11/2020.
//

import Foundation

struct AirfieldConfigurationPlan : Codable, Equatable {
    var id = UUID()
    var airfield: String
    var configurationChanges: [AirfieldConfigurationChange]
    
    // Do not encode id, as it is used only by the application to uniquely identify configuration plan
    private enum CodingKeys : String, CodingKey {
        case airfield, configurationChanges
    }
}
