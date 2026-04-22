import Foundation

struct Progress: Identifiable, Codable {
    var id: Int64
    var wordId: Int64
    var bookId: Int64
    var repetitions: Int = 0
    var intervalDays: Int = 0
    var easeFactor: Float = 2.5
    var nextReviewTime: TimeInterval = 0
    var reviewCount: Int = 0
    var status: Int = Status.learning
    var lastStudyTime: TimeInterval = 0
    var isNewWord: Bool = true
    
    enum Status {
        static let new = 0
        static let learning = 1
        static let mastered = 2
    }
}

struct StudyRecord: Identifiable, Codable {
    var id: Int64
    var wordId: Int64
    var bookId: Int64
    var rating: StudyRating
    var timestamp: TimeInterval
    var intervalDays: Int
    var easeFactor: Float
}

struct Book: Identifiable, Codable {
    var id: Int64
    var name: String
    var wordCount: Int
    var createdAt: TimeInterval
    var isPreset: Bool
}

struct DailyStats: Codable {
    var date: String
    var studyCount: Int
    var reviewCount: Int
    var masteredCount: Int
    var streakDays: Int
    var checkedIn: Bool
    var checkInTime: TimeInterval?
}
