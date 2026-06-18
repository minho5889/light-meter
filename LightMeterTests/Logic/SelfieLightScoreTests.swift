import Testing
@testable import LightMeter

struct SelfieLightScoreTests {

    // MARK: - Known values

    @Test func idealLightScoresPerfect() {
        #expect(SelfieLightScore.score(lux: 450, kelvin: 4500) == 100)
    }

    @Test func dimAndBlueScoresLow() {
        #expect(SelfieLightScore.score(lux: 30, kelvin: 7000) < 70)
    }

    // MARK: - Property 1: score stays within bounds (floored at 20, capped at 100)

    @Test func property_scoreInBounds() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let lux = Double.random(in: 0...8000, using: &rng)
            let kelvin = Double.random(in: 1000...12000, using: &rng)
            let s = SelfieLightScore.score(lux: lux, kelvin: kelvin)
            #expect(s >= 20 && s <= 100)
        }
    }

    // MARK: - Property 2: anything fully inside the flattering window is perfect

    @Test func property_sweetSpotIsPerfect() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            let lux = Double.random(in: 200...1000, using: &rng)
            let kelvin = Double.random(in: 2700...5500, using: &rng)
            #expect(SelfieLightScore.score(lux: lux, kelvin: kelvin) == 100)
        }
    }

    // MARK: - Property 3: in the dim regime, dimmer never scores higher (monotonic)

    @Test func property_dimmerNotBetter() {
        var rng = SystemRandomNumberGenerator()
        let kelvin = 4000.0  // sweet-spot warmth, so only brightness varies
        for _ in 0..<100 {
            let a = Double.random(in: 0...200, using: &rng)
            let b = Double.random(in: 0...200, using: &rng)
            let lo = min(a, b), hi = max(a, b)
            #expect(SelfieLightScore.score(lux: lo, kelvin: kelvin)
                    <= SelfieLightScore.score(lux: hi, kelvin: kelvin))
        }
    }

    // MARK: - Property 4: past 5500K, bluer light never scores higher

    @Test func property_coolerNotBetter() {
        var rng = SystemRandomNumberGenerator()
        let lux = 500.0  // sweet-spot brightness
        for _ in 0..<100 {
            let a = Double.random(in: 5500...12000, using: &rng)
            let b = Double.random(in: 5500...12000, using: &rng)
            let cooler = min(a, b), bluer = max(a, b)
            #expect(SelfieLightScore.score(lux: lux, kelvin: bluer)
                    <= SelfieLightScore.score(lux: lux, kelvin: cooler))
        }
    }
}
