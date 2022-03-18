//
//  EstimateCalculator.swift
//  SimEdit
//
//  Created by Axel Péju on 27/01/2022.
//

import Foundation

enum EstimateError : Error {
    case fixNotInRoute
    case initialPositionNotInContext
    case fixNotInContext
}

public struct RelativePosition {
    let fixName: String
    let bearing: Int
    let distance: Double
}

public typealias Speed = Int

public struct EstimateCalculator {
    public init() {
        self._estimatesCache = EstimatesCache()
    }
    
    private let simulationContext = SimulationContext.shared
    
    // Cache
    public class EstimatesCache {
        struct Flight: Hashable {
            let callsign:String
            let origin:String
            let destination:String
        }
        var estimates = [EstimatesCache.Flight:Date]()
    }
    
    private var _estimatesCache = EstimatesCache()
    
    // Hard coded times
    // TODO: calculate time according to procedure's distance
    // and aircraft speed
    private var times: [String:[String:[String:Int]]] {
        var timesLFPG:[String:[String:Int]] = [:]
        timesLFPG["LORNI"] = ["27":775, "26":760, "09":1105, "08":1150]
        timesLFPG["MOPAR"] = ["27":1270, "26":1150, "09":725, "08":740]
        timesLFPG["MOBRO"] = ["27":1335, "26":1340]
        timesLFPG["BANOX"] = ["27":1290, "26":1300, "09":865, "08":930]
        timesLFPG["OKIPA"] = ["27":870, "26":845, "09":1315, "08":1165]
        
        var timesLFPB:[String:[String:Int]] = [:]
        timesLFPB["MOBRO"] = ["27":1345]
        timesLFPB["KOLIV"] = ["07":760]
        timesLFPB["VEBEK"] = ["07":1300, "27":855]
        timesLFPB["OKABO"] = ["07":1140, "27":875]
        timesLFPB["BANOX"] = ["07":710, "27":1400]
        
        var timesLFOB:[String:[String:Int]] = [:]
        timesLFOB["IPNOB"] = ["30":280,"12":580]
        timesLFOB["LORNI"] = ["30":300,"12":600]
        
        var timesLFPO:[String:[String:Int]] = [:]
        timesLFPO["VEBEK"] = ["06":1885,"25":895]
        timesLFPO["MOLBA"] = ["06":1190,"25":840]
        timesLFPO["ODILO"] = ["06":750,"25":1365]
        
        return ["LFPG":timesLFPG, "LFPB":timesLFPB, "LFOB":timesLFOB, "LFPO":timesLFPO]
    }
    
    /// Returns an estimated date at the runway
    /// If the destination runway is missing, the date is the date at the last fix of the route
    public func estimatedDateToRunway(for flight:Flight) -> Date {
        var estimate = _estimatesCache.estimates[flight.cacheIdentifier()]
        if estimate == nil {
            estimate = flight.initialCondition.date.addingTimeInterval(self.estimatedTimeIntervalToRunway(for: flight))
            _estimatesCache.estimates[flight.cacheIdentifier()] = estimate
        }
        return estimate!
    }
    
    public func setEstimatedDateToRunway(_ date:Date, for flight:Flight) {
        _estimatesCache.estimates[flight.cacheIdentifier()] = date
    }
    
    public func setEstimatedTimeToRunway(for flight:inout Flight, to date:Date) {
        let initialPosition = flight.initialCondition.position
        
        // Departure from a runway
        if initialPosition.count != 5 && initialPosition.count != 3 {
            flight.initialCondition.date = date
        }
        
        // Arrival
        if let runway = flight.destinationRunway?.prefix(2), let iaf = flight.route.last?.fix.replacingOccurrences(of: "0", with: "O") {
            if let airfieldsTimes = times[flight.destination], let iafTimes = airfieldsTimes[iaf], let timeToRunway = iafTimes[String(runway)] {
                if let timeIntervalToFyRoute = try? self.timeInterval(to: iaf, for: flight) {
                    flight.initialCondition.date = date.addingTimeInterval(TimeInterval(-(Double(timeToRunway)+timeIntervalToFyRoute)))
                }
            }
        }
        
        _estimatesCache.estimates[flight.cacheIdentifier()] = date
    }
    
    /// Estimated time to fly the route
    public func timeIntervalToFly(route: [Leg],
                           upTo fixName:String? = nil,
                           withInitialSpeed initialSpeed:Int = 300,
                           initialAltitude: Altitude = .flightLevel(200)) throws -> TimeInterval {
        // Check that fix belongs to the route, or fix is empty
        guard route.map({ $0.fix }).contains(fixName) || fixName == nil else {
            throw EstimateError.fixNotInRoute
        }
        
        // If the route is empty, then the time to fly it is 0
        guard let firstLeg = route.first else {
            return 0
        }
        
        
        // Check that start fix is included in the context
        guard let startFix = simulationContext.fixesDictionary[firstLeg.fix] else {
            throw EstimateError.initialPositionNotInContext
        }
        
        var timeInterval: Double = 0
        var currentFix = startFix
        
        var currentSpeed = Double(initialSpeed)
        if currentSpeed == 0 {
            currentSpeed = 300
        }
        
        var currentFlightLevel = Double(initialAltitude.absoluteValue()/100)
        
        for leg in route {
            if let nextFix = simulationContext.fixesDictionary[leg.fix] {
                let distanceToNextFix = DistanceCalculator.distance(from: currentFix, to: nextFix)
                // Approximate ground speed to air speed + FL/2
                timeInterval += distanceToNextFix/(currentSpeed + currentFlightLevel/2)*3600
                
                if leg.fix == fixName {
                    return timeInterval
                } else {
                    currentFix = nextFix
                    
                    // Consider the speed reduction is instantaneous
                    if let speed = leg.speed {
                        currentSpeed = Double(speed)
                    }
                    // Altitude change is also considered instantaneous
                    if let altitude = leg.altitude {
                        currentFlightLevel = Double(altitude.absoluteValue()/100)
                    }
                }
            }
        }
        return timeInterval
    }
    
    public func timeInterval(to fixName:String, for flight:Flight) throws -> Double {
        var route = flight.route
        // Attempt to recover from a missing departure procedure
        if let firstLeg = route.first, simulationContext.fixesDictionary[firstLeg.fix] == nil {
            route[0] = .init(fix: flight.origin)
        }
        
        return try self.timeIntervalToFly(route: route,
                                      upTo: fixName,
                                          withInitialSpeed: flight.initialCondition.speed ?? flight.aircraftType.cruiseSpeed,
                                      initialAltitude: flight.initialCondition.altitude)
    }
    
    public func timeIntervalToFlyApproach(at destination:String, runway destinationRunway:String, from iaf:String) -> TimeInterval {
        let runway = destinationRunway.prefix(2)
        guard let airfieldsTimes = times[destination], let iafTimes = airfieldsTimes[iaf], let timeToRunway = iafTimes[String(runway)] else {
            return 0
        }
        return TimeInterval(timeToRunway)
    }
    
    public func estimatedTimeIntervalToRunway(for flight:Flight) -> TimeInterval {
        let initialPosition = flight.initialCondition.position
        
        // Departure from a runway
        if initialPosition.count != 5 && initialPosition.count != 3 {
            return 0
        }
        
        // Arrival
        if let runway = flight.destinationRunway?.prefix(2), let iaf = flight.route.last?.fix {
            if let airfieldsTimes = times[flight.destination],
               let iafTimes = airfieldsTimes[iaf],
               let timeToRunway = iafTimes[String(runway)],
               let timeIntervalToIAF = try? self.timeInterval(to: iaf, for: flight) {
                return TimeInterval(timeToRunway) + timeIntervalToIAF
            }
        }
        return 0
    }
    
    public func canProvideEstimatedDate(for flight:Flight) -> Bool {
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
    
    public func estimatedDate(at fixName:String, for flight:Flight) throws -> Date {
        let timeIntervalToFix = try self.timeInterval(to: fixName, for: flight)
        return flight.initialCondition.date.addingTimeInterval(timeIntervalToFix)
    }
    
    /// Calculates an conditions for a flight at a certain date in terms of 3D position and speed
    public func flightConditions(at date:Date, for flight:Flight) throws -> (RelativePosition, Altitude, Speed) {
        var indicatedSpeed = Double(flight.aircraftType.cruiseSpeed)
        guard date > flight.initialCondition.date else {
            let position = RelativePosition(fixName: flight.initialCondition.position, bearing: 0, distance: 0)
            return (position, flight.initialCondition.altitude, flight.initialCondition.speed ?? flight.aircraftType.cruiseSpeed)
        }
        // Iterate through the flight's route to find the leg the flight is on
        let startFixName = flight.initialCondition.position
        var currentAltitude = flight.initialCondition.altitude
        var currentGroundSpeed = indicatedSpeed + Double(currentAltitude.absoluteValue())/100/2
        guard var currentLegStart = simulationContext.fixesDictionary[startFixName] else {
            throw EstimateError.fixNotInContext
        }
        var currentLegEnd: GeographicalPosition
        var currentDate = flight.initialCondition.date
        for leg in flight.route {
            guard let legEnd = simulationContext.fixesDictionary[leg.fix] else {
                throw EstimateError.fixNotInContext
            }
            currentLegEnd = legEnd
            let distanceToNextFix = DistanceCalculator.distance(from: currentLegStart, to: currentLegEnd)
            let timeToNextFix = distanceToNextFix/currentGroundSpeed*3600
            if currentDate.addingTimeInterval(timeToNextFix) > date {
                // We will be after leg.fix at date
                // so we are along this leg
                let timeSpentOnLeg = date.timeIntervalSince(currentDate)
                let distanceOnLeg = currentGroundSpeed*timeSpentOnLeg/3600
                let trackToNextFix = TrackCalculator.track(from: currentLegEnd, to: currentLegStart)
                let legStartAltitude = Double(currentAltitude.absoluteValue())
                let legEndAltitude = Double(leg.altitude?.absoluteValue() ?? currentAltitude.absoluteValue())
                let altitude = legStartAltitude + (legEndAltitude - legStartAltitude) * distanceOnLeg / distanceToNextFix
                let position = RelativePosition(fixName: leg.fix, bearing: trackToNextFix, distance: distanceToNextFix - distanceOnLeg)
                return (position, .altitude(Int(altitude)), Int(indicatedSpeed))
            }
            currentLegStart = currentLegEnd
            // Update altitude and speed according to the leg's restrictions
            if let altitude = leg.altitude {
                currentAltitude = altitude
                currentGroundSpeed = indicatedSpeed + Double(currentAltitude.absoluteValue())/100/2
            }
            if let maxSpeed = leg.maximumSpeed {
                indicatedSpeed = min(Double(maxSpeed), indicatedSpeed)
                currentGroundSpeed = indicatedSpeed + Double(currentAltitude.absoluteValue())/100/2
            }
            currentDate = currentDate.addingTimeInterval(timeToNextFix)
        }
        
        let routeLength = flight.route.count
        let lastFix = flight.route[routeLength-1].fix
        let beforeFix = flight.route[routeLength-2].fix
        guard let from = simulationContext.fixesDictionary[beforeFix], let to = simulationContext.fixesDictionary[lastFix] else {
            throw EstimateError.fixNotInContext
        }
        let track = TrackCalculator.track(from: to, to: from)
        let position = RelativePosition(fixName: lastFix, bearing: track, distance: 5.0)
        return (position, currentAltitude, Int(indicatedSpeed))
    }
}

extension AircraftType {
    var cruiseSpeed: Int {
        switch self {
        case "C172", "P28T":
            return 108
        case "DR40", "TRIN", "TOBA":
            return 120
        case "SR22":
            return 150
        case "PC12":
            return 268
        case "DHC6":
            return 250
        case "AT72":
            return 275
        case "AT43":
            return 255
        case "B190":
            return 270
        case "BE40":
            return 260
        case "SW3":
            return 255
        default:
            return 300
        }
    }
}

extension Flight {
    fileprivate func cacheIdentifier() -> EstimateCalculator.EstimatesCache.Flight {
        return .init(callsign:self.callsign, origin:self.origin, destination:self.destination)
    }
}
