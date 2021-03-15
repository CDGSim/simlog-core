//
//  Route.swift
//  SimEdit
//
//  Created by Axel Péju on 07/11/2020.
//

import Foundation

public struct Leg: Identifiable, Codable, Hashable {
    public var id = UUID()
    public var fix:String
    public var speed:Int?
    public var altitude:Altitude?
    
    // Constraints
    public var maximumSpeed:Int?
    public var maximumAltitude:Altitude?
    public var minimumAltitude:Altitude?
    public var maximumAltitudeForPropellers:Altitude?
    public var minimumAltitudeForPropellers:Altitude?
    
    // Do not encode id, as it is used only by the application to uniquely identify flights
    private enum CodingKeys : String, CodingKey {
        case fix, speed, altitude, maximumSpeed, maximumAltitude, minimumAltitude, maximumAltitudeForPropellers, minimumAltitudeForPropellers
    }
}

extension Leg: Equatable {
    public static func == (lhs: Leg, rhs: Leg) -> Bool {
        return
            lhs.fix == rhs.fix &&
            lhs.speed == rhs.speed &&
            lhs.altitude == rhs.altitude
    }
}

public enum Altitude {
    case flightLevel(Int), altitude(Int)
}

extension Altitude: Codable {
    private enum CodingKeys: String, CodingKey {
            case flightLevel
            case altitude
    }

    enum PostTypeCodingError: Error {
        case decoding(String)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? values.decode(Int.self, forKey: .flightLevel) {
            self = .flightLevel(value)
            return
        }
        if let value = try? values.decode(Int.self, forKey: .altitude) {
            self = .altitude(value)
            return
        }
        throw PostTypeCodingError.decoding("Whoops! \(dump(values))")
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .flightLevel(let value):
            try container.encode(value, forKey: .flightLevel)
        case .altitude(let value):
            try container.encode(value, forKey: .altitude)
        }
    }
}

extension Altitude: Hashable {
}

extension Altitude: Comparable {
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.absoluteValue() < rhs.absoluteValue()
    }
    
    func absoluteValue() -> Int {
        switch self {
        case .altitude(let altitude):
            return altitude
        case .flightLevel(let fl):
            return fl*100
        }
    }
}

extension Leg {
    func maxAltitude(for aircraftType:String) -> Altitude? {
        var maxAltitude: Altitude? = nil
        if Flight.propellers.contains(aircraftType) {
            maxAltitude = self.maximumAltitudeForPropellers
        }
        if maxAltitude == nil {
            maxAltitude = self.maximumAltitude
        }
        return maxAltitude
    }
}
