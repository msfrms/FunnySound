import AVFoundation
import Combine

final class SoundAnalysisInteractor {
    typealias Classification = SoundClassificationAnalyzer.Classification

    enum Errors: Error {
        case audioStreamInterrupted
        case noMicrophoneAccess
    }

    private var audioEngine: AVAudioEngine?
    private let amplitudeAnalyzer = AmplitudeAnalyzer()
    private var classificationAnalyzer: AudioBufferAnalyzer?
    
    @Published
    private(set) var classification: Result<Classification, Error> = .success(.unknown)

    private func startAudioSession() throws {
        stopAudioSession()
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            stopAudioSession()
            throw error
        }
    }

    private func stopAudioSession() {
        autoreleasepool {
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setActive(false)
        }
    }
    
    func startAnalyzing() async throws {
        let isMicrophoneAccess = await AVCaptureDevice.ensureMicrophoneAccess()
        
        guard isMicrophoneAccess else {
            throw Errors.noMicrophoneAccess
        }
        
        try startAudioSession()
        
        audioEngine = AVAudioEngine()

        let busIndex = AVAudioNodeBus(0)
        let bufferSize = AVAudioFrameCount(4096)

        guard let audioFormat = audioEngine?.inputNode.outputFormat(forBus: busIndex) else {
            return
        }
        
        let soundAnalyzer = try SoundClassificationAnalyzer(format: audioFormat)
        
        soundAnalyzer.$result.assign(to: &$classification)

        classificationAnalyzer = SerialQueueAnalyzer(analyzer: soundAnalyzer)
        
        audioEngine?.inputNode.installTap(
            onBus: busIndex,
            bufferSize: bufferSize,
            format: audioFormat,
            block: { [weak self] (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
                self?.amplitudeAnalyzer.analyze(buffer: buffer, when: when)
                self?.classificationAnalyzer?.analyze(buffer: buffer, when: when)
            }
        )
        
        try audioEngine?.start()
    }
    
    func stopAnalyzing() {
        autoreleasepool {
            if let audioEngine = audioEngine {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
            }

            classificationAnalyzer?.stopAnalyze()
            amplitudeAnalyzer.stopAnalyze()

            classificationAnalyzer = nil
            audioEngine = nil
        }
        stopAudioSession()
    }
}

extension SoundAnalysisInteractor: AmplitudeTracker {
    func fetchAmplitude() -> Float {
        amplitudeAnalyzer.amplitude
    }
}
