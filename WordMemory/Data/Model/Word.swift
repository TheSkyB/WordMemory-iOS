import Foundation

struct Word: Identifiable, Codable, Hashable {
    let id: Int64
    let word: String
    let phonetic: String
    let meaning: String
    let example: String
    let phrases: String
    let synonyms: String
    let relWords: String
    let bookId: Int64
    
    enum CodingKeys: String, CodingKey {
        case id, word, phonetic, meaning, example, phrases, synonyms
        case relWords = "rel_words"
        case bookId = "book_id"
    }
}

struct WordEntry: Codable {
    let word: String
    let phonetic: String?
    let meaning: String
    let example: String?
    let phrases: String?
    let synonyms: String?
    let relWords: String?
    
    enum CodingKeys: String, CodingKey {
        case word, phonetic, meaning, example, phrases, synonyms
        case relWords = "rel_words"
    }
}

enum StudyRating: Int, Codable, CaseIterable {
    case again = 1
    case hard = 3
    case good = 4
    
    var quality: Int { rawValue }
    
    var label: String {
        switch self {
        case .again: return "不认识"
        case .hard: return "模糊"
        case .good: return "认识"
        }
    }
    
    var colorName: String {
        switch self {
        case .again: return "red"
        case .hard: return "yellow"
        case .good: return "green"
        }
    }
}

enum SpellingOutcome: Int, Codable {
    case failed = 1
    case retrySuccess = 3
    case hinted = 4
    case perfect = 5
    
    var quality: Int { rawValue }
}

enum LearningMode {
    case recognition
    case spelling
}

enum AlgorithmVersion {
    case v3
    case v4
}
