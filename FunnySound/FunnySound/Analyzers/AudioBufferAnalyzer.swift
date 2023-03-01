import AVFoundation

protocol AudioBufferAnalyzer {
    func analyze(buffer: AVAudioPCMBuffer, when: AVAudioTime)
    func stopAnalyze()
}
