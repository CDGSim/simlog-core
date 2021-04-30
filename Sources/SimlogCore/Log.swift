import Foundation

public struct Log: Codable {
    
    public struct Properties: Codable {
        public enum ControlPosition: String, Codable {
            case seq = "SEQ"
            case iniN = "INI N"
            case iniS = "INI S"
            case coorIniN = "COOR INI N"
            case coorIniS = "COOR INI S"
            case itmN = "ITM N"
            case itmS = "ITM S"
            case itmBA = "ITM BA"
            case depN = "DEP N"
            case depS = "DEP S"
            case coorDepN = "COOR DEP N"
            case coorDepS = "COOR DEP S"
            case locN = "LOC N"
            case locS = "LOC S"
            case coorLocN = "COOR LOC N"
            case coorLocS = "COOR LOC S"
            case solNW = "SOL NW"
            case solNE = "SOL NE"
            case solSW = "SOL SW"
            case solSE = "SOL SE"
            case pvl = "PVL"
            case ca = "CA"
            case ct = "CT"
            case cvs = "CVS"
        }
        
        public enum Controller: String, Codable {
            case instructor = "INS"
            case trainee = "ST"
            case certified = "PC"
        }
        
        public struct ControlPositionAssignment: Codable, Equatable {
            public var positions: Set<ControlPosition>
            public var controller: Controller
            
            public init(positions: Set<ControlPosition>, controller: Controller) {
                self.positions = positions
                self.controller = controller
            }
        }
        
        public var name: String
        public var updateDate: Date
        public var configuration: String
        public var trafficDensity: Int
        public var objectives: String
        public var description: String
        public var startDate: Date
        public var duration: Int
        public var weather: String
        public var assignments: [ControlPositionAssignment]?
        
        enum CodingKeys: String, CodingKey {
                case name, updateDate = "update_date", configuration, trafficDensity = "traffic_density", objectives, description, startDate = "start_date", duration, weather, assignments
        }
        
        public init(name: String, updateDate: Date, configuration: String, trafficDensity: Int, objectives: String, description: String, startDate: Date, duration: Int, weather: String, assignments:[ControlPositionAssignment]?) {
            self.name = name
            self.updateDate = updateDate
            self.configuration = configuration
            self.trafficDensity = trafficDensity
            self.objectives = objectives
            self.description = description
            self.startDate = startDate
            self.duration = duration
            self.weather = weather
            self.assignments = assignments
        }
    }
    
    public struct Event: Codable {
        public var time: String
        public var callsign: String
        public var location: String?
        public var description: String
        public var command: String?
        
        public init(time: String, callsign: String, location:String? = nil, description: String, command:String? = nil) {
            self.time = time
            self.callsign = callsign
            self.location = location
            self.description = description
            self.command = command
        }
    }
    
    public struct InstructorLog: Codable {
        public var setupInfo: String?
        public var events: [Event]?
        
        enum CodingKeys: String, CodingKey {
                case setupInfo = "setup_info", events
        }
        
        public init(setupInfo: String? = nil, events: [Log.Event]? = nil) {
            self.setupInfo = setupInfo
            self.events = events
        }
    }
    
    public struct PilotLog: Codable {
        public struct SetupElement: Codable {
            public var callsign: String
            public var description: String
            
            public init(callsign: String, description: String) {
                self.callsign = callsign
                self.description = description
            }
        }
        
        public var role: String
        public var frequency: String?
        public var directives: String?
        public var setup: [SetupElement]?
        public var events: [Event]?
        
        public init(role: String, frequency: String? = nil, directives: String? = nil, setup: [Log.PilotLog.SetupElement]? = nil, events: [Log.Event]? = nil) {
            self.role = role
            self.frequency = frequency
            self.directives = directives
            self.setup = setup
            self.events = events
        }
    }
    
    public var properties: Properties
    public var instructorLog: InstructorLog
    public var pilot_logs: [PilotLog]
    
    enum CodingKeys: String, CodingKey {
            case properties, instructorLog = "instructor_log", pilot_logs
    }
    
    public init(properties:Properties, instructorLog: InstructorLog, pilotLogs:[PilotLog]) {
        self.properties = properties
        self.instructorLog = instructorLog
        self.pilot_logs = pilotLogs
    }
}
