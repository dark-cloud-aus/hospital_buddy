import Foundation

class OpenAIService {
    private let apiKey = Config.openAIKey
    private let baseURL = "https://api.openai.com/v1"
    
    func transcribeAudio(audioData: Data) async throws -> String {
        let url = URL(string: "\(baseURL)/audio/transcriptions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)
        
        // Add language parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("en\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Print the response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("API Response: \(responseString)")
        }
        
        // Check if we got an error response
        if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data),
           let error = errorResponse.error {
            throw NSError(domain: "OpenAI",
                         code: 400,
                         userInfo: [NSLocalizedDescriptionKey: error.message])
        }
        
        // Try to decode the success response
        let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return transcriptionResponse.text
    }
    
    func summarizeText(_ text: String) async throws -> String {
        let prompt = """
        Please provide a clear and concise medical summary of this conversation. 
        Include the key points about diagnosis, current status, and any treatment plans or medications prescribed.
        Make it easy to read and understand.

        Here's the conversation:
        \(text)
        """
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return response.choices.first?.message.content ?? "No summary available"
    }
}

struct TranscriptionResponse: Codable {
    let text: String
}

struct ChatCompletionResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

// Add this new structure to handle potential errors
struct OpenAIErrorResponse: Codable {
    let error: OpenAIError?
}

struct OpenAIError: Codable {
    let message: String
    let type: String?
} 