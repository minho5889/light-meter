import Foundation

/// Pure mapping from a reading to a Gen-Z "vibe" (aesthetic name + emoji).
/// Shared by the Coach (offline stub) and the Records "Light Diary" so a saved
/// reading shows its vibe instantly, with no model call. Names are kept in
/// English on purpose — the aesthetic vocabulary is global and renders in the
/// handwritten card font.
enum LightVibe {
    static func of(lux: Double, kelvin: Double) -> (name: String, emoji: String) {
        let dim = lux < 100, bright = lux > 400
        let warm = kelvin < 3300, cool = kelvin > 4700
        switch (dim, bright, warm, cool) {
        case (_, true, true, _):  return ("Golden Hour Glow", "🌅")
        case (_, true, _, true):  return ("Clean Girl Daylight", "🤍")
        case (_, true, _, _):     return ("Main Character Energy", "✨")
        case (true, _, true, _):  return ("Cozy Cabincore", "🕯️")
        case (true, _, _, true):  return ("Moody Midnight", "🌃")
        case (true, _, _, _):     return ("Sleepy Wind-down", "🌙")
        case (_, _, true, _):     return ("Soft Sunset", "🌇")
        case (_, _, _, true):     return ("Studio Clean", "🎬")
        default:                  return ("Soft Daylight", "☁️")
        }
    }
}
