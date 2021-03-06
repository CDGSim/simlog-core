//
//  File.swift
//  
//
//  Created by Axel Péju on 16/03/2021.
//

import Foundation

public extension Flight {
    func estimatedMovementTime() -> Date? {
        return SimulationContext.shared?.estimatedDateToRunway(for: self)
    }
    
    func estimatedIAFTime() -> Date? {
        guard let iaf = self.route.last?.fix else {
            return nil
        }
        return SimulationContext.shared?.estimatedDate(at: iaf, for: self)
    }
}
