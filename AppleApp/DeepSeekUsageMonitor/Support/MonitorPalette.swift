import SwiftUI

struct MonitorPalette {
    var isDark: Bool
    var background: Color
    var leftPanel: Color
    var rightPanel: Color
    var card: Color
    var cardHover: Color
    var inset: Color
    var primary: Color
    var secondary: Color
    var muted: Color
    var border: Color
    var strongBorder: Color
    var accent: Color
    var warning: Color
    var blue: Color
    var gaugeBezelOuter: Color
    var gaugeBezel: Color
    var gaugeBezel2: Color
    var gaugeTrack: Color
    var gaugeArc: Color
    var gaugeCenter: Color
    var gaugeCenterMid: Color
    var gaugeInnerRing: Color
    var gaugeTickMajor: Color
    var gaugeTickMid: Color
    var gaugeTickMinor: Color
    var dotMatrixActive: Color
    var dotMatrixInactive: Color

    static func palette(for scheme: ColorScheme) -> MonitorPalette {
        if scheme == .dark {
            return MonitorPalette(
                isDark: true,
                background: Color(red: 0.02, green: 0.02, blue: 0.02),
                leftPanel: Color(red: 0.03, green: 0.03, blue: 0.03),
                rightPanel: Color(red: 0.04, green: 0.04, blue: 0.04),
                card: Color(red: 0.07, green: 0.07, blue: 0.07),
                cardHover: Color(red: 0.10, green: 0.10, blue: 0.10),
                inset: Color(red: 0.04, green: 0.04, blue: 0.04),
                primary: Color(red: 0.96, green: 0.96, blue: 0.93),
                secondary: Color(red: 0.78, green: 0.78, blue: 0.74),
                muted: Color(red: 0.55, green: 0.55, blue: 0.51),
                border: Color.white.opacity(0.12),
                strongBorder: Color.white.opacity(0.28),
                accent: Color(red: 0.00, green: 0.82, blue: 0.52),
                warning: Color(red: 1.00, green: 0.23, blue: 0.19),
                blue: Color(red: 0.31, green: 0.64, blue: 1.00),
                gaugeBezelOuter: Color(red: 0.04, green: 0.04, blue: 0.04),
                gaugeBezel: Color(red: 0.11, green: 0.11, blue: 0.11),
                gaugeBezel2: Color(red: 0.16, green: 0.16, blue: 0.16),
                gaugeTrack: Color(red: 0.08, green: 0.08, blue: 0.08),
                gaugeArc: Color(red: 0.96, green: 0.96, blue: 0.93),
                gaugeCenter: Color(red: 0.03, green: 0.03, blue: 0.03),
                gaugeCenterMid: Color(red: 0.06, green: 0.06, blue: 0.06),
                gaugeInnerRing: Color(red: 0.14, green: 0.14, blue: 0.14),
                gaugeTickMajor: Color(red: 0.29, green: 0.29, blue: 0.29),
                gaugeTickMid: Color(red: 0.18, green: 0.18, blue: 0.18),
                gaugeTickMinor: Color(red: 0.12, green: 0.12, blue: 0.12),
                dotMatrixActive: Color.white,
                dotMatrixInactive: Color.white.opacity(0.10)
            )
        }

        return MonitorPalette(
            isDark: false,
            background: Color(red: 0.96, green: 0.95, blue: 0.92),
            leftPanel: Color(red: 0.93, green: 0.93, blue: 0.90),
            rightPanel: Color(red: 0.96, green: 0.95, blue: 0.92),
            card: Color.white,
            cardHover: Color(red: 0.98, green: 0.98, blue: 0.96),
            inset: Color(red: 0.92, green: 0.91, blue: 0.88),
            primary: Color(red: 0.07, green: 0.07, blue: 0.07),
            secondary: Color(red: 0.28, green: 0.28, blue: 0.25),
            muted: Color(red: 0.44, green: 0.44, blue: 0.40),
            border: Color.black.opacity(0.12),
            strongBorder: Color.black.opacity(0.28),
            accent: Color(red: 0.00, green: 0.56, blue: 0.35),
            warning: Color(red: 0.85, green: 0.19, blue: 0.15),
            blue: Color(red: 0.15, green: 0.39, blue: 0.92),
            gaugeBezelOuter: Color(red: 0.60, green: 0.60, blue: 0.57),
            gaugeBezel: Color(red: 0.72, green: 0.72, blue: 0.69),
            gaugeBezel2: Color(red: 0.78, green: 0.78, blue: 0.74),
            gaugeTrack: Color(red: 0.88, green: 0.87, blue: 0.84),
            gaugeArc: Color(red: 0.07, green: 0.07, blue: 0.07),
            gaugeCenter: Color(red: 0.96, green: 0.95, blue: 0.92),
            gaugeCenterMid: Color(red: 0.93, green: 0.92, blue: 0.89),
            gaugeInnerRing: Color(red: 0.84, green: 0.84, blue: 0.80),
            gaugeTickMajor: Color(red: 0.54, green: 0.54, blue: 0.51),
            gaugeTickMid: Color(red: 0.69, green: 0.69, blue: 0.66),
            gaugeTickMinor: Color(red: 0.80, green: 0.80, blue: 0.76),
            dotMatrixActive: Color(red: 0.03, green: 0.03, blue: 0.03),
            dotMatrixInactive: Color.black.opacity(0.06)
        )
    }
}
