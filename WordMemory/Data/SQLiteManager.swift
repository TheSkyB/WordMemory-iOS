import Foundation
import SQLite3

class SQLiteManager {
    
    static let shared = SQLiteManager()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        dbPath = docsDir.appendingPathComponent("wordmemory.db").path
        
        openDatabase()
        createTables()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database at \(dbPath)")
        }
    }
    
    private func createTables() {
        let createProgressTable = """
            CREATE TABLE IF NOT EXISTS progress (
                word_id INTEGER PRIMARY KEY,
                book_id INTEGER,
                repetitions INTEGER DEFAULT 0,
                interval_days INTEGER DEFAULT 0,
                ease_factor REAL DEFAULT 2.5,
                next_review_time REAL DEFAULT 0,
                review_count INTEGER DEFAULT 0,
                status INTEGER DEFAULT 1,
                last_study_time REAL DEFAULT 0,
                is_new_word INTEGER DEFAULT 1
            );
        """
        
        let createRecordsTable = """
            CREATE TABLE IF NOT EXISTS study_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word_id INTEGER,
                book_id INTEGER,
                rating INTEGER,
                timestamp REAL,
                interval_days INTEGER,
                ease_factor REAL
            );
        """
        
        let createStatsTable = """
            CREATE TABLE IF NOT EXISTS daily_stats (
                date TEXT PRIMARY KEY,
                study_count INTEGER DEFAULT 0,
                review_count INTEGER DEFAULT 0,
                mastered_count INTEGER DEFAULT 0,
                streak_days INTEGER DEFAULT 0,
                checked_in INTEGER DEFAULT 0,
                check_in_time REAL
            );
        """
        
        execute(createProgressTable)
        execute(createRecordsTable)
        execute(createStatsTable)
    }
    
    @discardableResult
    private func execute(_ sql: String) -> Bool {
        var errorMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMsg)
        if result != SQLITE_OK {
            let msg = String(cString: errorMsg!)
            print("SQL Error: \(msg)")
            sqlite3_free(errorMsg)
            return false
        }
        return true
    }
    
    // MARK: - Progress Operations
    
    func saveProgress(_ progress: Progress) {
        let sql = """
            INSERT OR REPLACE INTO progress (
                word_id, book_id, repetitions, interval_days, ease_factor,
                next_review_time, review_count, status, last_study_time, is_new_word
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, progress.wordId)
            sqlite3_bind_int64(stmt, 2, progress.bookId)
            sqlite3_bind_int(stmt, 3, Int32(progress.repetitions))
            sqlite3_bind_int(stmt, 4, Int32(progress.intervalDays))
            sqlite3_bind_double(stmt, 5, Double(progress.easeFactor))
            sqlite3_bind_double(stmt, 6, progress.nextReviewTime)
            sqlite3_bind_int(stmt, 7, Int32(progress.reviewCount))
            sqlite3_bind_int(stmt, 8, Int32(progress.status))
            sqlite3_bind_double(stmt, 9, progress.lastStudyTime)
            sqlite3_bind_int(stmt, 10, progress.isNewWord ? 1 : 0)
            
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }
    
    func loadProgress(wordId: Int64) -> Progress? {
        let sql = "SELECT * FROM progress WHERE word_id = ?;"
        var stmt: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_int64(stmt, 1, wordId)
        
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            sqlite3_finalize(stmt)
            return nil
        }
        
        let progress = Progress(
            id: sqlite3_column_int64(stmt, 0),
            wordId: sqlite3_column_int64(stmt, 0),
            bookId: sqlite3_column_int64(stmt, 1),
            repetitions: Int(sqlite3_column_int(stmt, 2)),
            intervalDays: Int(sqlite3_column_int(stmt, 3)),
            easeFactor: Float(sqlite3_column_double(stmt, 4)),
            nextReviewTime: sqlite3_column_double(stmt, 5),
            reviewCount: Int(sqlite3_column_int(stmt, 6)),
            status: Int(sqlite3_column_int(stmt, 7)),
            lastStudyTime: sqlite3_column_double(stmt, 8),
            isNewWord: sqlite3_column_int(stmt, 9) == 1
        )
        
        sqlite3_finalize(stmt)
        return progress
    }
    
    func loadAllProgress() -> [Int64: Progress] {
        let sql = "SELECT * FROM progress;"
        var stmt: OpaquePointer?
        var result: [Int64: Progress] = [:]
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return result }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let wordId = sqlite3_column_int64(stmt, 0)
            let progress = Progress(
                id: wordId,
                wordId: wordId,
                bookId: sqlite3_column_int64(stmt, 1),
                repetitions: Int(sqlite3_column_int(stmt, 2)),
                intervalDays: Int(sqlite3_column_int(stmt, 3)),
                easeFactor: Float(sqlite3_column_double(stmt, 4)),
                nextReviewTime: sqlite3_column_double(stmt, 5),
                reviewCount: Int(sqlite3_column_int(stmt, 6)),
                status: Int(sqlite3_column_int(stmt, 7)),
                lastStudyTime: sqlite3_column_double(stmt, 8),
                isNewWord: sqlite3_column_int(stmt, 9) == 1
            )
            result[wordId] = progress
        }
        
        sqlite3_finalize(stmt)
        return result
    }
    
    // MARK: - Study Records
    
    func saveStudyRecord(_ record: StudyRecord) {
        let sql = """
            INSERT INTO study_records (word_id, book_id, rating, timestamp, interval_days, ease_factor)
            VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, record.wordId)
            sqlite3_bind_int64(stmt, 2, record.bookId)
            sqlite3_bind_int(stmt, 3, Int32(record.rating.rawValue))
            sqlite3_bind_double(stmt, 4, record.timestamp)
            sqlite3_bind_int(stmt, 5, Int32(record.intervalDays))
            sqlite3_bind_double(stmt, 6, Double(record.easeFactor))
            
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }
    
    func loadStudyRecords(for wordId: Int64? = nil) -> [StudyRecord] {
        let sql = wordId != nil
            ? "SELECT * FROM study_records WHERE word_id = ? ORDER BY timestamp DESC;"
            : "SELECT * FROM study_records ORDER BY timestamp DESC;"
        
        var stmt: OpaquePointer?
        var records: [StudyRecord] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return records }
        
        if let id = wordId {
            sqlite3_bind_int64(stmt, 1, id)
        }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let record = StudyRecord(
                id: sqlite3_column_int64(stmt, 0),
                wordId: sqlite3_column_int64(stmt, 1),
                bookId: sqlite3_column_int64(stmt, 2),
                rating: StudyRating(rawValue: Int(sqlite3_column_int(stmt, 3))) ?? .again,
                timestamp: sqlite3_column_double(stmt, 4),
                intervalDays: Int(sqlite3_column_int(stmt, 5)),
                easeFactor: Float(sqlite3_column_double(stmt, 6))
            )
            records.append(record)
        }
        
        sqlite3_finalize(stmt)
        return records
    }
    
    // MARK: - Daily Stats
    
    func saveDailyStats(_ stats: DailyStats) {
        let sql = """
            INSERT OR REPLACE INTO daily_stats
            (date, study_count, review_count, mastered_count, streak_days, checked_in, check_in_time)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (stats.date as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(stats.studyCount))
            sqlite3_bind_int(stmt, 3, Int32(stats.reviewCount))
            sqlite3_bind_int(stmt, 4, Int32(stats.masteredCount))
            sqlite3_bind_int(stmt, 5, Int32(stats.streakDays))
            sqlite3_bind_int(stmt, 6, stats.checkedIn ? 1 : 0)
            if let checkInTime = stats.checkInTime {
                sqlite3_bind_double(stmt, 7, checkInTime)
            } else {
                sqlite3_bind_null(stmt, 7)
            }
            
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }
    
    func loadDailyStats(date: String) -> DailyStats? {
        let sql = "SELECT * FROM daily_stats WHERE date = ?;"
        var stmt: OpaquePointer?
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(stmt, 1, (date as NSString).utf8String, -1, nil)
        
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            sqlite3_finalize(stmt)
            return nil
        }
        
        let stats = DailyStats(
            date: String(cString: sqlite3_column_text(stmt, 0)),
            studyCount: Int(sqlite3_column_int(stmt, 1)),
            reviewCount: Int(sqlite3_column_int(stmt, 2)),
            masteredCount: Int(sqlite3_column_int(stmt, 3)),
            streakDays: Int(sqlite3_column_int(stmt, 4)),
            checkedIn: sqlite3_column_int(stmt, 5) == 1,
            checkInTime: sqlite3_column_type(stmt, 6) == SQLITE_NULL ? nil : sqlite3_column_double(stmt, 6)
        )
        
        sqlite3_finalize(stmt)
        return stats
    }
    
    func getTodayStats() -> DailyStats {
        let date = formatDate(Date())
        return loadDailyStats(date: date) ?? DailyStats(
            date: date,
            studyCount: 0,
            reviewCount: 0,
            masteredCount: 0,
            streakDays: 0,
            checkedIn: false,
            checkInTime: nil
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Word Count
    
    func getTotalWordCount() -> Int {
        let sql = "SELECT COUNT(*) FROM progress;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            sqlite3_finalize(stmt)
            return 0
        }
        let count = Int(sqlite3_column_int(stmt, 0))
        sqlite3_finalize(stmt)
        return count
    }
    
    func getMasteredWordCount() -> Int {
        let sql = "SELECT COUNT(*) FROM progress WHERE status = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        sqlite3_bind_int(stmt, 1, Int32(Progress.Status.mastered))
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            sqlite3_finalize(stmt)
            return 0
        }
        let count = Int(sqlite3_column_int(stmt, 0))
        sqlite3_finalize(stmt)
        return count
    }
    
    // MARK: - Today's Studied Words
    
    /// Get word IDs studied today from study_records
    func getTodayStudiedWordIds() -> [Int64] {
        let startOfDay = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        let sql = "SELECT DISTINCT word_id FROM study_records WHERE timestamp >= ?;"
        var stmt: OpaquePointer?
        var ids: [Int64] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return ids }
        sqlite3_bind_double(stmt, 1, startOfDay)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            ids.append(sqlite3_column_int64(stmt, 0))
        }
        sqlite3_finalize(stmt)
        return ids
    }
    
    /// Get all word IDs that have been studied (appear in progress table)
    func getAllStudiedWordIds() -> [Int64] {
        let sql = "SELECT word_id FROM progress WHERE is_new_word = 0;"
        var stmt: OpaquePointer?
        var ids: [Int64] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return ids }
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            ids.append(sqlite3_column_int64(stmt, 0))
        }
        sqlite3_finalize(stmt)
        return ids
    }
    
    /// Get mastered word IDs (status = mastered)
    func getMasteredWordIds() -> [Int64] {
        let sql = "SELECT word_id FROM progress WHERE status = ?;"
        var stmt: OpaquePointer?
        var ids: [Int64] = []
        
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return ids }
        sqlite3_bind_int(stmt, 1, Int32(Progress.Status.mastered))
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            ids.append(sqlite3_column_int64(stmt, 0))
        }
        sqlite3_finalize(stmt)
        return ids
    }
}
