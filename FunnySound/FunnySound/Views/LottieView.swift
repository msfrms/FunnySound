import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    
    private let animationView = LottieAnimationView()
    let name: String
    
    func makeUIView(context: Context) -> LottieAnimationView {
        animationView.animation = LottieAnimation.named(name)
        animationView.loopMode = .loop
        
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        guard !animationView.isAnimationPlaying else {
            return
        }
        animationView.play()
    }
}
