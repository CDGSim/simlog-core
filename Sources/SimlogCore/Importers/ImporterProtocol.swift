//
//  ImporterProtocol.swift
//  SimEdit
//
//  Created by Axel Péju on 15/11/2020.
//

import Foundation

public protocol ImporterProtocol {
    var name: String { get }
    mutating func simulation() -> Simulation
    mutating func date() -> Date
    mutating func duration() -> Int
    var flights: [Flight] { mutating get }
    var pressure: Int { get }
    var temperature: Int { get }
}

extension ImporterProtocol {
    public mutating func simulation() -> Simulation {
        return Simulation(name: self.name, date:date(), duration:duration(), flights: self.flights, pressure: self.pressure, temperature: self.temperature)
    }
    
    mutating public func date() -> Date {
        return self.flights.randomElement()?.initialCondition.date ?? Date()
    }
}
