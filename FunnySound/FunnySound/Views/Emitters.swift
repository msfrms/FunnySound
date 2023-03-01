import Foundation

enum Emiters {
    static func rain(_ text: String) -> ParticlesEmitter {
        ParticlesEmitter {
            EmitterCell()
                .image(text.image()!)
                .lifetime(10)
                .birthRate(50)
                .scale(0.5)
                .scaleRange(0.1)
                .spinRange(.pi * 3)
                .velocity(500)
                .velocityRange(250)
                .emissionLongitude(.pi)
    //            .emissionRange(.pi / 4)
        }
    }
}
