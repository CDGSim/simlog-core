//
//  File.swift
//  
//
//  Created by Axel Péju on 16/03/2021.
//

import Foundation

public extension Flight {
    func estimatedMovementTime() -> Date? {
        if let estimateAtRunway = self.estimateAtRunway {
            return estimateAtRunway
        }
        return EstimateCalculator().estimatedDateToRunway(for: self)
    }
    
    func estimatedIAFTime() -> Date? {
        guard let iaf = self.route.last?.fix else {
            return nil
        }
        return try? EstimateCalculator().estimatedDate(at: iaf, for: self)
    }
}
