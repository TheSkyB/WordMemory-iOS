import Foundation

// Placeholder for database manager
// In production, this would use CoreData or SQLite.swift

class DatabaseManager {
    static let shared = DatabaseManager()
    
    private init() {}
    
    func saveProgress(_ progress: Progress) {
        // TODO: Implement persistence
        UserDefaults.standard.set(try? JSONEncoder().encode(progress), forKey: "progress_\(progress.wordId)")
    }
    
    func loadProgress(wordId: Int64) -> Progress? {
        guard let data = UserDefaults.standard.data(forKey: "progress_\(wordId)") else { return nil }
        return try? JSONDecoder().decode(Progress.self, from: data)
    }
    
    func saveStudyRecord(_ record: StudyRecord) {
        var records = loadStudyRecords()
        records.append(record)
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: "study_records")
        }
    }
    
    func loadStudyRecords() -> [StudyRecord] {
        guard let data = UserDefaults.standard.data(forKey: "study_records") else { return [] }
        return (try? JSONDecoder().decode([StudyRecord].self, from: data)) ?? []
    }
}
