import Foundation
import SwiftUI

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var audioRecorder = AudioRecorder()
    @Published var transcription: String = ""
    @Published var summary: String = ""
    @Published var isProcessing = false
    @Published var error: String?
    
    private let openAIService = OpenAIService()
    
    func startRecording() {
        print("ViewModel: Starting recording")
        error = nil
        audioRecorder.startRecording()
    }
    
    func stopRecording() {
        print("ViewModel: Stopping recording")
        if audioRecorder.isRecording {
            audioRecorder.stopRecording()
            processRecording()
        }
    }
    
    private func processRecording() {
        guard let recordingURL = audioRecorder.recordingURL else {
            error = "No recording URL found"
            return
        }
        
        Task {
            isProcessing = true
            do {
                print("Attempting to read audio file at: \(recordingURL)")
                guard FileManager.default.fileExists(atPath: recordingURL.path) else {
                    error = "Recording file does not exist at location"
                    isProcessing = false
                    return
                }
                
                let audioData = try Data(contentsOf: recordingURL)
                print("Audio data size: \(audioData.count) bytes")
                transcription = try await openAIService.transcribeAudio(audioData: audioData)
                summary = try await openAIService.summarizeText(transcription)
                SummariesStore.shared.addSummary(summary)
                try FileManager.default.removeItem(at: recordingURL)
            } catch {
                print("Detailed error: \(error)")
                self.error = "Error processing audio: \(error.localizedDescription)"
            }
            isProcessing = false
        }
    }
} 