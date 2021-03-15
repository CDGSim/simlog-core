//
//  Airfield.swift
//  SimEdit
//
//  Created by Axel Péju on 15/11/2020.
//

import Foundation

struct Airfield: Identifiable, Codable, Hashable {
    var id = UUID()
    
    var name: String
    var latitude: Double?
    var longitude: Double?
    var runways: [Runway]?
    var departures: [Departure]?
    var arrivals: [Arrival]?
    
    private enum CodingKeys : String, CodingKey {
        case name, latitude, longitude, runways, departures, arrivals
    }
}

extension Airfield {
    // Parallel runways belong to a same group
    // Both QFU belong to the same group
    var runwayGroups:[String] {
        var groups:[String] = []
        if let runways = self.runways {
            for runway in runways {
                if let runwayNumber = Int(runway.name.prefix(2)) {
                    let runwayA = runwayNumber > 18 ? runwayNumber - 18 : runwayNumber
                    let runwayB = runwayNumber > 18 ? runwayNumber : runwayNumber + 18
                    let prefix = runwayA < 10 || runwayB < 10 ? "0":""
                    let runwayIdentifier = prefix+"\(runwayA)-\(runwayB)"
                    if !groups.contains(runwayIdentifier) {
                        groups.append(runwayIdentifier)
                    }
                }
            }
        }
        return groups.sorted { a, b in
            a > b
        }
    }
}

extension Airfield {
    func departureRunwayName(for configuration:AirfieldConfiguration, runwayPair: String) -> String {
        let runways = runwayPair.components(separatedBy: "-").map {
            String($0.prefix(2))
        }.sorted()
        switch configuration {
        case .east:
            var runwayName = runways.first!
            if self.name == "LFPG" {
                runwayName += runwayName == "08" ? "L" : "R"
            }
            return runwayName
        case .west:
            var runwayName = runways.last!
            if self.name == "LFPG" {
                runwayName += runwayName == "26" ? "R" : "L"
            }
            return runwayName
        }
    }
    
    func arrivalRunwayName(for configuration:AirfieldConfiguration, runwayPair: String) -> String {
        let runways = runwayPair.components(separatedBy: "-").map {
            String($0.prefix(2))
        }.sorted()
        switch configuration {
        case .east:
            var runwayName = runways.first!
            if self.name == "LFPG" {
                runwayName += runwayName == "08" ? "R" : "L"
            }
            return runwayName
        case .west:
            var runwayName = runways.last!
            if self.name == "LFPG" {
                runwayName += runwayName == "26" ? "L" : "R"
            }
            return runwayName
        }
    }
}

// MARK:- IAFs
// IAFs : determined according to the airfield's arrival
// each arrival is an array of fixes, ending on an IAF

extension Airfield {
    func initialfApproachFixes() -> [String] {
        guard let arrivals = self.arrivals else {
            return []
        }
        return Array(Set(arrivals.compactMap({ arrival in
            return arrival.route.last?.fix
        })))
    }
}
