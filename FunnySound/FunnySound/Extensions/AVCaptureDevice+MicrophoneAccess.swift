import AVFoundation

extension AVCaptureDevice {
    static func ensureMicrophoneAccess() async -> Bool {
        switch Self.authorizationStatus(for: .audio) {
        case .notDetermined:
             return await Self.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        case .authorized:
            return true
        @unknown default:
            fatalError("unknown authorization status for microphone access")
        }
    }
}
