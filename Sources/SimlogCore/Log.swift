import Foundation

public struct Log: Codable {
    
    public struct Properties: Codable {
        public var name: String
        public var updateDate: Date
        public var configuration: String
        public var trafficDensity: String
        public var objectives: String
        public var description: String
        public var startDate: Date
        public var duration: Int
        public var pressure: Int
        public var weather: String
        
        enum CodingKeys: String, CodingKey {
                case name, updateDate = "update_date", configuration, trafficDensity = "traffic_density", objectives, description, startDate = "start_date", duration, pressure, weather
        }
        
        public init(name: String, updateDate: Date, configuration: String, trafficDensity: String, objectives: String, description: String, startDate: Date, duration: Int, pressure: Int, weather: String) {
            self.name = name
            self.updateDate = updateDate
            self.configuration = configuration
            self.trafficDensity = trafficDensity
            self.objectives = objectives
            self.description = description
            self.startDate = startDate
            self.duration = duration
            self.pressure = pressure
            self.weather = weather
        }
    }
    
    public struct Event: Codable {
        public var time: String
        public var callsign: String
        public var description: String
        
        public init(time: String, callsign: String, description: String) {
            self.time = time
            self.callsign = callsign
            self.description = description
        }
    }
    
    public struct InstructorLog: Codable {
        public var setupInfo: String?
        public var events: [Event]?
        
        enum CodingKeys: String, CodingKey {
                case setupInfo = "setup_info", events
        }
        
        internal init(setupInfo: String? = nil, events: [Log.Event]? = nil) {
            self.setupInfo = setupInfo
            self.events = events
        }
    }
    
    public struct PilotLog: Codable {
        public struct SetupElement: Codable {
            public var callsign: String
            public var description: String
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
