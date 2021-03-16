//
//  Simulation.swift
//  SimEdit
//
//  Created by Axel Péju on 07/11/2020.
//

import Foundation

public struct Simulation : Codable, Equatable {
    var name: String?
    public var date: Date?
    public var duration: Int? // In minutes
    
    var airfieldConfigurationPlans: [AirfieldConfigurationPlan]?
    
    public var flights: [Flight] = []
    
    var pressure: Int?
    var temperature: Int?
    var departureSectors: Bool?
    var arrivalSectors: Bool?
    
    var activatedZones: [String]?
}

