//
//  Context.swift
//  SimEdit
//
//  Created by Axel Péju on 15/11/2020.
//

import Foundation

struct SimulationContext: Codable {
    var name: String
    var airfields: [Airfield]?
    var fixes: [Fix]?
    
    private enum CodingKeys : String, CodingKey {
        case name, airfields, fixes
    }
    
    static let shared: SimulationContext? = loadFromBundle()
    
    static func loadFromBundle() -> SimulationContext? {
        let bundle = Bundle.module
        if let contextUrl = bundle.url(forResource: "context", withExtension: "simulationcontext") {
            if let data = try? Data(contentsOf: contextUrl) {
                let decoder = JSONDecoder()
                if let context = try? decoder.decode(SimulationContext.self, from: data) {
                    return context
                }
            }
        }
        return nil
    }
    
    internal init(name: String, airfields: [Airfield]? = nil, fixes: [Fix]? = nil) {
        self.name = name
        self.airfields = airfields
        self.fixes = fixes
        
        self.loadFixesDictionary()
        self.loadAirfieldsDictionary()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.airfields = try container.decode([Airfield]?.self, forKey: .airfields)
        self.fixes = try container.decode([Fix]?.self, forKey: .fixes)
        
        self.loadFixesDictionary()
        self.loadAirfieldsDictionary()
    }
    
    // Quick way to access fixes according to their name
    var fixesDictionary: [String:Fix] = [:]
    
    private mutating func loadFixesDictionary() {
        var fixesDictionary:[String:Fix] = [:]
        fixes?.forEach { fix in
            fixesDictionary[fix.name] = fix
        }
        self.fixesDictionary = fixesDictionary
    }
    
    // Quick way to access fixes according to their name
    var airfieldsDictionary: [String:Airfield] = [:]
    
    private mutating func loadAirfieldsDictionary() {
        var dictionary:[String:Airfield] = [:]
        airfields?.forEach { airfield in
            dictionary[airfield.name] = airfield
        }
        self.airfieldsDictionary = dictionary
    }
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
}

// MARK:- Estimates

extension SimulationContext {
    
    // Hard coded times
    // TODO: calculate time according to procedure's distance
    // and aircraft speed
    private var times: [String:[String:[String:Int]]] {
        var timesLFPG:[String:[String:Int]] = [:]
        timesLFPG["LORNI"] = ["27":775, "26":760, "09":1125, "08":1150]
        timesLFPG["MOPAR"] = ["27":1170, "26":970, "09":745, "08":730]
        timesLFPG["MOBRO"] = ["27":1335, "26":1340]
        timesLFPG["BANOX"] = ["27":1360, "26":1300, "09":865, "08":915]
        timesLFPG["OKIPA"] = ["27":870, "26":845, "09":1315, "08":1325]
        
        var timesLFPB:[String:[String:Int]] = [:]
        timesLFPB["MOBRO"] = ["27":1345]
        timesLFPB["KOLIV"] = ["07":760]
        timesLFPB["VEBEK"] = ["07":1300, "27":855]
        timesLFPB["OKABO"] = ["07":1140, "27":875]
        timesLFPB["BANOX"] = ["07":710, "27":1310]
        
        var timesLFOB:[String:[String:Int]] = [:]
        timesLFOB["IPNOB"] = ["30":980,"12":1320]
        timesLFOB["LORNI"] = ["30":960,"12":1190]
        
        var timesLFPO:[String:[String:Int]] = [:]
        timesLFPO["VEBEK"] = ["06":1885,"25":895]
        timesLFPO["MOLBA"] = ["06":1190,"25":840]
        timesLFPO["ODILO"] = ["06":750,"25":1365]
        
        return ["LFPG":timesLFPG, "LFPB":timesLFPB, "LFOB":timesLFOB, "LFPO":timesLFPO]
    }
    
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
    
    /// Estimated time to fly the route
    func timeIntervalToFly(route: [Leg]) -> TimeInterval {
        guard let firstLeg = route.first else {
            return 0
        }
        var timeInterval: Double = 0
        guard let startFix = self.fixesDictionary[firstLeg.fix] else {
            return 0
        }
        var currentFix = startFix
        var currentSpeed = Double(300) // Default speed
        for leg in route {
            if let nextFix = self.fixesDictionary[leg.fix] {
                let distanceToNextFix = DistanceCalculator.distance(from: currentFix, to: nextFix)
                
                if let speed = leg.speed { // A leg has optionnaly a speed
                    // Consider the speed reduction is instantaneous
                    // TODO: calculate the additionnal time due to speed change
                    currentSpeed = Double(speed)
                }
                timeInterval += distanceToNextFix/currentSpeed*3600
                
                currentFix = nextFix
            }
        }
        return timeInterval
    }
    
    func timeInterval(to fixName:String, for flight:Flight) -> Double? {
        guard flight.route.map({ $0.fix }).contains(fixName) else {
            return nil
        }
        guard let startFix = self.fixesDictionary[flight.initialCondition.position] else {
            return nil
        }
        var timeInterval: Double = 0
        var currentFix = startFix
        var initialSpeed = flight.initialCondition.speed ?? 300
        if initialSpeed == 0 {
            initialSpeed = 300
        }
        var currentSpeed = Double(initialSpeed)
        for leg in flight.route {
            if let nextFix = self.fixesDictionary[leg.fix] {
                let distanceToNextFix = DistanceCalculator.distance(from: currentFix, to: nextFix)
                // Consider the speed reduction is instantaneous
                // TODO: calculate the additionnal time due to speed change
                if let speed = leg.speed {
                    currentSpeed = Double(speed)
                }
                timeInterval += distanceToNextFix/currentSpeed*3600
                if leg.fix == fixName {
                    return timeInterval
                }
                else {
                    currentFix = nextFix
                }
            }
        }
        return nil
    }
    
    func timeIntervalToFlyApproach(at destination:String, runway destinationRunway:String, from iaf:String) -> TimeInterval {
        let runway = destinationRunway.prefix(2)
        guard let airfieldsTimes = times[destination], let iafTimes = airfieldsTimes[iaf], let timeToRunway = iafTimes[String(runway)] else {
            return 0
        }
        return TimeInterval(timeToRunway)
    }
    
    func estimatedTimeIntervalToRunway(for flight:Flight) -> TimeInterval {
        let initialPosition = flight.initialCondition.position
        
        // Departure from a runway
        if initialPosition.count != 5 && initialPosition.count != 3 {
            return 0
        }
        
        // Arrival
        if let runway = flight.destinationRunway?.prefix(2), let iaf = flight.route.last?.fix {
            if let airfieldsTimes = times[flight.destination], let iafTimes = airfieldsTimes[iaf], let timeToRunway = iafTimes[String(runway)] {
                return TimeInterval(timeToRunway) + (self.timeInterval(to: iaf, for: flight) ?? Double(0))
            }
        }
        return 0
    }
    
    func estimatedDateToRunway(for flight:Flight) -> Date {
        return flight.initialCondition.date.addingTimeInterval(self.estimatedTimeIntervalToRunway(for: flight))
    }
    
    func setEstimatedTimeToRunway(for flight:inout Flight, to date:Date) {
        let initialPosition = flight.initialCondition.position
        
        // Departure from a runway
        if initialPosition.count != 5 && initialPosition.count != 3 {
            flight.initialCondition.date = date
        }
        
        // Arrival
        if let runway = flight.destinationRunway?.prefix(2), let iaf = flight.route.last?.fix.replacingOccurrences(of: "0", with: "O") {
            if let airfieldsTimes = times[flight.destination], let iafTimes = airfieldsTimes[iaf], let timeToRunway = iafTimes[String(runway)] {
                let timeIntervalToFyRoute = self.timeInterval(to: iaf, for: flight) ?? Double(0)
                flight.initialCondition.date = date.addingTimeInterval(TimeInterval(-(Double(timeToRunway)+timeIntervalToFyRoute)))
            }
        }
    }
    
    func canProvideEstimatedDate(for flight:Flight) -> Bool {
        if flight.initialCondition.position.count != 5 && flight.initialCondition.position.count != 3 {
            // Departure from a runway
            return true
        }
        else if let runway = flight.destinationRunway?.prefix(2) {
            if let iaf = flight.route.last?.fix {
                if let airfieldsTimes = times[flight.destination], let iafTimes = airfieldsTimes[iaf], let _ = iafTimes[String(runway)] {
                    return true
                }
            }
        }
        return false
    }
    
    func estimatedDate(at fixName:String, for flight:Flight) -> Date {
        return flight.initialCondition.date.addingTimeInterval(self.timeInterval(to: fixName, for: flight) ?? 0)
    }
}

// Flight route according to arrival procedure
extension SimulationContext {
    
    func flightRoute(from arrival:Arrival, startAltitude:Altitude = Altitude.flightLevel(350), aircraftType:String) -> [Leg] {
        var currentAltitude = startAltitude
        let propeller = Flight.propellers.contains(aircraftType)
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
                                if delta/distanceFromNextLegFixToFixWithConstrain > Double(270) {
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
