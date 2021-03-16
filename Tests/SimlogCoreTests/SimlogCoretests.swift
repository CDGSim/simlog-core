import XCTest
@testable import SimlogCore

final class SimlogCoretests: XCTestCase {
    
    let propertiesJSON = """
    {
    "traffic_density" : 5,
    "start_date" : "2021-01-30T12:06:10Z",
    "objectives" : "Objectifs de la simulation",
      "assignments" : [
        {
          "controller" : "PC",
          "positions" : [
            "INI N"
          ]
        },
        {
          "controller" : "ST",
          "positions" : [
            "INI S"
          ]
        }
      ],
    "configuration" : "WL",
    "duration" : 60,
    "update_date" : "2021-01-30T12:08:10Z",
    "description" : "Description",
    "name" : "test",
    "weather" : "CAVOK"
    }
    """
    
    func testPropertiesJSONDecoding() throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try XCTUnwrap(propertiesJSON.data(using: .utf8))
        let properties = try decoder.decode(Log.Properties.self, from: data)
        XCTAssert(properties.name == "test")
        XCTAssert(properties.trafficDensity == 5)
        XCTAssert(properties.objectives == "Objectifs de la simulation")
        XCTAssert(properties.duration == 60)
        XCTAssert(properties.description == "Description")
        XCTAssert(properties.weather == "CAVOK")
        XCTAssert(properties.assignments == [.init(positions: [.iniN], controller: .certified), .init(positions: [.iniS], controller: .trainee)])
        
        // Test dates
        let dateFormatter = ISO8601DateFormatter()
        XCTAssert(properties.startDate == dateFormatter.date(from: "2021-01-30T12:06:10Z"))
        XCTAssert(properties.updateDate == dateFormatter.date(from: "2021-01-30T12:08:10Z"))
    }
    
    func testSharedContext() throws {
        XCTAssertNotNil(SimulationContext.shared)
    }
}
