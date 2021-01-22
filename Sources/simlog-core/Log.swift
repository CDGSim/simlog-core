import Foundation

struct Log: Codable {
    
    struct Properties: Codable {
        var name: String
        var updateDate: Date
        var configuration: String
        var trafficDensity: String
        var objectives: String
        var description: String
        var startDate: Date
        var duration: Int
        var pressure: Int
        var weather: String
        
        enum CodingKeys: String, CodingKey {
                case name, updateDate = "update_date", configuration, trafficDensity = "traffic_density", objectives, description, startDate = "start_date", duration, pressure, weather
        }
    }
    
    struct InstructorLog: Codable {
        var setupInfo: String?
        var events: [Event]?
        
        enum CodingKeys: String, CodingKey {
                case setupInfo = "setup_info", events
        }
    }
    
    struct Event: Codable {
        var time: String
        var callsign: String
        var description: String
    }
    
    struct SetupElement: Codable {
        var callsign: String
        var description: String
    }
    
    struct PilotLog: Codable {
        var role: String
        var frequency: String?
        var directives: String?
        var setup: [SetupElement]?
        var events: [Event]?
    }
    
    var properties: Properties
    var instructorLog: InstructorLog
    var pilot_logs: [PilotLog]
    
    enum CodingKeys: String, CodingKey {
            case properties, instructorLog = "instructor_log", pilot_logs
    }
}
