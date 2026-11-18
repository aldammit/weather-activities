import Foundation

/// Response of Open-Meteo's `/v1/marine` endpoint. Inland locations get `null` wave heights.
nonisolated struct MarineResponseDTO: Decodable, Sendable {
    let daily: Daily

    nonisolated struct Daily: Decodable, Sendable {
        /// Local dates, `yyyy-MM-dd`.
        let time: [String]
        let waveHeightMax: [Double?]

        nonisolated enum CodingKeys: String, CodingKey {
            case time
            case waveHeightMax = "wave_height_max"
        }
    }
}
