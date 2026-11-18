import Foundation

extension FormatStyle where Self == Measurement<UnitTemperature>.FormatStyle {
    /// Whole-degree temperature in the user's preferred unit, e.g. "18°".
    static var temperature: Self {
        .measurement(
            width: .narrow,
            usage: .weather,
            hidesScaleName: true,
            numberFormatStyle: .number.precision(.fractionLength(0))
        )
    }
}

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Percent {
    /// Whole-percent activity score, e.g. "92%".
    static var score: Self {
        .percent.precision(.fractionLength(0))
    }
}
