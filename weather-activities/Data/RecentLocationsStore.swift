import Foundation

/// The last few locations the user opened, most recent first, persisted in `UserDefaults`.
///
/// Not `Sendable` because `UserDefaults` isn't; the app only uses it from the main actor.
nonisolated struct RecentLocationsStore {
    static let capacity = 5

    private let defaults: UserDefaults
    private let key = "recentLocations"

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    /// Stored locations, or none when nothing is stored or the stored data can't be read.
    func load() -> [Location] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Location].self, from: data)) ?? []
    }

    /// Moves `location` to the front, dropping its older entry and anything past `capacity`.
    func record(_ location: Location) {
        let others = load().filter { $0.id != location.id }
        let updated = Array(([location] + others).prefix(Self.capacity))
        // Encoding plain value types can't fail.
        defaults.set(try! JSONEncoder().encode(updated), forKey: key)
    }
}
