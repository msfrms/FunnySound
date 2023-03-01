import AVFoundation

final class SerialQueueAnalyzer: AudioBufferAnalyzer {
    private let queue: DispatchQueue
    private let analyzer: AudioBufferAnalyzer
    
    init(analyzer: AudioBufferAnalyzer, label: String = "com.msfrms.analyzer.private.queue") {
        queue = DispatchQueue(label: label)
        self.analyzer = analyzer
    }

    func analyze(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        queue.async { [weak self] in
            self?.analyzer.analyze(buffer: buffer, when: when)
        }
    }
    
    func stopAnalyze() {
        queue.async { [weak self] in
            self?.analyzer.stopAnalyze()
        }
    }
}
