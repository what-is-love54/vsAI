import Foundation
import AVFoundation
import React

@objc(AudioRecorder)
class AudioRecorder: RCTEventEmitter {
    
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?
    private var currentRecordingPath: String?
    private var recordingTimer: Timer?
    private var playbackTimer: Timer?
    private var isCurrentlyRecording = false
    private var isCurrentlyPlaying = false
    private var isPaused = false
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - RCTEventEmitter
    override func supportedEvents() -> [String]! {
        return [
            "onRecordingStarted",
            "onRecordingStopped",
            "onRecordingPaused",
            "onRecordingResumed",
            "onRecordingProgress",
            "onRecordingError",
            "onPlaybackStarted",
            "onPlaybackStopped",
            "onPlaybackPaused",
            "onPlaybackResumed",
            "onPlaybackProgress",
            "onPlaybackCompleted",
            "onPlaybackError"
        ]
    }
    
    override static func requiresMainQueueSetup() -> Bool {
        return false
    }
    
    override func constantsToExport() -> [AnyHashable : Any]! {
        return [:]
    }
    
    // MARK: - Recording Methods
    @objc(startRecording:reject:)
    func startRecording(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard !self.isCurrentlyRecording else {
                reject("ALREADY_RECORDING", "Recording is already in progress", nil)
                return
            }
            
            let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
            let documentsPath = self.getRecordingsDirectoryPath()
            let filePath = (documentsPath as NSString).appendingPathComponent(fileName)
            
            let url = URL(fileURLWithPath: filePath)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                try self.recordingSession?.setActive(true)
                self.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                self.audioRecorder?.isMeteringEnabled = true
                self.audioRecorder?.record()
                
                self.currentRecordingPath = filePath
                self.isCurrentlyRecording = true
                self.isPaused = false
                
                self.startRecordingTimer()
                self.sendEvent(withName: "onRecordingStarted", body: ["filePath": filePath])
                
                resolve(filePath)
            } catch {
                reject("RECORDING_ERROR", "Failed to start recording: \(error.localizedDescription)", error)
            }
        }
    }
    
    @objc(stopRecording:reject:)
    func stopRecording(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.isCurrentlyRecording, let recorder = self.audioRecorder else {
                reject("NOT_RECORDING", "No recording in progress", nil)
                return
            }
            
            self.stopRecordingTimer()
            recorder.stop()
            
            let filePath = self.currentRecordingPath ?? ""
            self.isCurrentlyRecording = false
            self.isPaused = false
            
            self.sendEvent(withName: "onRecordingStopped", body: [
                "filePath": filePath,
                "duration": recorder.currentTime
            ])
            
            resolve(filePath)
        }
    }
    
    @objc(pauseRecording:reject:)
    func pauseRecording(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.isCurrentlyRecording, let recorder = self.audioRecorder else {
                reject("NOT_RECORDING", "No recording in progress", nil)
                return
            }
            
            recorder.pause()
            self.isPaused = true
            self.stopRecordingTimer()
            
            self.sendEvent(withName: "onRecordingPaused", body: [
                "duration": recorder.currentTime
            ])
            
            resolve(nil)
        }
    }
    
    @objc(resumeRecording:reject:)
    func resumeRecording(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.isCurrentlyRecording, self.isPaused, let recorder = self.audioRecorder else {
                reject("NOT_PAUSED", "Recording is not paused", nil)
                return
            }
            
            recorder.record()
            self.isPaused = false
            self.startRecordingTimer()
            
            self.sendEvent(withName: "onRecordingResumed", body: nil)
            
            resolve(nil)
        }
    }
    
    @objc(cancelRecording:reject:)
    func cancelRecording(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.stopRecordingTimer()
            self.audioRecorder?.stop()
            
            if let path = self.currentRecordingPath {
                try? FileManager.default.removeItem(atPath: path)
            }
            
            self.isCurrentlyRecording = false
            self.isPaused = false
            self.currentRecordingPath = nil
            self.audioRecorder = nil
            
            resolve(nil)
        }
    }
    
    // MARK: - Playback Methods
    @objc(playRecording:resolve:reject:)
    func playRecording(_ filePath: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let url = URL(fileURLWithPath: filePath)
            
            guard FileManager.default.fileExists(atPath: filePath) else {
                reject("FILE_NOT_FOUND", "Audio file not found at path: \(filePath)", nil)
                return
            }
            
            do {
                try self.recordingSession?.setCategory(.playback, mode: .default)
                try self.recordingSession?.setActive(true)
                
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.delegate = self
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
                
                self.isCurrentlyPlaying = true
                self.startPlaybackTimer()
                
                self.sendEvent(withName: "onPlaybackStarted", body: [
                    "filePath": filePath,
                    "duration": self.audioPlayer?.duration ?? 0
                ])
                
                resolve(nil)
            } catch {
                reject("PLAYBACK_ERROR", "Failed to play recording: \(error.localizedDescription)", error)
            }
        }
    }
    
    @objc(stopPlayback:reject:)
    func stopPlayback(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.stopPlaybackTimer()
            self.audioPlayer?.stop()
            self.audioPlayer?.currentTime = 0
            self.isCurrentlyPlaying = false
            
            self.sendEvent(withName: "onPlaybackStopped", body: nil)
            
            resolve(nil)
        }
    }
    
    @objc(pausePlayback:reject:)
    func pausePlayback(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard self.isCurrentlyPlaying, let player = self.audioPlayer else {
                reject("NOT_PLAYING", "No playback in progress", nil)
                return
            }
            
            player.pause()
            self.stopPlaybackTimer()
            
            self.sendEvent(withName: "onPlaybackPaused", body: [
                "currentTime": player.currentTime
            ])
            
            resolve(nil)
        }
    }
    
    @objc(resumePlayback:reject:)
    func resumePlayback(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            guard let player = self.audioPlayer else {
                reject("NOT_PAUSED", "No playback to resume", nil)
                return
            }
            
            player.play()
            self.isCurrentlyPlaying = true
            self.startPlaybackTimer()
            
            self.sendEvent(withName: "onPlaybackResumed", body: nil)
            
            resolve(nil)
        }
    }
    
    // MARK: - Status Methods
    @objc(isRecording:reject:)
    func isRecording(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(isCurrentlyRecording)
    }
    
    @objc(isPlaying:reject:)
    func isPlaying(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(isCurrentlyPlaying)
    }
    
    @objc(getRecordingDuration:reject:)
    func getRecordingDuration(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(audioRecorder?.currentTime ?? 0)
    }
    
    @objc(getPlaybackDuration:reject:)
    func getPlaybackDuration(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(audioPlayer?.duration ?? 0)
    }
    
    @objc(getPlaybackCurrentTime:reject:)
    func getPlaybackCurrentTime(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(audioPlayer?.currentTime ?? 0)
    }
    
    // MARK: - Permission Methods
    @objc(requestPermissions:reject:)
    func requestPermissions(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                resolve(granted)
            }
        }
    }
    
    @objc(hasPermissions:reject:)
    func hasPermissions(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let permission = AVAudioSession.sharedInstance().recordPermission
        resolve(permission == .granted)
    }
    
    // MARK: - File Management
    @objc(getRecordingsDirectory:reject:)
    func getRecordingsDirectory(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(getRecordingsDirectoryPath())
    }
    
    @objc(deleteRecording:resolve:reject:)
    func deleteRecording(_ filePath: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        do {
            try FileManager.default.removeItem(atPath: filePath)
            resolve(true)
        } catch {
            reject("DELETE_ERROR", "Failed to delete recording: \(error.localizedDescription)", error)
        }
    }
    
    // MARK: - Helper Methods
    private func getRecordingsDirectoryPath() -> String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let recordingsPath = paths[0].appendingPathComponent("recordings").path
        
        if !FileManager.default.fileExists(atPath: recordingsPath) {
            try? FileManager.default.createDirectory(atPath: recordingsPath, withIntermediateDirectories: true)
        }
        
        return recordingsPath
    }
    
    private func startRecordingTimer() {
        stopRecordingTimer()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            self.sendEvent(withName: "onRecordingProgress", body: [
                "duration": recorder.currentTime,
                "filePath": self.currentRecordingPath ?? ""
            ])
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.sendEvent(withName: "onPlaybackProgress", body: [
                "currentTime": player.currentTime,
                "duration": player.duration,
                "filePath": player.url?.path ?? ""
            ])
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioRecorder: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.stopPlaybackTimer()
            self?.isCurrentlyPlaying = false
            self?.sendEvent(withName: "onPlaybackCompleted", body: [
                "filePath": player.url?.path ?? "",
                "success": flag
            ])
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.stopPlaybackTimer()
            self?.isCurrentlyPlaying = false
            self?.sendEvent(withName: "onPlaybackError", body: [
                "message": error?.localizedDescription ?? "Unknown error",
                "code": "DECODE_ERROR"
            ])
        }
    }
}