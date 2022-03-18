//
//  Context.swift
//  SimEdit
//
//  Created by Axel Péju on 15/11/2020.
//

import Foundation

struct SimulationContext: Codable {
    var name: String
    var airfields: [Airfield]
    var fixes: [Fix]
    
    // Coding
    
    private enum CodingKeys : String, CodingKey {
        case name, airfields, fixes
    }
    
    /// Reads a file named fileName.simulation context and decodes it into a SimulationContext
    private static func contextFromFileNamed(fileName:String) -> SimulationContext? {
        let bundle = Bundle.module
        guard let contextUrl = bundle.url(forResource: fileName, withExtension: "simulationcontext"),
              let data = try? Data(contentsOf: contextUrl) else {
                  return nil
              }
        let decoder = JSONDecoder()
        do {
            let context = try decoder.decode(SimulationContext.self, from: data)
            return context
        } catch {
            return nil
        }
    }
    
    internal init(name: String = "", airfields: [Airfield] = [], fixes: [Fix] = []) {
        self.name = name
        self.airfields = airfields
        self.fixes = fixes
        
        // Read context.simulationcontext and other files
        if var defaultContext = Self.contextFromFileNamed(fileName: "context") {
            for contextFileName in ["LFRS", "LFRZ", "LFBH", "LFRN", "LFPG", "LFPB", "LFPO", "LFPV", "LFPN", "LFOB", "VFR"] {
                if let context = Self.contextFromFileNamed(fileName: contextFileName) {
                    defaultContext.importData(from: context)
                }
            }
            self.importData(from:defaultContext)
        }
    }
    
    mutating func importData(from context:SimulationContext) {
        self.airfields.append(contentsOf: context.airfields)
        self.fixes.append(contentsOf: context.fixes)
        
        self.loadFixesDictionary()
        self.loadAirfieldsDictionary()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.airfields = try container.decode([Airfield].self, forKey: .airfields)
        self.fixes = try container.decode([Fix].self, forKey: .fixes)
        
        self.loadFixesDictionary()
        self.loadAirfieldsDictionary()
    }
    
    // Quick way to access fixes according to their name
    var fixesDictionary: [String:GeographicalPosition] = [:]
    
    private mutating func loadFixesDictionary() {
        var fixesDictionary:[String:GeographicalPosition] = [:]
        fixes.forEach { fix in
            fixesDictionary[fix.name] = fix
        }
        airfields.forEach { airfield in
            fixesDictionary[airfield.name] = airfield
        }
        self.fixesDictionary = fixesDictionary
    }
    
    // Quick way to access fixes according to their name
    var airfieldsDictionary: [String:Airfield] = [:]
    
    private mutating func loadAirfieldsDictionary() {
        var dictionary:[String:Airfield] = [:]
        airfields.forEach { airfield in
            dictionary[airfield.name] = airfield
        }
        self.airfieldsDictionary = dictionary
    }
    
    static var shared: SimulationContext = {
        return SimulationContext()
    }()
}

// MARK:- Arrivals

extension SimulationContext {
    func mostProbableArrival(toRunway destinationRunway:String, ofAirfield destination:Airfield, from origin:Airfield, for iaf:String) -> Arrival? {
        return destination.arrivals?.filter({ arrival -> Bool in
            arrival.route.last?.fix == iaf
        }).filter({ arrival -> Bool in
            arrival.runways.contains(destinationRunway)
        }).sorted(by: { arrivalA, arrivalB -> Bool in
            guard let firstFixNameForA = arrivalA.route.first?.fix, let firstFixNameForB = arrivalB.route.first?.fix else {
                // If any of the route is empty, return true arbitrarily
                return false
            }
            guard let firstFixForA = self.fixesDictionary[firstFixNameForA],
                  let firstFixForB = self.fixesDictionary[firstFixNameForB] else {
                return false
            }
            let distanceToA = DistanceCalculator.distance(from: origin, to:firstFixForA)
            let distanceToB = DistanceCalculator.distance(from: origin, to:firstFixForB)
            return distanceToA < distanceToB
        })
        .first
    }
    
    /// Returns the arrival starting at the point the closest to the origin airfield
    func mostProbableArrival(for flight:Flight) -> Arrival? {
        guard let originAirfield = airfieldsDictionary[flight.origin],
           let destinationAirfield = airfieldsDictionary[flight.destination],
           let iaf = flight.route.last?.fix,
           let destinationRunway = flight.destinationRunway else {
            return nil
        }
        return self.mostProbableArrival(toRunway: destinationRunway, ofAirfield: destinationAirfield, from: originAirfield, for: iaf)
    }
    
    func possibleArrivals(for flight:Flight) -> [Arrival] {
        guard let destinationAirfield = airfieldsDictionary[flight.destination],
           let iaf = flight.route.last?.fix,
           let destinationRunway = flight.destinationRunway else {
            return []
        }
        return destinationAirfield.arrivals?.filter { $0.route.last?.fix == iaf }
            .filter { $0.runways.contains(destinationRunway)} ?? []
    }
}

// MARK:- Distance Calculation

extension SimulationContext {
    
    /// Total distance of the route of the specified flight
    func routeDistance(for flight:Flight) -> Double {
        return self.totalDistance(of: flight.route)
    }
    
    func totalDistance(of route:[Leg]) -> Double {
        var distance: Double = 0
        guard let firstFixName = route.first?.fix else {
            return 0
        }
        guard let startFix = self.fixesDictionary[firstFixName] else {
            return 0
        }
        var currentFix = startFix
        for leg in route {
            if let fix = self.fixesDictionary[leg.fix] {
                distance += DistanceCalculator.distance(from: currentFix, to: fix)
                currentFix = fix
            }
        }
        return distance
    }
    
}
 
extension SimulationContext {
}

// Flight route according to arrival procedure
extension SimulationContext {
    
    func flightRoute(from arrival:Arrival, startAltitude:Altitude = Altitude.flightLevel(350), aircraftType:String) -> [Leg] {
        var currentAltitude = startAltitude
        let propeller = aircraftType.isPropeller
        let slowJets = ["C25C", "C550", "C525"]
        let canSetSpeed = !propeller && !slowJets.contains(aircraftType) // Do not change speed for these aircraft
        let currentSpeed = 350
        
        // Build the route according to the arrival's constraints
        return arrival.route.map({ leg in
            // For each leg in the arrival's route, determine if we should descend and reduce speed
            // according to future constraints along the route
            
            var speed: Int? = nil
            var altitude: Altitude? = nil
            
            // Check the rest of the route for altitude constraints
            checkFollowingRoute: if let legIndex = arrival.route.firstIndex(of: leg) {
                guard legIndex < arrival.route.count - 1 else {
                    // We are at the end of the route
                    
                    if let maximumAltitude = leg.maxAltitude(for: aircraftType) {
                        if currentAltitude > maximumAltitude {
                            altitude = maximumAltitude
                        }
                    }
                    break checkFollowingRoute
                }
                
                // Check next leg for a speed constraint
                if let maximumSpeed = leg.maximumSpeed, canSetSpeed {
                    speed = min(maximumSpeed, currentSpeed)
                }
                
                // Starting with the last leg of the route,
                // check if we can wait for the next fix to descend
                // otherwhise descend now
                
                for followingLeg in arrival.route.reversed() {
                    guard followingLeg != leg else {
                        // We have reached the current leg
                        if let maximumAltitude = followingLeg.maxAltitude(for: aircraftType) {
                            if  currentAltitude > maximumAltitude {
                                altitude = maximumAltitude
                                currentAltitude = maximumAltitude
                            }
                        }
                        break
                    }
                    if let maximumAltitude = followingLeg.maxAltitude(for: aircraftType) {
                        guard currentAltitude > maximumAltitude else {
                            break checkFollowingRoute
                        }
                        // There is an altitude contraint at the end of this leg
                        let truncatedRoute = arrival.route.enumerated().compactMap { (index, leg) -> Leg? in
                            // if followingLeg is the last leg of the arrival, make sure we can make the constraint earlier
                            // In practice, ATCs will not be able to give a clearance for the last leg
                            let correctionFactor = arrival.route.reversed().firstIndex(of: followingLeg) == 0 ? 2 : 0
                            if index >= legIndex - 1 && index <= arrival.route.firstIndex(of: followingLeg)! - correctionFactor {
                                return leg
                            }
                            return nil
                        }
                        let distanceFromNextLegFixToFixWithConstrain = self.totalDistance(of: truncatedRoute)
                        switch currentAltitude {
                        case .flightLevel(let currentFL):
                            switch maximumAltitude {
                            case .flightLevel(let maxFL):
                                let delta = Double((currentFL - maxFL)*100)
                                if delta/distanceFromNextLegFixToFixWithConstrain > Double(260) {
                                    altitude = maximumAltitude
                                    currentAltitude = maximumAltitude
                                    break checkFollowingRoute
                                }
                            default:
                                break
                            }
                        default:
                            break
                        }
                    }
                }
            }
            
            return Leg(fix: leg.fix, speed: speed, altitude: altitude)
        })
    }
}
