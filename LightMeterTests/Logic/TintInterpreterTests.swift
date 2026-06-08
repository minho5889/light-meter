import Testing
@testable import LightMeter

struct TintInterpreterTests {

    @Test func ranges_english() {
        let green = TintInterpreter.interpret(tint: -15.0, language: .english)
        #expect(green.description == "Green Tint 🟢")
        #expect(green.tip == "Fluorescent or green-cast lighting. Can look sickly.")

        let neutral = TintInterpreter.interpret(tint: 0.0, language: .english)
        #expect(neutral.description == "Neutral ⚪")
        #expect(neutral.tip == "Balanced tint. Excellent color rendering.")

        let magenta = TintInterpreter.interpret(tint: 15.0, language: .english)
        #expect(magenta.description == "Magenta Tint 🟣")
        #expect(magenta.tip == "Magenta or reddish-cast lighting. Common in some LED lights.")
    }

    @Test func ranges_korean() {
        let green = TintInterpreter.interpret(tint: -15.0, language: .korean)
        #expect(green.description == "초록빛 (그린) 🟢")
        #expect(green.tip == "형광등이나 녹색조 조명입니다. 피부톤이 아파 보일 수 있습니다.")

        let neutral = TintInterpreter.interpret(tint: 0.0, language: .korean)
        #expect(neutral.description == "보통 (중립) ⚪")
        #expect(neutral.tip == "균형 잡힌 색조입니다. 우수한 색 재현력.")

        let magenta = TintInterpreter.interpret(tint: 15.0, language: .korean)
        #expect(magenta.description == "자줏빛 (마젠타) 🟣")
        #expect(magenta.tip == "자줏빛이나 붉은 조명입니다. 일부 LED 등에서 자주 보입니다.")
    }

    @Test func ranges_french() {
        let green = TintInterpreter.interpret(tint: -15.0, language: .french)
        #expect(green.description == "Teinte Verte 🟢")
        #expect(green.tip == "Éclairage fluorescent ou verdâtre. Peut donner un teint terne.")

        let neutral = TintInterpreter.interpret(tint: 0.0, language: .french)
        #expect(neutral.description == "Neutre ⚪")
        #expect(neutral.tip == "Teinte équilibrée. Excellent rendu des couleurs.")

        let magenta = TintInterpreter.interpret(tint: 15.0, language: .french)
        #expect(magenta.description == "Teinte Magenta 🟣")
        #expect(magenta.tip == "Éclairage magenta ou rougeâtre. Courant sur certaines LED.")
    }

    @Test func boundaries() {
        // Magenta boundary
        #expect(TintInterpreter.interpret(tint: 10.0, language: .english).description == "Neutral ⚪")
        #expect(TintInterpreter.interpret(tint: 10.0001, language: .english).description == "Magenta Tint 🟣")

        // Green boundary
        #expect(TintInterpreter.interpret(tint: -10.0, language: .english).description == "Neutral ⚪")
        #expect(TintInterpreter.interpret(tint: -10.0001, language: .english).description == "Green Tint 🟢")
    }

    @Test func property_tintInterpretationConsistency() {
        var rng = SystemRandomNumberGenerator()

        for _ in 0..<100 {
            let tint = Double.random(in: -150.0...150.0, using: &rng)
            let result1 = TintInterpreter.interpret(tint: tint, language: .english)
            let result2 = TintInterpreter.interpret(tint: tint, language: .english)

            #expect(!result1.description.isEmpty)
            #expect(!result1.tip.isEmpty)
            #expect(result1 == result2)
        }
    }
}
