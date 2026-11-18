import Foundation
@testable import weather_activities

/// Responses captured from the live Open-Meteo API on 2026-11-17, plus domain values built from them.
enum Fixtures {
    // MARK: Geocoding

    /// `/v1/search?name=Paris`, first three results (postcodes shortened).
    static let parisSearchJSON = #"""
    {"results":[{"id":2988507,"name":"Paris","latitude":48.85341,"longitude":2.3488,"elevation":42.0,"feature_code":"PPLC","country_code":"FR","admin1_id":3012874,"admin2_id":2968815,"admin3_id":2988506,"admin4_id":6455259,"timezone":"Europe/Paris","population":2138551,"postcodes":["75001","75020"],"country_id":3017382,"country":"France","admin1":"Île-de-France Region","admin2":"Paris Department","admin3":"Paris","admin4":"Paris"},{"id":4717560,"name":"Paris","latitude":33.66094,"longitude":-95.55551,"elevation":183.0,"feature_code":"PPLA2","country_code":"US","admin1_id":4736286,"admin2_id":4705086,"timezone":"America/Chicago","population":24782,"postcodes":["75460","75461"],"country_id":6252001,"country":"United States","admin1":"Texas","admin2":"Lamar"},{"id":4647963,"name":"Paris","latitude":36.302,"longitude":-88.32671,"elevation":157.0,"feature_code":"PPLA2","country_code":"US","admin1_id":4662168,"admin2_id":4628829,"timezone":"America/Chicago","population":10150,"postcodes":["38242"],"country_id":6252001,"country":"United States","admin1":"Tennessee","admin2":"Henry"}],"generationtime_ms":0.19657612}
    """#

    /// `/v1/search?name=Singapore`: a city-state with no `admin1`.
    static let singaporeSearchJSON = #"""
    {"results":[{"id":1880252,"name":"Singapore","latitude":1.28967,"longitude":103.85007,"elevation":23.0,"feature_code":"PPLC","country_code":"SG","timezone":"Asia/Singapore","population":5638700,"country_id":1880251,"country":"Singapore"}],"generationtime_ms":0.08273125}
    """#

    /// `/v1/search` with no matches: the `results` key is missing entirely.
    static let noMatchesSearchJSON = #"{"generationtime_ms":0.100016594}"#

    // MARK: Forecast

    /// `/v1/forecast` for Paris, Texas.
    static let parisTexasForecastJSON = #"""
    {"latitude":33.65681,"longitude":-95.568184,"generationtime_ms":0.31065940856933594,"utc_offset_seconds":-21600,"timezone":"America/Chicago","timezone_abbreviation":"GMT-6","elevation":190.0,"daily_units":{"time":"iso8601","weather_code":"wmo code","temperature_2m_max":"°C","temperature_2m_min":"°C","precipitation_sum":"mm","snowfall_sum":"cm","wind_speed_10m_max":"km/h"},"daily":{"time":["2026-11-17","2026-11-18","2026-11-19","2026-11-20","2026-11-21","2026-11-22","2026-11-23"],"weather_code":[0,2,3,3,51,51,2],"temperature_2m_max":[16.8,19.4,22.0,21.9,23.1,16.6,17.1],"temperature_2m_min":[1.6,3.8,8.5,11.0,12.0,7.7,5.1],"precipitation_sum":[0.00,0.00,0.00,0.00,0.10,0.60,0.00],"snowfall_sum":[0.00,0.00,0.00,0.00,0.00,0.00,0.00],"wind_speed_10m_max":[12.0,13.8,16.1,13.5,17.7,29.3,13.9]}}
    """#

    /// `/v1/forecast` for San Francisco.
    static let sanFranciscoForecastJSON = #"""
    {"latitude":37.763283,"longitude":-122.41286,"generationtime_ms":0.39839744567871094,"utc_offset_seconds":-28800,"timezone":"America/Los_Angeles","timezone_abbreviation":"GMT-8","elevation":18.0,"daily_units":{"time":"iso8601","weather_code":"wmo code","temperature_2m_max":"°C","temperature_2m_min":"°C","precipitation_sum":"mm","snowfall_sum":"cm","wind_speed_10m_max":"km/h"},"daily":{"time":["2026-11-17","2026-11-18","2026-11-19","2026-11-20","2026-11-21","2026-11-22","2026-11-23"],"weather_code":[3,63,81,2,81,81,55],"temperature_2m_max":[13.9,13.0,15.6,14.3,13.7,14.5,14.1],"temperature_2m_min":[7.0,10.4,10.4,10.7,9.4,10.3,10.0],"precipitation_sum":[0.00,39.00,28.85,0.00,11.10,17.80,6.10],"snowfall_sum":[0.00,0.00,0.00,0.00,0.00,0.00,0.00],"wind_speed_10m_max":[12.2,31.8,53.8,18.1,28.8,27.4,14.3]}}
    """#

    // MARK: Marine

    /// `/v1/marine` for San Francisco.
    static let sanFranciscoMarineJSON = #"""
    {"latitude":37.791664,"longitude":-122.45833,"generationtime_ms":0.23686885833740234,"utc_offset_seconds":-28800,"timezone":"America/Los_Angeles","timezone_abbreviation":"GMT-8","elevation":18.0,"daily_units":{"time":"iso8601","wave_height_max":"m"},"daily":{"time":["2026-11-17","2026-11-18","2026-11-19","2026-11-20","2026-11-21","2026-11-22","2026-11-23"],"wave_height_max":[2.32,2.50,2.62,2.06,1.34,1.66,1.60]}}
    """#

    /// `/v1/marine` for inland Chamonix: HTTP 200 with every wave height `null`.
    static let chamonixMarineJSON = #"""
    {"latitude":45.958336,"longitude":6.8750153,"generationtime_ms":0.2334117889404297,"utc_offset_seconds":3600,"timezone":"Europe/Paris","timezone_abbreviation":"GMT+1","elevation":1041.0,"daily_units":{"time":"iso8601","wave_height_max":"m"},"daily":{"time":["2026-11-17","2026-11-18","2026-11-19","2026-11-20","2026-11-21","2026-11-22","2026-11-23"],"wave_height_max":[null,null,null,null,null,null,null]}}
    """#

    // MARK: Domain values

    static let parisFrance = Location(
        id: 2988507, name: "Paris", region: "Île-de-France Region", country: "France",
        latitude: 48.85341, longitude: 2.3488
    )
    static let parisTexas = Location(
        id: 4717560, name: "Paris", region: "Texas", country: "United States",
        latitude: 33.66094, longitude: -95.55551
    )
    static let parisTennessee = Location(
        id: 4647963, name: "Paris", region: "Tennessee", country: "United States",
        latitude: 36.302, longitude: -88.32671
    )
    static let london = Location(
        id: 2643743, name: "London", region: "England", country: "United Kingdom",
        latitude: 51.50853, longitude: -0.12574
    )

    /// A location whose id is `id`; other fields don't matter.
    static func location(id: Int) -> Location {
        Location(id: id, name: "Place \(id)", region: nil, country: nil, latitude: 0, longitude: 0)
    }

    static func day(
        _ condition: WeatherCondition = .clear,
        high: Double = 20,
        low: Double = 10,
        precipitation: Double? = 0,
        snowfall: Double? = 0,
        wind: Double? = 10,
        waves: Double? = nil,
        date: Date = Date(timeIntervalSince1970: 1_795_000_000)
    ) -> DailyWeather {
        DailyWeather(
            date: date,
            condition: condition,
            highC: high,
            lowC: low,
            precipitationMM: precipitation,
            snowfallCM: snowfall,
            windSpeedMaxKmh: wind,
            waveHeightMaxM: waves
        )
    }

    /// `days` re-dated to consecutive days from a fixed start, in Chicago time.
    static func forecast(_ days: [DailyWeather]) -> Forecast {
        let start = Date(timeIntervalSince1970: 1_795_000_000)
        return Forecast(
            timeZone: TimeZone(identifier: "America/Chicago")!,
            days: days.enumerated().map { offset, day in
                DailyWeather(
                    date: start.addingTimeInterval(Double(offset) * 86_400),
                    condition: day.condition,
                    highC: day.highC,
                    lowC: day.lowC,
                    precipitationMM: day.precipitationMM,
                    snowfallCM: day.snowfallCM,
                    windSpeedMaxKmh: day.windSpeedMaxKmh,
                    waveHeightMaxM: day.waveHeightMaxM
                )
            }
        )
    }
}

/// Builds `/v1/forecast` bodies. Defaults are the live Paris, Texas values.
struct ForecastJSON {
    var timezone = "America/Chicago"
    var time = ["2026-11-17", "2026-11-18", "2026-11-19", "2026-11-20", "2026-11-21", "2026-11-22", "2026-11-23"]
    var weatherCode: [Int?] = [0, 2, 3, 3, 51, 51, 2]
    var temperatureMax: [Double?] = [16.8, 19.4, 22.0, 21.9, 23.1, 16.6, 17.1]
    var temperatureMin: [Double?] = [1.6, 3.8, 8.5, 11.0, 12.0, 7.7, 5.1]
    var precipitationSum: [Double?] = [0, 0, 0, 0, 0.1, 0.6, 0]
    var snowfallSum: [Double?] = [0, 0, 0, 0, 0, 0, 0]
    var windSpeedMax: [Double?] = [12.0, 13.8, 16.1, 13.5, 17.7, 29.3, 13.9]

    var body: String {
        """
        {"timezone":"\(timezone)","daily":{"time":\(jsonArray(time)),"weather_code":\(jsonArray(weatherCode)),\
        "temperature_2m_max":\(jsonArray(temperatureMax)),"temperature_2m_min":\(jsonArray(temperatureMin)),\
        "precipitation_sum":\(jsonArray(precipitationSum)),"snowfall_sum":\(jsonArray(snowfallSum)),\
        "wind_speed_10m_max":\(jsonArray(windSpeedMax))}}
        """
    }
}

/// Builds `/v1/marine` bodies.
struct MarineJSON {
    var time: [String]
    var waveHeightMax: [Double?]

    var body: String {
        #"{"daily":{"time":\#(jsonArray(time)),"wave_height_max":\#(jsonArray(waveHeightMax))}}"#
    }
}

private func jsonArray(_ values: [String]) -> String {
    "[" + values.map { "\"\($0)\"" }.joined(separator: ",") + "]"
}

private func jsonArray<Number: Numeric>(_ values: [Number?]) -> String {
    "[" + values.map { $0.map { "\($0)" } ?? "null" }.joined(separator: ",") + "]"
}
