import Foundation

enum MonitorFormatters {
    static func cny(_ value: Double, digits: Int = 2) -> String {
        "¥" + value.formatted(.number.precision(.fractionLength(digits)))
    }

    static func tokens(_ value: Int) -> String {
        if value >= 1_000_000 {
            return (Double(value) / 1_000_000).formatted(.number.precision(.fractionLength(2))) + "M"
        }
        if value >= 1_000 {
            return (Double(value) / 1_000).formatted(.number.precision(.fractionLength(0))) + "K"
        }
        return "\(value)"
    }

    static func shortTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    static func relativeUptime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }
}
