//
//  InitialCondition.swift
//  SimEdit
//
//  Created by Axel Péju on 14/11/2020.
//

import Foundation

public struct InitialCondition: Codable, Hashable {
    public var date: Date
    
    // URL style encoded string
    // ie: LFPG.RWY.26R, LORNI, LFPG.PKG.A38
    public var position: String
    
    // Speed in knots
    public var speed: Int?
    
    public var altitude: Altitude
}
