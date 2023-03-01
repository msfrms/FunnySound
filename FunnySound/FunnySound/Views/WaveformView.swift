import SwiftUI

struct WaveformView: View {
    @State private var amplitude: CGFloat = 0.0
    @State private var phase: CGFloat = 0.0
    @State private var change: CGFloat = 0.0
    @State private var color = Color.green

    let amplitudeTracker: AmplitudeTracker
    
    var body: some View {
        MultiWave(amplitude: amplitude, color: color, phase: phase)
            .onAppear {
                let linearAnimation = Animation
                    .linear(duration: 0.1)
                    .repeatForever(autoreverses: false)

                withAnimation(linearAnimation) {
                    self.amplitude = _nextAmplitude()
                    self.phase -= 1.5
                }
            }
            .onAnimationCompleted(for: amplitude) {
                withAnimation(.linear(duration: 0.1)) {
                    self.amplitude = _nextAmplitude()
                    self.phase -= 1.5
                }
            }
    }
    
    private func _nextAmplitude() -> CGFloat {
        // If the amplitude is too low or too high, cap it and go in the other direction.
        if self.amplitude <= 0.01 {
            self.change = 0.1
            return 0.02
        } else if self.amplitude > 0.9 {
            self.change = -0.1
            return 0.9
        }
        
        // Simply set the amplitude to whatever you need and the view will update itself.
        let newAmplitude = CGFloat(amplitudeTracker.fetchAmplitude())

        return max(0.01, newAmplitude)
    }

}
