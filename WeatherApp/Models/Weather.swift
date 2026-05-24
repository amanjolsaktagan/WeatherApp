import Foundation

struct Weather: Codable {
    let current: Current
    let hourly: Hourly
    let daily: Daily

    struct Current: Codable {
        let time: String
        let temperature2m: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let relativeHumidity2m: Int

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case relativeHumidity2m = "relative_humidity_2m"
        }
    }

    struct Hourly: Codable {
        let time: [String]
        let temperature2m: [Double]
        let weatherCode: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }

    struct Daily: Codable {
        let time: [String]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let weatherCode: [Int]
        let sunrise: [String]
        let sunset: [String]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case weatherCode = "weather_code"
            case sunrise
            case sunset
        }
    }
}

struct GeocodingResponse: Decodable {
    let results: [City]?
}

extension Weather {
    /// True if `current.time` (in the location's local timezone) is outside today's sunrise→sunset window.
    /// Falls back to a 06:00–19:00 daytime heuristic if sunrise/sunset are missing.
    var isNight: Bool {
        let now = Self.minutesSinceMidnight(in: current.time)
        guard let sunriseString = daily.sunrise.first,
              let sunsetString = daily.sunset.first else {
            let hour = now / 60
            return hour < 6 || hour >= 19
        }
        let sunrise = Self.minutesSinceMidnight(in: sunriseString)
        let sunset = Self.minutesSinceMidnight(in: sunsetString)
        return now < sunrise || now >= sunset
    }

    private static func minutesSinceMidnight(in iso: String) -> Int {
        // "YYYY-MM-DDTHH:MM" -> H*60 + M
        guard let timePart = iso.split(separator: "T").last else { return 12 * 60 }
        let parts = timePart.split(separator: ":")
        guard parts.count >= 2,
              let h = Int(parts[0]),
              let m = Int(parts[1]) else { return 12 * 60 }
        return h * 60 + m
    }
}
