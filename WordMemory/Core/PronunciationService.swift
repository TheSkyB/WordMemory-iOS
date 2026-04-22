import Foundation
import AVFoundation

class PronunciationService: ObservableObject {
    
    static let shared = PronunciationService()
    
    @Published var isPlaying = false
    @Published var currentWord: String?
    
    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    
    enum PronunciationSource: String, CaseIterable {
        case system = "系统语音"
        case freeDictionary = "Free Dictionary"
        case youdao = "有道"
        
        var icon: String {
            switch self {
            case .system: return "speaker.wave.2"
            case .freeDictionary: return "globe"
            case .youdao: return "character.book.closed"
            }
        }
    }
    
    @Published var currentSource: PronunciationSource = .system
    
    func pronounce(word: String) {
        currentWord = word
        
        switch currentSource {
        case .system:
            speakWithSystem(word: word)
        case .freeDictionary:
            playFromFreeDictionary(word: word)
        case .youdao:
            playFromYoudao(word: word)
        }
    }
    
    private func speakWithSystem(word: String) {
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        
        synthesizer.speak(utterance)
        isPlaying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isPlaying = false
        }
    }
    
    private func playFromFreeDictionary(word: String) {
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let first = json.first,
                  let phonetics = first["phonetics"] as? [[String: Any]] else {
                // Fallback to system
                DispatchQueue.main.async {
                    self?.speakWithSystem(word: word)
                }
                return
            }
            
            // Find audio URL
            let audioURL = phonetics.compactMap { $0["audio"] as? String }.first { !$0.isEmpty }
            
            if let audioURL = audioURL, let url = URL(string: audioURL) {
                self?.downloadAndPlay(url: url, fallbackWord: word)
            } else {
                DispatchQueue.main.async {
                    self?.speakWithSystem(word: word)
                }
            }
        }.resume()
    }
    
    private func playFromYoudao(word: String) {
        let urlString = "https://dict.youdao.com/dictvoice?type=2&audio=\(word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word)"
        
        guard let url = URL(string: urlString) else {
            speakWithSystem(word: word)
            return
        }
        
        downloadAndPlay(url: url, fallbackWord: word)
    }
    
    private func downloadAndPlay(url: URL, fallbackWord: String) {
        URLSession.shared.downloadTask(with: url) { [weak self] localURL, _, error in
            guard let localURL = localURL, error == nil else {
                DispatchQueue.main.async {
                    self?.speakWithSystem(word: fallbackWord)
                }
                return
            }
            
            do {
                let data = try Data(contentsOf: localURL)
                DispatchQueue.main.async {
                    self?.playAudio(data: data, fallbackWord: fallbackWord)
                }
            } catch {
                DispatchQueue.main.async {
                    self?.speakWithSystem(word: fallbackWord)
                }
            }
        }.resume()
    }
    
    private func playAudio(data: Data, fallbackWord: String) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()
            isPlaying = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.isPlaying = false
            }
        } catch {
            speakWithSystem(word: fallbackWord)
        }
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        audioPlayer?.stop()
        isPlaying = false
    }
}
