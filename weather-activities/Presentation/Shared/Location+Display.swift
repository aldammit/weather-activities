import Foundation

extension Location {
    /// "Texas, United States": tells apart places that share a name.
    var detail: String? {
        let parts = [region, country].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
