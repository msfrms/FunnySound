import Accelerate
import AVFoundation

final class AmplitudeAnalyzer: AudioBufferAnalyzer {

    private(set) var amplitude: Float = 0.2
    private var amp: [Int: Float] = [:]
    

    func analyze(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        guard let floatData = buffer.floatChannelData else {
            return
        }

        let channelCount = Int(buffer.format.channelCount)
        let length = UInt(buffer.frameLength)

        // n is the channel
        for n in 0 ..< channelCount {
            let data = floatData[n]
            var rms: Float = 0
            vDSP_rmsqv(data, 1, &rms, UInt(length))
            amp[n] = rms
        }

        let newAmplitude = (amp.values.reduce(0, +) / Float(channelCount)) * 10

        guard !newAmplitude.isNaN else {
            amplitude = 0.2
            return
        }

        amplitude = min(newAmplitude, 0.8 - Float.random(in: 0.1..<0.2))
    }
    
    func stopAnalyze() {
        amplitude = 0.2
        amp = [:]
    }
}
