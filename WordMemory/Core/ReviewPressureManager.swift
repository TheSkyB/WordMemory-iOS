import Foundation

class ReviewPressureManager {
    
    static let shared = ReviewPressureManager()
    
    private let dailyLimitKey = "daily_review_limit"
    private let defaultLimit = 50
    
    var dailyLimit: Int {
        get { UserDefaults.standard.integer(forKey: dailyLimitKey) }
        set { UserDefaults.standard.set(newValue, forKey: dailyLimitKey) }
    }
    
    func distributeReviews(words: [Word], progressMap: [Int64: Progress]) -> [Word] {
        let limit = dailyLimit > 0 ? dailyLimit : defaultLimit
        let now = Date().timeIntervalSince1970
        
        // Get all due reviews
        var dueWords = words.filter { word in
            guard let progress = progressMap[word.id] else { return false }
            return !progress.isNewWord && progress.nextReviewTime <= now
        }
        
        // Sort by urgency (earliest review time first)
        dueWords.sort { a, b in
            let timeA = progressMap[a.id]?.nextReviewTime ?? 0
            let timeB = progressMap[b.id]?.nextReviewTime ?? 0
            return timeA < timeB
        }
        
        // If within limit, return all
        if dueWords.count <= limit {
            return dueWords
        }
        
        // Otherwise, distribute by postponing some
        let toReview = Array(dueWords.prefix(limit))
        let toPostpone = Array(dueWords.suffix(from: limit))
        
        // Postpone remaining to tomorrow
        for word in toPostpone {
            if var progress = progressMap[word.id] {
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
                components.hour = 4
                components.minute = 0
                progress.nextReviewTime = Calendar.current.date(from: components)!.timeIntervalSince1970
                
                // Save to database
                SQLiteManager.shared.saveProgress(progress)
            }
        }
        
        return toReview
    }
    
    func getReviewStats(words: [Word], progressMap: [Int64: Progress]) -> (total: Int, today: Int, postponed: Int) {
        let now = Date().timeIntervalSince1970
        let limit = dailyLimit > 0 ? dailyLimit : defaultLimit
        
        let dueWords = words.filter { word in
            guard let progress = progressMap[word.id] else { return false }
            return !progress.isNewWord && progress.nextReviewTime <= now
        }
        
        let todayCount = min(dueWords.count, limit)
        let postponedCount = max(dueWords.count - limit, 0)
        
        return (dueWords.count, todayCount, postponedCount)
    }
}
