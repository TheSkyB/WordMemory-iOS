import Foundation

enum AIRequestType: String {
    case exampleSentence = "EXAMPLE_SENTENCE"
    case memoryAid = "MEMORY_AID"
    case wordAnalysis = "WORD_ANALYSIS"
}

struct AIResponse: Codable {
    let content: String
    let type: String
}

class AIService {
    
    static let shared = AIService()
    
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "ai_api_key") ?? ""
    }
    private let baseURL = "https://api.deepseek.com/v1/chat/completions"
    
    private init() {}
    
    static func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "ai_api_key")
    }
    
    func generateExampleSentence(for word: String, meaning: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        请为单词 "\(word)"（\(meaning)）生成一个地道的英文例句，并附上中文翻译。
        例句要简洁实用，适合考研英语学习。
        只返回例句和翻译，不要其他内容。
        """
        
        sendRequest(prompt: prompt, type: .exampleSentence, completion: completion)
    }
    
    func generateMemoryAid(for word: String, meaning: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        请为单词 "\(word)"（\(meaning)）提供一个有趣的记忆方法或词根词缀分析。
        可以是谐音联想、词根拆解、场景联想等，帮助记忆。
        控制在100字以内。
        """
        
        sendRequest(prompt: prompt, type: .memoryAid, completion: completion)
    }
    
    func analyzeWord(word: String, completion: @escaping (Result<String, Error>) -> Void) {
        let prompt = """
        请分析单词 "\(word)" 的词源、常见搭配、同义词辨析和考研真题出现频率。
        用简洁的格式输出，适合快速复习。
        """
        
        sendRequest(prompt: prompt, type: .wordAnalysis, completion: completion)
    }
    
    private func sendRequest(prompt: String, type: AIRequestType, completion: @escaping (Result<String, Error>) -> Void) {
        guard !apiKey.isEmpty else {
            completion(.failure(AIError.noAPIKey))
            return
        }
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                ["role": "system", "content": "你是一个专业的英语词汇助手，擅长帮助考研学生记忆单词。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 300
        ]
        
        guard let url = URL(string: baseURL),
              let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(AIError.invalidRequest))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(AIError.noData))
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let message = first["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        completion(.success(content))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.failure(AIError.invalidResponse))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    enum AIError: Error, LocalizedError {
        case noAPIKey
        case invalidRequest
        case noData
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "未设置 API Key，请在设置中配置"
            case .invalidRequest: return "请求格式错误"
            case .noData: return "未收到响应数据"
            case .invalidResponse: return "响应解析失败"
            }
        }
    }
}
