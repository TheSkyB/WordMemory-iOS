import Foundation
import Combine

class LearningViewModel: ObservableObject {
    
    @Published var words: [Word] = []
    @Published var currentWord: Word?
    @Published var currentIndex: Int = 0
    @Published var totalCount: Int = 0
    @Published var isCardFlipped: Bool = false
    @Published var isAnswering: Bool = false
    @Published var learningMode: LearningMode = .recognition
    @Published var algorithmVersion: AlgorithmVersion = .v3
    @Published var showCompletion: Bool = false
    @Published var todayStudyCount: Int = 0
    @Published var streakDays: Int = 0
    @Published var dueReviewCount: Int = 0
    @Published var isInNewWords: Bool = false
    
    // Spelling mode
    @Published var spellingInput: String = ""
    @Published var spellingOutcome: SpellingOutcome?
    @Published var spellingHint: String?
    @Published var revealedLetterCount: Int = 0
    @Published var showSpellingResult: Bool = false
    
    private var progressMap: [Int64: Progress] = [:]
    private var newWordsQueue: [Word] = []
    private var reviewQueue: [Word] = []
    private var immediateRetryQueue: [Word] = []
    private var studyRecords: [StudyRecord] = []
    
    private let scheduler = SM2Scheduler.shared
    private let evaluator = SpellingEvaluator.shared
    private let notebook = NotebookManager.shared
    private let db = SQLiteManager.shared
    private var now: TimeInterval { Date().timeIntervalSince1970 }
    
    func loadWords(_ words: [Word]) {
        self.words = words
        self.totalCount = words.count
        
        // Load saved progress from database
        let savedProgress = db.loadAllProgress()
        for (wordId, progress) in savedProgress {
            progressMap[wordId] = progress
        }
        
        // Load today's stats
        let todayStats = db.getTodayStats()
        todayStudyCount = todayStats.studyCount
        streakDays = todayStats.streakDays
        
        buildQueue()
        loadNextWord()
    }
    
    private func buildQueue() {
        // Separate new words and review words
        newWordsQueue = words.filter { progressMap[$0.id]?.isNewWord ?? true }
        reviewQueue = words.filter { word in
            guard let progress = progressMap[word.id] else { return false }
            return !progress.isNewWord && progress.nextReviewTime <= now
        }
        
        // Sort review queue by nextReviewTime (earliest first)
        reviewQueue.sort { a, b in
            let timeA = progressMap[a.id]?.nextReviewTime ?? 0
            let timeB = progressMap[b.id]?.nextReviewTime ?? 0
            return timeA < timeB
        }
        
        dueReviewCount = reviewQueue.count
    }
    
    private func loadNextWord() {
        // Priority: immediate retry > review > new words
        if !immediateRetryQueue.isEmpty {
            currentWord = immediateRetryQueue.removeFirst()
        } else if !reviewQueue.isEmpty {
            currentWord = reviewQueue.removeFirst()
        } else if !newWordsQueue.isEmpty {
            currentWord = newWordsQueue.removeFirst()
        } else {
            currentWord = nil
            showCompletion = true
            return
        }
        
        isCardFlipped = false
        spellingInput = ""
        spellingOutcome = nil
        spellingHint = nil
        revealedLetterCount = 0
        showSpellingResult = false
        currentIndex += 1
        
        // Update new words status
        if let word = currentWord {
            isInNewWords = notebook.contains(wordId: word.id)
        }
    }
    
    // MARK: - Recognition Mode
    
    func submitAnswer(_ rating: StudyRating) {
        guard let word = currentWord else { return }
        isAnswering = true
        
        let currentProgress = progressMap[word.id]
        let result = scheduler.schedule(
            current: currentProgress,
            rating: rating,
            algorithm: algorithmVersion
        )
        
        updateProgress(word: word, result: result)
        
        // Handle again: add to immediate retry queue
        if rating == .again {
            immediateRetryQueue.append(word)
        }
        
        todayStudyCount += 1
        saveTodayStats()
        
        // Delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnswering = false
            self.loadNextWord()
        }
    }
    
    // MARK: - Spelling Mode
    
    func submitSpelling() {
        guard let word = currentWord else { return }
        isAnswering = true
        
        let (outcome, hint) = evaluator.evaluate(input: spellingInput, target: word.word)
        spellingOutcome = outcome
        spellingHint = hint
        showSpellingResult = true
        
        let currentProgress = progressMap[word.id]
        let result = scheduler.scheduleSpelling(
            current: currentProgress,
            outcome: outcome,
            algorithm: algorithmVersion
        )
        
        updateProgress(word: word, result: result)
        
        if outcome == .failed {
            immediateRetryQueue.append(word)
        }
        
        todayStudyCount += 1
        saveTodayStats()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isAnswering = false
        }
    }
    
    func continueAfterSpelling() {
        showSpellingResult = false
        loadNextWord()
    }
    
    func requestLetterHint() {
        guard let word = currentWord else { return }
        revealedLetterCount += 1
        spellingHint = evaluator.getLetterHint(for: word.word, revealedCount: revealedLetterCount)
    }
    
    // MARK: - Common
    
    private func updateProgress(word: Word, result: SM2Scheduler.ScheduleResult) {
        var progress = progressMap[word.id] ?? Progress(
            id: word.id,
            wordId: word.id,
            bookId: word.bookId
        )
        progress.repetitions = result.repetitions
        progress.intervalDays = result.intervalDays
        progress.easeFactor = result.easeFactor
        progress.nextReviewTime = result.nextReviewTime
        progress.reviewCount += 1
        progress.status = result.status
        progress.lastStudyTime = now
        progress.isNewWord = false
        
        progressMap[word.id] = progress
        db.saveProgress(progress)
        
        // Record study
        let record = StudyRecord(
            id: Int64(studyRecords.count + 1),
            wordId: word.id,
            bookId: word.bookId,
            rating: .good, // Will be updated based on context
            timestamp: now,
            intervalDays: result.intervalDays,
            easeFactor: result.easeFactor
        )
        studyRecords.append(record)
        db.saveStudyRecord(record)
    }
    
    func flipCard() {
        isCardFlipped.toggle()
    }
    
    func toggleNewWord() {
        guard let word = currentWord else { return }
        notebook.toggle(wordId: word.id)
        isInNewWords = notebook.contains(wordId: word.id)
    }
    
    func getProgress(for wordId: Int64) -> Progress? {
        return progressMap[wordId]
    }
    
    func getReviewTag(for wordId: Int64) -> String {
        guard let progress = progressMap[wordId] else { return "新词" }
        if progress.isNewWord { return "新词" }
        
        let days = Int((progress.nextReviewTime - now) / 86400)
        if days <= 0 { return "今天" }
        if days == 1 { return "明天" }
        if days < 7 { return "\(days)天后" }
        if days < 30 { return "\(days/7)周后" }
        return "\(days/30)月后"
    }
    
    func resetSession() {
        currentIndex = 0
        showCompletion = false
        immediateRetryQueue.removeAll()
        buildQueue()
        loadNextWord()
    }
    
    private func saveTodayStats() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: Date())
        
        let stats = DailyStats(
            date: date,
            studyCount: todayStudyCount,
            reviewCount: 0,
            masteredCount: 0,
            streakDays: streakDays,
            checkedIn: false,
            checkInTime: nil
        )
        db.saveDailyStats(stats)
    }
    
    func checkIn() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: Date())
        
        var stats = db.loadDailyStats(date: date) ?? DailyStats(
            date: date,
            studyCount: todayStudyCount,
            reviewCount: 0,
            masteredCount: 0,
            streakDays: streakDays,
            checkedIn: false,
            checkInTime: nil
        )
        
        if !stats.checkedIn {
            stats.checkedIn = true
            stats.checkInTime = now
            stats.streakDays += 1
            streakDays = stats.streakDays
            db.saveDailyStats(stats)
        }
    }
}

// MARK: - Supporting Types

enum LearningMode {
    case recognition
    case spelling
}

enum AlgorithmVersion {
    case v3
    case v4
}

enum SpellingOutcome {
    case perfect       // 完全正确
    case retrySuccess  // 接近正确
    case hinted        // 需要练习
    case failed        // 再试一次
    
    /// SM2 quality value (0-5 scale)
    var quality: Int {
        switch self {
        case .perfect: return 5
        case .retrySuccess: return 4
        case .hinted: return 3
        case .failed: return 1
        }
    }
}
