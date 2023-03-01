import AVFoundation
import SoundAnalysis

final class SoundClassificationAnalyzer: NSObject, AudioBufferAnalyzer {
    
    enum Errors: Error {
        case invalidFormatException
    }

    enum Classification: String {
        case typingKeyboard = "typing_computer_keyboard"
        case music = "music"
        case laughter = "laughter"
        case babyLaughter = "baby_laughter"
        case speech = "speech"
        case unknown = "unknown"
    }

    @Published
    private(set) var result: Result<Classification, Error> = .success(.unknown)

    private let analyzer: SNAudioStreamAnalyzer

    init(format: AVAudioFormat) throws {
        guard format.channelCount > 0, format.sampleRate > 0.0 else {
            throw Errors.invalidFormatException
        }

        analyzer = SNAudioStreamAnalyzer(format: format)

        super.init()

        let classifications: [Classification] = [
            .laughter,
            .typingKeyboard,
            .speech,
            .music
        ]
        
        let requests = try classifications.map { classification in
            let config = classification.config
            
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            request.windowDuration = CMTimeMakeWithSeconds(Float64(config.windowDuration), preferredTimescale: 48_000)
            request.overlapFactor = Double(config.overlapFactor)
            
            return request
        }

        try requests.forEach {
            try analyzer.add($0, withObserver: self)
        }
    }

    func analyze(buffer: AVAudioPCMBuffer, when: AVAudioTime) {
        analyzer.analyze(buffer, atAudioFramePosition: when.sampleTime)
    }
    
    func stopAnalyze() {
        analyzer.removeAllRequests()
    }
}

extension SoundClassificationAnalyzer: SNResultsObserving {

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else {
            return
        }

        let classifications = result.classifications
        let bestClassification = Classification(
            foundClasses: classifications
        )
        
        guard let bestClassification = bestClassification else {
            return
        }
        
        self.result = .success(bestClassification)
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        result = .failure(error)
    }
}

extension SoundClassificationAnalyzer.Classification: CaseIterable {
    typealias Classification = SoundClassificationAnalyzer.Classification

    fileprivate init?(foundClasses: [SNClassification]) {
        let classesOfInterest = Set(Classification.allCases.map { $0.rawValue })
        let bestClassesOfInterest = foundClasses
            .filter { classesOfInterest.contains($0.identifier) }
            .sorted { $0.confidence > $1.confidence }

        guard let bestClass = bestClassesOfInterest.first else {
            return nil
        }

        guard let bestClassification = Classification(rawValue: bestClass.identifier) else {
            return nil
        }
        
        let preferredPrecision = Double(bestClassification.config.precision)
        
        guard bestClass.confidence >= preferredPrecision else {
            return nil
        }

        self = bestClassification
    }
}

private extension SoundClassificationAnalyzer.Classification {
    struct Config {
        let windowDuration: Float
        let overlapFactor: Float
        let precision: Float
    }

    var config: Config {
        switch self {
        case .typingKeyboard:
            return Config(windowDuration: 1.5, overlapFactor: 0.9, precision: 0.75)
        case .music:
            return Config(windowDuration: 3.0, overlapFactor: 0.9, precision: 0.75)
        case .laughter, .babyLaughter:
            return Config(windowDuration: 2.0, overlapFactor: 0.9, precision: 0.8)
        case .speech:
            return Config(windowDuration: 2.0, overlapFactor: 0.9, precision: 0.75)
        case .unknown:
            return Config(windowDuration: 1.5, overlapFactor: 0.9, precision: 0.9)
        }
    }
}
