import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession?
    
    @Published var isRecording = false
    @Published var recordingURL: URL?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        print("AudioRecorder: Starting recording")
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("\(Date().ISO8601Format()).m4a")
        print("Will save recording to: \(audioFilename)")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            try audioSession?.setActive(true)
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            recordingURL = audioFilename
            print("AudioRecorder: Recording started successfully")
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        print("AudioRecorder: Stopping recording")
        audioRecorder?.stop()
        
        // Verify the file exists and log its size
        if let url = recordingURL {
            print("Recording saved at: \(url)")
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                let fileSize = attributes[.size] as? UInt64 ?? 0
                print("Recording file size: \(fileSize) bytes")
            }
        }
        
        isRecording = false
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            if !flag {
                print("AudioRecorder: Recording failed")
            } else {
                print("AudioRecorder: Recording finished successfully")
            }
        }
    }
} 