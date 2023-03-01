import UIKit
import AVFoundation
import Combine

final class RainEmojiViewModel: ObservableObject {
    typealias Errors = SoundAnalysisInteractor.Errors
    typealias Classification = SoundClassificationAnalyzer.Classification
    
    enum State {
        struct Emoji {
            let text: String
            let classification: Classification
        }
        enum Show {
            case waveform
            case rain(emoji: Emoji)
        }
        case failed
        case noMicrophoneAccess
        case inProgress
        case show(Show)
    }
    
    @Published
    private(set) var state: State = .inProgress
    private let soundAnalysisInteractor = SoundAnalysisInteractor()
    private var cancellables: [AnyCancellable] = []
    private var classificationCancellable: AnyCancellable?
    private var hiddingRainEmojiTimer: Timer?
    private var isAudioSessionStarted: Bool = false

    func onRetry() {
        self.state = .inProgress
        registerHandlers()
    }
    
    func onAppear() {
        startObservingAppLifecycle()
        startObservingAudioSessionErrors()
        registerHandlers()
    }
    
    private func registerHandlers() {
        guard !isAudioSessionStarted else {
            return
        }
        isAudioSessionStarted = true
        subscribeToSoundSignalClassifier()
        startingSoundSignalMonitoring()
    }
    
    private func unregisterHandlers() {
        isAudioSessionStarted = false
        soundAnalysisInteractor.stopAnalyzing()
        classificationCancellable?.cancel()
        hiddingRainEmojiTimer?.invalidate()
    }
    
    private func startObservingAppLifecycle() {
        let center = NotificationCenter.default

        center
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.unregisterHandlers()
                self?.state = .inProgress
            }
            .store(in: &cancellables)
        
        center
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.registerHandlers()
            }
            .store(in: &cancellables)
    }
    
    private func startObservingAudioSessionErrors() {
        let center = NotificationCenter.default

        let audioSessionErrorsPublisher = center
            .publisher(for: AVAudioSession.interruptionNotification)
            .merge(with: center.publisher(for: AVAudioSession.mediaServicesWereLostNotification))
        
        audioSessionErrorsPublisher
            .sink { [weak self] _ in
                self?.unregisterHandlers()
                self?.state = .failed
            }
            .store(in: &cancellables)
    }
    
    private func startingSoundSignalMonitoring(attempts: Int = 3) {
        Task { @MainActor in
            do {
                try await soundAnalysisInteractor.startAnalyzing()
                self.state = .show(.waveform)
            } catch Errors.noMicrophoneAccess {
                self.state = .noMicrophoneAccess
                self.isAudioSessionStarted = false
            } catch {
                self.unregisterHandlers()
                self.state = .failed
            }
        }
    }
    
    private func startTimerToHideRainEmoji() {
        hiddingRainEmojiTimer?.invalidate()
        hiddingRainEmojiTimer = Timer.scheduledTimer(
            withTimeInterval: 5,
            repeats: false,
            block: { [weak self] _ in
                self?.state = .show(.waveform)
            }
        )
    }
    
    private func subscribeToSoundSignalClassifier() {
        classificationCancellable?.cancel()
        classificationCancellable = soundAnalysisInteractor.$classification
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] result in
                guard let self = self else {
                    return
                }
                switch result {
                case let .success(classification):
                    guard let text = classification.emoji else {
                        return
                    }
                    self.startTimerToHideRainEmoji()
                    let emoji: State.Emoji = State.Emoji(text: text, classification: classification)
                    self.state = .show(.rain(emoji: emoji))

                case .failure:
                    break
                }
            }
    }
}

extension RainEmojiViewModel: AmplitudeTracker {
    func fetchAmplitude() -> Float {
        soundAnalysisInteractor.fetchAmplitude()
    }
}

private extension RainEmojiViewModel.Classification {
    var emoji: String? {
        switch self {
        case .unknown:
            return nil
        case .babyLaughter, .laughter:
            return "😂"
        case .speech:
            return "💬"
        case .music:
            return "🎵"
        case .typingKeyboard:
            return "⌨️"
        }
    }
}
