import XCTest
@testable import SimlogCore

final class SimlogCoretests: XCTestCase {
    
    let propertiesJSON = """
    {
    "traffic_density" : "Fort",
    "start_date" : "2021-01-30T12:06:10Z",
    "objectives" : "Objectifs de la simulation",
    "controlPositionGroups" : [
      [
        "inin",
        "inis"
      ],
      [
        "itmn",
        "itms",
        "itmba"
      ]
    ],
    "configuration" : "WL",
    "duration" : 60,
    "update_date" : "2021-01-30T12:08:10Z",
    "description" : "Description",
    "pressure" : 1013,
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
        XCTAssert(properties.trafficDensity == "Fort")
        XCTAssert(properties.objectives == "Objectifs de la simulation")
        XCTAssert(properties.duration == 60)
        XCTAssert(properties.description == "Description")
        XCTAssert(properties.pressure == 1013)
        XCTAssert(properties.weather == "CAVOK")
        XCTAssert(properties.controlPositionGroups == [[.inin, .inis], [.itms, .itmn, .itmba]])
        
        // Test dates
        let dateFormatter = ISO8601DateFormatter()
        XCTAssert(properties.startDate == dateFormatter.date(from: "2021-01-30T12:06:10Z"))
        XCTAssert(properties.updateDate == dateFormatter.date(from: "2021-01-30T12:08:10Z"))
    }
}
