//
//  ElectraImporter.swift
//  SimEdit
//
//  Created by Axel Péju on 13/11/2020.
//

import Foundation

public struct ElectraImporter {
    public init(content: String) {
        self.content = content
    }
    
    private (set) var content: String
    
    private let simulationContext = SimulationContext.shared
    
    // Scans a line from the file and returns a key and its value
    private func keyAndValue(from line:String) -> (String, String) {
        var keyScanned = false
        var key: String = ""
        var value: String = ""
        for character in line {
            if !keyScanned {
                if character != ">" && character != "<" {
                    key.append(character)
                }
                else if character == ">" {
                    key = key.trimmingCharacters(in: .whitespaces)
                    keyScanned = true
                }
            }
            else {
                value.append(character)
            }
        }
        return (key, value)
    }
}

extension ElectraImporter: ImporterProtocol {
    public var name: String {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let keyAndValue = self.keyAndValue(from:line)
            let key = keyAndValue.0
            let value = keyAndValue.1
            
            let values = value.trimmingCharacters(in: .whitespaces).split(separator: ";")
            
            if key == "EXERCICE" {
                if let nameSubstring = values.first {
                    return String(nameSubstring)
                }
            }
        }
        return "Simulation ELECTRA"
    }
    
    public func date() -> Date {
        var date = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        
        self.scanContentAndForEachLine { (key, values) in
            if key == "DATES" {
                if let dateSubtring = values.last, let timeSubstring = values.first {
                    let simulationDateString = String(dateSubtring)+" "+String(timeSubstring)
                    if let parsedDate = dateFormatter.date(from: simulationDateString) {
                        date = parsedDate
                    }
                }
            }
        }
        
        return date
    }
    
    public mutating func duration() -> Int {
        var duration = 120 // Default value
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "HH:mm"
        
        self.scanContentAndForEachLine { (key, values) in
            if key == "DATES" {
                if values.count > 2 {
                    let startTime = values[0]
                    let endTime = values[1]
                    if let startDate = dateFormatter.date(from: startTime), let endDate = dateFormatter.date(from: endTime) {
                        duration = Int(endDate.timeIntervalSince(startDate))/60
                    }
                }
            }
        }
        
        return duration
    }
    
    public var flights: [Flight] {
        func appendCurrentFlight() {
            if let current = currentFlight, let callsign = current["callsign"], let aircraftType = current["aircraftType"] {
                // Create a flight from the elements of currentFlight and add it to the flights array
                var flight = Flight(callsign: callsign, aircraftType: aircraftType)
                
                // Origin
                if let origin = current["origin"] {
                    flight.origin = origin
                    
                    if let runway = current["departureRunway"], let runwayLetter = current["departureRunwayLetter"] {
                        if runwayLetter != "N" {
                            flight.departureRunway = runway+runwayLetter
                        }
                        else {
                            flight.departureRunway = runway
                        }
                        if let timeString = current["time"],
                           let date = dateFormatter.date(from: simulationDateString+" "+timeString) {
                            let initialPosition = origin+".RWY."+flight.departureRunway!
                            
                            let initialAltitude: Altitude
                            if let initialAltitudeString = currentFlight?["initialAltitude"] {
                                let index = initialAltitudeString.index(initialAltitudeString.startIndex, offsetBy: 1)
                                if initialAltitudeString.first == "A", let altitude = Int(initialAltitudeString[index...]) {
                                    initialAltitude = .altitude(altitude*100)
                                } else if let flightLevel = Int(initialAltitudeString) {
                                    initialAltitude = .flightLevel(flightLevel)
                                } else {
                                    initialAltitude = .flightLevel(260)
                                }
                            } else {
                                initialAltitude = .flightLevel(260)
                            }
                            
                            flight.initialCondition = .init(date: date, position: initialPosition, altitude:initialAltitude)
                            
                        }
                    }
                }
                
                if let firstFix = current["firstFix"], let initialAltitudeString = currentFlight?["initialAltitude"] {
                    let initialAltitude:Altitude
                    if initialAltitudeString.first == "A", let altitude = Int(initialAltitudeString.suffix(1)) {
                        initialAltitude = .altitude(altitude*100)
                    }
                    else if let flightLevel = Int(initialAltitudeString) {
                        initialAltitude = .flightLevel(flightLevel)
                    } else {
                        initialAltitude = .flightLevel(260)
                    }
                    
                    if let timeString = current["time"], var date = dateFormatter.date(from: simulationDateString+" "+timeString) {
                        if let setupFix = current["setupFix"] {
                            // Get the route
                            var route = [Leg]()
                            if let fixes = current["fixes"] {
                                var speeds: [Int?]? = nil
                                if let speedSubstrings = current["speeds"] {
                                    speeds = speedSubstrings.components(separatedBy:";").map { substring in
                                        Int(String(substring))
                                    }
                                }
                                
                                let fixesStrings = fixes.components(separatedBy:";")
                                for (index, fix) in fixesStrings.enumerated() {
                                    var step = Leg(fix: String(fix.replacingOccurrences(of: "0", with: "O")))
                                    if let speeds = speeds, speeds.count >= fixesStrings.count, index >= 1,  let speed = speeds[index - 1] {
                                        step.speed = speed
                                    }
                                    route.append(step)
                                    if fix == setupFix {
                                        break
                                    }
                                }
                            }
                            date = date.addingTimeInterval(-(simulationContext?.timeIntervalToFly(route: route) ?? 0))
                        }
                        flight.initialCondition = .init(date: date, position: firstFix, altitude:initialAltitude)
                    }
                }
                
                // Destination
                if let destination = current["destination"] {
                    flight.destination = destination
                    
                    // Destination runway
                    if let runway = current["destinationRunway"], let runwayLetter = current["destinationRunwayLetter"] {
                        if runwayLetter != "N" {
                            flight.destinationRunway = runway+runwayLetter
                        }
                        else {
                            flight.destinationRunway = runway
                        }
                    }
                }
                
                if let fixes = current["fixes"] {
                    var speeds: [Int?]? = nil
                    if let speedSubstrings = current["speeds"] {
                        speeds = speedSubstrings.components(separatedBy:";").map { substring in
                            Int(String(substring))
                        }
                    }
                    
                    speeds?.removeLast()
                    speeds?.insert(nil, at: 0)
                    
                    var altitudes: [Altitude?]? = nil
                    if let altitudesSubstrings = current["altitudes"] {
                        altitudes = altitudesSubstrings.components(separatedBy:";").map { substring in
                            let altitudeString = String(substring)
                            if altitudeString.first == "A" {
                                let numericString = altitudeString.suffix(1)
                                if let altitude = Int(numericString) {
                                    return .altitude(altitude*10)
                                }
                            }
                            else if altitudeString.count > 0 {
                                if let flightLevel = Int(altitudeString) {
                                    return .flightLevel(flightLevel)
                                }
                            }
                            return nil
                        }
                    }
                    
                    altitudes?.removeLast()
                    altitudes?.insert(nil, at: 0)
                    
                    let fixesStrings = fixes.components(separatedBy:";")
                    for (index, fix) in fixesStrings.enumerated() {
                        var step = Leg(fix: String(fix.replacingOccurrences(of: "0", with: "O")))
                        if let speeds = speeds, speeds.count >= fixesStrings.count, let speed = speeds[index] {
                            step.speed = speed
                        }
                        if let altitudes = altitudes, altitudes.count >= fixesStrings.count, let altitude = altitudes[index] {
                            step.altitude = altitude
                        }
                        flight.route.append(step)
                    }
                }
                flights.append(flight)
            }
        }
        
        var flights: [Flight] = []
        
        let lines = content.components(separatedBy: .newlines)
        
        var simulationDateString: String = ""
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
        
        var currentFlight: [String:String]? = nil
        
        for line in lines {
            guard line.trimmingCharacters(in: .whitespaces).first != "#" else { // Line is a comment
                continue
            }
            guard line.count > 0 else {
                continue
            }
            // Parse the key and the value
            let keyAndValue = self.keyAndValue(from:line)
            let key = keyAndValue.0
            let value = keyAndValue.1
            
            let values = value.trimmingCharacters(in: .whitespaces).split(separator: ";")
            
            if key == "DATES" {
                if let dateSubtring = values.last {
                    simulationDateString = String(dateSubtring)
                }
            }
            
            if key == "PLN" {
                appendCurrentFlight()
                
                // Start a new flight
                currentFlight = [String:String]()
                
                for (index, substring) in values.enumerated() {
                    let string = String(substring)
                    if index == 0 {
                        currentFlight?["callsign"] = string
                    }
                    else if index == 1 {
                        currentFlight?["aircraftType"] = string
                    }
                    else if index == 2 {
                        currentFlight?["origin"] = string
                    }
                    else if index == 3 {
                        currentFlight?["destination"] = string
                    }
                    else if index == 4 {
                        currentFlight?["time"] = string
                    }
                }
            }
            
            if key == "NIVEAUX" {
                for (index, substring) in values.enumerated() {
                    let string = String(substring)
                    if index == 1 {
                        currentFlight?["initialAltitude"] = string
                    }
                }
            }
            
            if key == "DEPART_TERRAIN" {
                for (index, substring) in values.enumerated() {
                    let string = String(substring)
                    if index == 1 {
                        currentFlight?["departureRunway"] = string
                    }
                    else if index == 2 {
                        currentFlight?["departureRunwayLetter"] = string
                    }
                }
            }
            
            if key == "ARRIVEE_TERRAIN" {
                for (index, substring) in values.enumerated() {
                    let string = String(substring)
                    if index == 1 {
                        currentFlight?["destinationRunway"] = string
                    }
                    else if index == 2 {
                        currentFlight?["destinationRunwayLetter"] = string
                    }
                }
            }
            
            if key == "DEPART_BALISE" {
                currentFlight?["firstFix"] = value.trimmingCharacters(in: .whitespaces)
            }
            
            if key == "BALISES" {
                currentFlight?["fixes"] = value.trimmingCharacters(in: .whitespaces)
            }
            
            if key == "FL_BALISES" {
                currentFlight?["altitudes"] = value.trimmingCharacters(in: .whitespaces)
            }
            
            if key == "VI_BALISES" {
                currentFlight?["speeds"] = value.trimmingCharacters(in: .whitespaces)
            }
            
            if key == "CALAGE_BALISE" {
                currentFlight?["setupFix"] = value.trimmingCharacters(in: .whitespaces)
            }
        }
        
        appendCurrentFlight()
        return flights
    }
    
    public var pressure: Int {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let keyAndValue = self.keyAndValue(from:line)
            let key = keyAndValue.0
            let value = keyAndValue.1
            
            let values = value.trimmingCharacters(in: .whitespaces).split(separator: ";")
            
            if key == "METEO_GLOBALE" {
                if let pressure = Int(values[1]) {
                    return pressure
                }
            }
        }
        return 999
    }
    
    public var temperature: Int {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let keyAndValue = self.keyAndValue(from:line)
            let key = keyAndValue.0
            let value = keyAndValue.1
            
            let values = value.trimmingCharacters(in: .whitespaces).split(separator: ";")
            
            if key == "METEO_GLOBALE" {
                if let pressure = Int(values[0]) {
                    return pressure
                }
            }
        }
        return 999
    }
    
    private func scanContentAndForEachLine(_ handler: (String, [String]) -> Void) {
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            guard line.trimmingCharacters(in: .whitespaces).first != "#" else { // Line is a comment
                continue
            }
            guard line.count > 0 else {
                continue
            }
            // Parse the key and the value
            let keyAndValue = self.keyAndValue(from:line)
            let key = keyAndValue.0
            let value = keyAndValue.1
            
            let values = value.trimmingCharacters(in: .whitespaces).split(separator: ";").map { String($0) }
            
            handler(key, values)
        }
    }
    
    mutating func configurations() -> [String:String] {
        var configurations = [String:String]()
        
        self.scanContentAndForEachLine { (key, values) in
            if key == "CONFIG_PISTE" {
                if values.count >= 2 {
                    let airfieldName = values[0]
                    let configurationLetter = values[1]
                    configurations[airfieldName] = configurationLetter
                }
            }
        }
        
        return configurations
    }
}
