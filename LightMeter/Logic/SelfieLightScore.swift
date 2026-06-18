import Foundation

/// Pure, testable scorer for how flattering a light is for selfies / on-camera
/// content. Extracted from the Coach so it can be unit- and property-tested and
/// reused by the offline stub. Flattering light is soft and fairly bright
/// (~200–1000 lux) and neutral-to-warm (~2700–5500 K); harsh, dim, or very blue
/// light scores lower.
enum SelfieLightScore {
    /// A 0–100 rating (floored at 20). Higher = more flattering on camera.
    static func score(lux: Double, kelvin: Double) -> Int {
        var s = 100.0
        if lux < 200 {
            s -= min(45, (200 - lux) / 200 * 45)          // too dim
        } else if lux > 1000 {
            s -= min(30, (lux - 1000) / 1500 * 30)        // harsh / blown out
        }
        if kelvin > 5500 {
            s -= min(30, (kelvin - 5500) / 2000 * 30)     // too blue / clinical
        } else if kelvin < 2700 {
            s -= min(20, (2700 - kelvin) / 1000 * 20)     // too orange on camera
        }
        return Int(max(20, min(100, s)).rounded())
    }
}
