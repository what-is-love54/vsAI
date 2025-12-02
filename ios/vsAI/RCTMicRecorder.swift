import Foundation
import AVFoundation

@objc(MicRecorder)
class MicRecorder: NSObject {
    @objc static let shared = MicRecorder()

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioFileURL: URL?
    private var isRecording = false
  
    typealias MicRecorderCompletionBlock = (NSError?) -> Void

    @objc(startRecordingWithCompletion:)
    func start(completion: @escaping MicRecorderCompletionBlock) {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            completion(error as NSError)
            return
        }

        session.requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if !allowed {
                    let err = NSError(
                        domain: "MicRecorder",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"]
                    )
                    completion(err)
                    return
                }

                if self.isRecording {
                    let err = NSError(
                        domain: "MicRecorder",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Recording already in progress"]
                    )
                    completion(err)
                    return
                }

                let tmpDir = FileManager.default.temporaryDirectory
                let filename = "mic_recording_\(Int(Date().timeIntervalSince1970)).m4a"
                let url = tmpDir.appendingPathComponent(filename)

                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]

                do {
                    let recorder = try AVAudioRecorder(url: url, settings: settings)
                    recorder.prepareToRecord()
                    recorder.record()

                    self.audioFileURL = url
                    self.audioRecorder = recorder
                    self.isRecording = true

                    completion(nil)
                } catch {
                    completion(error as NSError)
                }
            }
        }
    }

  @objc(stopRecordingWithCompletion:)
    func stop(completion: @escaping MicRecorderCompletionBlock) {
        guard isRecording, let recorder = audioRecorder else {
            let err = NSError(
                domain: "MicRecorder",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "No active recording"]
            )
            completion(err)
            return
        }

        recorder.stop()
        audioRecorder = nil
        isRecording = false

        guard let url = audioFileURL else {
            let err = NSError(
                domain: "MicRecorder",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "No recorded file"]
            )
            completion(err)
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioPlayer = player
            player.delegate = self
            player.prepareToPlay()
            player.play()
            completion(nil)
        } catch {
            completion(error as NSError)
        }
    }
}

extension MicRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
    }
}
