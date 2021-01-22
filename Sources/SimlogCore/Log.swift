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
    }
    
    public struct Event: Codable {
        public var time: String
        public var callsign: String
        public var description: String
    }
    
    public struct InstructorLog: Codable {
        public var setupInfo: String?
        public var events: [Event]?
        
        enum CodingKeys: String, CodingKey {
                case setupInfo = "setup_info", events
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
