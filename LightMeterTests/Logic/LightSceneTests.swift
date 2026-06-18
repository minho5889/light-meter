import Testing
@testable import LightMeter

struct LightSceneTests {

    // MARK: - Known values

    @Test func closestAtMidpointIsSelf() {
        // Each scene's own midpoint should map back to that scene.
        for scene in LightScene.all {
            let match = LightScene.closest(lux: scene.luxMid, kelvin: scene.kelvinMid)
            #expect(match.id == scene.id)
        }
    }

    // MARK: - Property 1: closest always returns a real scene

    @Test func property_closestAlwaysValid() {
        var rng = SystemRandomNumberGenerator()
        let ids = Set(LightScene.all.map { $0.id })
        for _ in 0..<200 {
            let match = LightScene.closest(lux: Double.random(in: 0...5000, using: &rng),
                                           kelvin: Double.random(in: 1000...10000, using: &rng))
            #expect(ids.contains(match.id))
        }
    }

    // MARK: - Property 2: distance is never negative

    @Test func property_distanceNonNegative() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let scene = LightScene.all.randomElement(using: &rng)!
            let d = scene.distance(lux: Double.random(in: 0...5000, using: &rng),
                                   kelvin: Double.random(in: 1000...10000, using: &rng))
            #expect(d >= 0)
        }
    }

    // MARK: - Property 3: adjustment direction matches the range comparison

    @Test func property_adjustDirectionMatchesRange() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<300 {
            let scene = LightScene.all.randomElement(using: &rng)!
            let lux = Double.random(in: 0...5000, using: &rng)
            let kelvin = Double.random(in: 1000...10000, using: &rng)

            let b = scene.brightnessAdjust(lux: lux)
            if lux < scene.lux.lowerBound { #expect(b == .increase) }
            else if lux > scene.lux.upperBound { #expect(b == .decrease) }
            else { #expect(b == .ok) }

            let w = scene.warmthAdjust(kelvin: kelvin)
            if kelvin > scene.kelvin.upperBound { #expect(w == .increase) }
            else if kelvin < scene.kelvin.lowerBound { #expect(w == .decrease) }
            else { #expect(w == .ok) }
        }
    }

    // MARK: - Property 4: a reading inside a scene's ranges needs no change

    @Test func property_inRangeNeedsNoAdjustment() {
        var rng = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let scene = LightScene.all.randomElement(using: &rng)!
            let lux = Double.random(in: scene.lux.lowerBound...scene.lux.upperBound, using: &rng)
            let kelvin = Double.random(in: scene.kelvin.lowerBound...scene.kelvin.upperBound, using: &rng)
            #expect(scene.brightnessAdjust(lux: lux) == .ok)
            #expect(scene.warmthAdjust(kelvin: kelvin) == .ok)
        }
    }
}
