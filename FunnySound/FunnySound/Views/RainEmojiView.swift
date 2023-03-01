import SwiftUI

struct RainEmojiView: View {
    typealias Classification = RainEmojiViewModel.Classification
    
    @StateObject var viewModel: RainEmojiViewModel = RainEmojiViewModel()
    
    var body: some View {
        VStack {
            Spacer()
            Group {
                switch viewModel.state {

                case .inProgress: loading

                case .failed: unknownError
                    
                case .noMicrophoneAccess: microphonePermission

                case .show(.waveform): waveform

                case let .show(.rain(emoji)): emoji.classification.asView.overlay(rain(emoji.text))
                }
            }
            Spacer()
        }
        .onAppear(perform: viewModel.onAppear)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
    }
}

private extension RainEmojiView {
    @ViewBuilder
    var loading: some View {
        Color.white
            .overlay(
                LottieView(name: "loader").frame(width: 88, height: 88)
            )
    }
    
    @ViewBuilder
    var unknownError: some View {
        ErrorView(
            description: "Упс, произошло то, чего мы никак не ожидали ☔",
            button: .init(
                title: "Попробовать снова",
                action: viewModel.onRetry
            )
        )
    }
    
    @ViewBuilder
    var microphonePermission: some View {
        MicrophonePermissionView(
            description: "Чтобы воспользоваться приложением разрешите доступ к микрофону",
            button: .init(
                title: "Перейти в Настройки",
                action: {
                    guard let settingURL = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    guard UIApplication.shared.canOpenURL(settingURL) else {
                        return
                    }
                    UIApplication.shared.open(settingURL)
                }
            )
        )
    }
    
    @ViewBuilder
    var waveform: some View {
        GeometryReader { geometry in
            let size = geometry.size
            WaveformView(amplitudeTracker: viewModel)
                .frame(width: size.width, height: size.height)
        }
    }

    func rain(_ emoji: String) -> some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            Emiters.rain(emoji)
                .emitterSize(size)
                .emitterPosition(CGPoint(x: size.width / 2.0, y: 0))
                .emitterShape(.line)
                .frame(width: size.width, height: size.height)
        }
    }
}

private extension RainEmojiViewModel.Classification {
    @ViewBuilder
    var asView: some View {
        GeometryReader { geometry in
            let size = geometry.size
            Color.white
                .frame(width: size.width, height: size.height)
                .overlay(
                    Group {
                        switch self {
                        case .typingKeyboard:
                            LottieView(name: "keyboard")
                                .frame(height: 150)
                        case .laughter, .babyLaughter:
                            LottieView(name: "laughing")
                                .frame(height: 150)
                        case .music:
                            LottieView(name: "music")
                                .frame(width: 300, height: 300)
                        case .speech:
                            LottieView(name: "speech")
                                .frame(height: 150)
                        case .unknown:
                            EmptyView()
                        }
                    }
                )
        }
    }
}
