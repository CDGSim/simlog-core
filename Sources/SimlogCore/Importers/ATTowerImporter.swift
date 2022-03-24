import Foundation
import XMLCoder

public struct ATTowerImporter {
    public init(content data: Data) {
        
        let exerciseData = try! XMLDecoder().decode(ExerciseData.self, from: data)
        let startDate = Date(timeIntervalSince1970: TimeInterval(exerciseData.exercise.header.basicData.start))
        
        let flights = exerciseData.exercise.flightPlans.flightPlans.map { flightPlan -> Flight in
            
            // Flight Rule
            let flightRule: DecodableFlightRule = .init(wrappedValue: flightPlan.basicData.flightRule == "VFR" ? .VFR : .IFR)
            
            // Initial conditions
            let initialCondition: InitialCondition
            switch flightPlan.setup.command {
            case "DPO", "XDP":
                let date: Date
                if let etd = flightPlan.departureAirport.plannedEtd {
                    date = startDate.addingTimeInterval(TimeInterval(etd))
                } else {
                    date = startDate.addingTimeInterval(TimeInterval(flightPlan.setup.time))
                }
                let runway: String
                if let miscRunway = flightPlan.misc.assignedRunway {
                    runway = miscRunway
                } else if let externalRunway = flightPlan.icao.externalRunway {
                    runway = externalRunway
                } else {
                    runway = ""
                }
                initialCondition = InitialCondition(date: date,
                                                    position: "\(flightPlan.departureAirport.code).RWY.\(runway)",
                                                    altitude: .altitude(400))
            default:
                let date = startDate.addingTimeInterval(TimeInterval(flightPlan.setup.time))
                initialCondition = InitialCondition(date: date,
                                                    position: flightPlan.setup.name!,
                                                    altitude: .flightLevel(260))
            }
            
            let route = flightPlan.actionLines.actionLines.sorted(by: { firstActionLine, secondActionLine in
                func order(for actionLine:ActionLine) -> Int {
                    let order: Int
                    switch actionLine.command {
                    case "SID":
                        order = 1
                    case "FBX", "FIX":
                        order = 2
                    case "APP":
                        order = 3
                    default:
                        order = 0
                    }
                    return order
                }
                let firstActionOrder = order(for: firstActionLine)
                let secondActionOrder = order(for: secondActionLine)
                return firstActionOrder < secondActionOrder
            }).compactMap { actionLine -> [Leg]? in
                switch actionLine.command {
                case "FBX", "FIX":
                    if let fixName = actionLine.name {
                        return [Leg(fix: fixName)]
                    } else { return nil }
                case "SID":
                    if let fixName = actionLine.name?.prefix(5), fixName.count == 5{
                        return [Leg(fix: String(fixName))]
                    } else { return nil }
                case "APP":
                    if let atTowerProcedureName = actionLine.name {
                        if let procedureName = atTowerProcedureName.components(separatedBy: "_").first {
                            let arrivalAirfieldSTARs = SimulationContext.shared.airfields.first(where: { $0.name == flightPlan.arrivalAirport.code })?.arrivals
                            if let arrivalAirfieldSTARs = arrivalAirfieldSTARs {
                                let arrivalName = procedureName.prefix(5) + " " + procedureName.suffix(2)
                                if let correspondingSTAR = arrivalAirfieldSTARs.first(where: {
                                    $0.name == arrivalName
                                    
                                }) {
                                    return correspondingSTAR.route
                                }
                            }
                        }
                    }
                    return nil
                default:
                    return nil
                }
            }.reduce([Leg]()) { partialRoute, legs in
                partialRoute + legs
            }
            
            let flight = Flight(callsign: flightPlan.basicData.callsign,
                                aircraftType: flightPlan.basicData.aircraftType,
                                origin: flightPlan.departureAirport.code,
                                departureRunway: flightPlan.misc.assignedRunway,
                                destination: flightPlan.arrivalAirport.code,
                                destinationRunway: flightPlan.misc.assignedRunway,
                                parkingStand: flightPlan.misc.assignedGate ?? "",
                                flightRule: flightRule,
                                ssrCode: flightPlan.transponder.SSRCode,
                                route: route,
                                initialCondition: initialCondition)
            return flight
        }
        self.flights = flights
        
        self.exerciseName = exerciseData.exercise.header.basicData.name
        self.exerciseDuration = exerciseData.exercise.header.basicData.duration/60
    }
    
    private let simulationContext = SimulationContext.shared
    private let estimateCalculator = EstimateCalculator()
    
    private let exerciseName: String
    private let exerciseDuration: Int
    
    public var flights: [Flight]
}

extension ATTowerImporter: ImporterProtocol {
    public var name: String {
        self.exerciseName
    }
    
    public mutating func duration() -> Int {
        self.exerciseDuration
    }
    
    public var pressure: Int {
        return 1013
    }
    
    public var temperature: Int {
        return 15
    }
    
}

// MARK: - Exercise XML Data

struct ExerciseData: Codable {
    let exercise: Exercise
    
    enum CodingKeys: String, CodingKey {
        case exercise = "Exercise"
    }
}

struct Exercise: Codable {
    let flightPlans: FlightPlans
    let header: Header
    
    enum CodingKeys: String, CodingKey {
        case header = "Header"
        case flightPlans = "FlightPlans"
    }
}

struct Header: Codable {
    let basicData: HeaderData
    
    enum CodingKeys: String, CodingKey {
        case basicData = "BasicData"
    }
}

struct HeaderData: Codable {
    let duration: Int
    let start: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case duration = "Duration"
        case start = "Start"
        case name = "Name"
    }
}

struct FlightPlans: Codable {
    let flightPlans: [FlightPlan]
    
    enum CodingKeys: String, CodingKey {
        case flightPlans = "FlightPlan"
    }
}

struct FlightPlan: Codable {
    let basicData: BasicData
    let departureAirport: FlightAirport
    let arrivalAirport: FlightAirport
    let icao: ICAO
    let transponder: Transponder
    let misc: Misc
    let setup: Setup
    let actionLines: ActionLines
    
    enum CodingKeys: String, CodingKey {
        case basicData = "BasicData"
        case departureAirport = "DepartureAirport"
        case arrivalAirport = "ArrivalAirport"
        case icao = "ICAO"
        case transponder = "Transponder"
        case misc = "Misc"
        case setup = "Setup"
        case actionLines = "ActionLines"
    }
}

struct BasicData: Codable {
    let aircraftType: String
    let callsign: String
    let flightRule: String
    
    enum CodingKeys: String, CodingKey {
        case aircraftType = "AircraftType"
        case callsign = "Callsign"
        case flightRule = "FlightRule"
    }
}

struct FlightAirport: Codable {
    let code: String
    let eta: Int?
    let plannedEta: Int?
    let etd: Int?
    let plannedEtd: Int?
    
    enum CodingKeys: String, CodingKey {
        case code = "Code"
        case eta = "ETA"
        case plannedEta = "PlannedETA"
        case etd = "ETD"
        case plannedEtd = "PlannedETD"
    }
}

struct Transponder: Codable {
    let SSRCode: String?
    
    enum CodingKeys: String, CodingKey {
        case SSRCode = "SSRCode"
    }
}

struct ICAO: Codable {
    let externalRunway: String?
    
    enum CodingKeys: String, CodingKey {
        case externalRunway = "ExternalRunway"
    }
}

struct Misc: Codable {
    let assignedGate: String?
    let assignedRunway: String?
    
    enum CodingKeys: String, CodingKey {
        case assignedGate = "AssignedGate"
        case assignedRunway = "AssignedRunway"
    }
}

struct Setup: Codable {
    let command: String
    let name: String?
    let time: Int
    
    enum CodingKeys: String, CodingKey {
        case command = "Command"
        case name = "Name"
        case time = "Time"
    }
}

struct ActionLines: Codable {
    let actionLines: [ActionLine]
    
    enum CodingKeys: String, CodingKey {
        case actionLines = "ActionLine"
    }
}

struct ActionLine: Codable {
    let command: String
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case command = "Command"
        case name = "Name"
    }
}
