import Testing
@testable import LightMeter

struct SignalSmootherTests {

    @Test func convergence_toConstantInput() {
        var smoother = SignalSmoother(alpha: 0.2)
        let constantValue = 100.0
        
        // Initial update
        _ = smoother.update(0.0)
        
        // Feed constant input
        var lastOutput = 0.0
        for _ in 0..<50 {
            lastOutput = smoother.update(constantValue)
        }
        
        // It should converge to constantValue
        #expect(abs(lastOutput - constantValue) < 0.01)
    }

    @Test func boundedOutput_neverOvershootsRange() {
        var smoother = SignalSmoother(alpha: 0.3)
        
        // Feed various inputs within [10.0, 50.0]
        let inputs = [10.0, 20.0, 50.0, 30.0, 40.0, 15.0, 45.0]
        for input in inputs {
            let output = smoother.update(input)
            #expect(output >= 10.0)
            #expect(output <= 50.0)
        }
    }

    @Test func correctStepResponseDirection() {
        var smoother = SignalSmoother(alpha: 0.5)
        
        // First update sets lastValue to 50.0
        let first = smoother.update(50.0)
        #expect(first == 50.0)
        
        // Upward step: input 100.0. Output should be between 50.0 and 100.0 (exclusive)
        let upward = smoother.update(100.0)
        #expect(upward > 50.0)
        #expect(upward < 100.0)
        
        // Downward step: input 20.0. Output should be between 20.0 and upward (exclusive)
        let downward = smoother.update(20.0)
        #expect(downward < upward)
        #expect(downward > 20.0)
    }

    @Test func edgeValue_alphaZero() {
        var smoother = SignalSmoother(alpha: 0.0)
        
        // First value sets lastValue
        let first = smoother.update(10.0)
        #expect(first == 10.0)
        
        // Subsequent values should not change the output from 10.0
        #expect(smoother.update(20.0) == 10.0)
        #expect(smoother.update(100.0) == 10.0)
    }

    @Test func edgeValue_alphaOne() {
        var smoother = SignalSmoother(alpha: 1.0)
        
        // First value is returned as-is
        #expect(smoother.update(10.0) == 10.0)
        
        // Subsequent values should be returned instantly as-is
        #expect(smoother.update(20.0) == 20.0)
        #expect(smoother.update(100.0) == 100.0)
    }
    
    @Test func reset_clearsState() {
        var smoother = SignalSmoother(alpha: 0.5)
        
        _ = smoother.update(10.0)
        _ = smoother.update(20.0) // output is 15.0
        
        smoother.reset()
        
        // Since it's reset, the next update should treat it as first update and output 50.0 directly
        #expect(smoother.update(50.0) == 50.0)
    }

    @Test func rounding_toTwoSignificantFigures() {
        #expect(SignalSmoother.roundToTwoSignificantFigures(1234.5) == 1200.0)
        #expect(SignalSmoother.roundToTwoSignificantFigures(123.4) == 120.0)
        #expect(SignalSmoother.roundToTwoSignificantFigures(12.3) == 12.0)
        #expect(SignalSmoother.roundToTwoSignificantFigures(1.23) == 1.2)
        #expect(SignalSmoother.roundToTwoSignificantFigures(0.123) == 0.12)
        #expect(SignalSmoother.roundToTwoSignificantFigures(0.00345) == 0.0035)
        #expect(SignalSmoother.roundToTwoSignificantFigures(0.0) == 0.0)
        #expect(SignalSmoother.roundToTwoSignificantFigures(-123.4) == -120.0)
        #expect(SignalSmoother.roundToTwoSignificantFigures(99.9) == 100.0)
        #expect(SignalSmoother.roundToTwoSignificantFigures(10.0) == 10.0)
        #expect(SignalSmoother.roundToTwoSignificantFigures(1.0) == 1.0)
    }
}
