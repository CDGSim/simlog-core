//
//  Flight.swift
//  SimEdit
//
//  Created by Axel Péju on 07/11/2020.
//

import Foundation

public struct Flight: Identifiable, Codable, Hashable, Equatable {
    public var id = UUID()
    public var callsign:String
    public var aircraftType: AircraftType
    public var origin:String = ""
    public var departureRunway:String?
    public var destination:String = ""
    public var destinationRunway:String?
    @DecodableFlightRule public  var flightRule: FlightRule
    public var ssrCode: String?
    public var route:[Leg] = []
    public var initialCondition: InitialCondition = .init(date: Date(), position: "", altitude: .flightLevel(260))
    
    // Do not encode id, as it is used only by the application to uniquely identify flights
    private enum CodingKeys : String, CodingKey {
        case callsign, aircraftType, origin, destination, route, departureRunway, destinationRunway, flightRule, ssrCode = "ssr_code", initialCondition
    }
}

extension Flight {
    static let propellers = ["P180", "AT72", "AT43", "DH8D", "C172", "DA42", "P28T", "BE33", "PC12", "D228"]
    
    var isPropeller: Bool {
        Self.propellers.contains(self.aircraftType)
    }
}

// MARK: - Flight Rule

public enum FlightRule: String, Codable {
    case VFR = "vfr", IFR = "ifr"
}

@propertyWrapper
public struct DecodableFlightRule {
    public init(wrappedValue: FlightRule = .IFR) {
        self.wrappedValue = wrappedValue
    }
    
    public var wrappedValue: FlightRule = .IFR
}

extension DecodableFlightRule: Hashable {
}

extension DecodableFlightRule: Equatable {
}

extension DecodableFlightRule: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(FlightRule.self)
    }
}

extension DecodableFlightRule: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }
}

extension KeyedDecodingContainer {
    func decode(_ type: DecodableFlightRule.Type, forKey key: Key) throws -> DecodableFlightRule {
        try decodeIfPresent(type, forKey: key) ?? .init()
    }
}
