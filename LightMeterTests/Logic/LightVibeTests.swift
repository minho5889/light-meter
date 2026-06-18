import Testing
@testable import LightMeter

struct LightVibeTests {

    // MARK: - Known values

    @Test func brightWarmIsGoldenHour() {
        #expect(LightVibe.of(lux: 600, kelvin: 2800).name == "Golden Hour Glow")
    }

    @Test func dimCoolIsMoody() {
        #expect(LightVibe.of(lux: 40, kelvin: 6000).name == "Moody Midnight")
    }

    // MARK: - Property 1: always returns a non-empty name + emoji

    @Test func property_alwaysLabelled() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<300 {
            let v = LightVibe.of(lux: Double.random(in: 0...8000, using: &rng),
                                 kelvin: Double.random(in: 1000...12000, using: &rng))
            #expect(!v.name.isEmpty)
            #expect(!v.emoji.isEmpty)
        }
    }

    // MARK: - Property 2: deterministic (same reading → same vibe)

    @Test func property_deterministic() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            let lux = Double.random(in: 0...5000, using: &rng)
            let kelvin = Double.random(in: 1000...10000, using: &rng)
            let a = LightVibe.of(lux: lux, kelvin: kelvin)
            let b = LightVibe.of(lux: lux, kelvin: kelvin)
            #expect(a.name == b.name && a.emoji == b.emoji)
        }
    }
}
