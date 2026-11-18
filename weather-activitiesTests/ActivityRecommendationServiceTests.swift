import Foundation
import Testing
@testable import weather_activities

struct ActivityRecommendationServiceTests {
    private let service = ActivityRecommendationService()

    private func ranking(for day: DailyWeather) -> [Activity] {
        service.recommendation(for: day).rankedScores.map(\.activity)
    }

    private func score(_ activity: Activity, for day: DailyWeather) -> Double? {
        service.recommendation(for: day).rankedScores.first { $0.activity == activity }?.score
    }

    @Test func dryWarmDayRanksOutdoorSightseeingFirst() {
        let day = Fixtures.day(.clear, high: 22, precipitation: 0, wind: 10)

        #expect(ranking(for: day).first == .outdoorSightseeing)
    }

    @Test func rainyDayRanksIndoorSightseeingFirst() {
        let day = Fixtures.day(.rain, high: 14, precipitation: 12, wind: 25, waves: 0.2)

        #expect(ranking(for: day).first == .indoorSightseeing)
    }

    @Test func freshSnowOnAColdDayRanksSkiingFirst() {
        let day = Fixtures.day(.snow, high: -5, low: -12, precipitation: 12, snowfall: 15, wind: 15)

        #expect(ranking(for: day).first == .skiing)
        #expect(score(.skiing, for: day) == 1)
    }

    @Test func goodWavesAndLightWindScoreSurfingHigh() throws {
        let day = Fixtures.day(.partlyCloudy, high: 21, wind: 10, waves: 1.5)

        let surfing = try #require(score(.surfing, for: day))
        #expect(surfing >= 0.9)
        // Ties with outdoor sightseeing; `Activity.allCases` order puts surfing first.
        #expect(ranking(for: day).first == .surfing)
    }

    @Test func thunderstormRulesOutSurfing() {
        let day = Fixtures.day(.thunderstorm, high: 21, wind: 10, waves: 1.5)

        #expect(score(.surfing, for: day) == 0)
    }

    @Test func missingWaveDataLeavesSurfingUnscoredAndLast() {
        let day = Fixtures.day(.clear, high: 22, waves: nil)

        let recommendation = service.recommendation(for: day)

        #expect(score(.surfing, for: day) == nil)
        #expect(recommendation.rankedScores.last?.activity == .surfing)
        #expect(recommendation.best?.activity != .surfing)
    }

    @Test func missingPrecipitationLeavesBothSightseeingActivitiesUnscored() {
        let day = Fixtures.day(precipitation: nil)

        #expect(score(.outdoorSightseeing, for: day) == nil)
        #expect(score(.indoorSightseeing, for: day) == nil)
        #expect(ranking(for: day).suffix(3) == [.surfing, .outdoorSightseeing, .indoorSightseeing])
    }

    @Test func noBestActivityWhenNothingCanBeScored() {
        let day = Fixtures.day(precipitation: nil, snowfall: nil, wind: nil, waves: nil)

        let recommendation = service.recommendation(for: day)

        #expect(recommendation.best == nil)
        #expect(recommendation.rankedScores.map(\.activity) == Activity.allCases)
    }

    @Test func scoresStayWithinZeroToOne() {
        let conditions: [WeatherCondition] = [.clear, .partlyCloudy, .overcast, .fog, .drizzle, .rain, .snow, .thunderstorm]
        for condition in conditions {
            for high in [-40.0, -5, 0, 8, 16, 22, 26, 34, 50] {
                for precipitation in [0.0, 5, 200] {
                    for snowfall in [0.0, 10, 150] {
                        for wind in [0.0, 30, 150] {
                            for waves in [nil, 0, 1.5, 3, 12] as [Double?] {
                                let day = Fixtures.day(
                                    condition, high: high, precipitation: precipitation,
                                    snowfall: snowfall, wind: wind, waves: waves
                                )
                                for activityScore in service.recommendation(for: day).rankedScores {
                                    guard let score = activityScore.score else { continue }
                                    #expect((0...1).contains(score), "\(activityScore.activity) scored \(score) for \(day)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @Test func recommendationsKeepTheForecastOrder() {
        let forecast = Fixtures.forecast([
            Fixtures.day(.rain, precipitation: 15),
            Fixtures.day(.clear),
        ])

        let recommendations = service.recommendations(for: forecast)

        #expect(recommendations.map(\.weather) == forecast.days)
    }
}
