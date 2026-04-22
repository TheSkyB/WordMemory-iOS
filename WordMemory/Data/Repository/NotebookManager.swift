import Foundation
import Combine

class NotebookManager: ObservableObject {
    
    static let shared = NotebookManager()
    
    @Published var newWords: Set<Int64> = []
    
    private let userDefaultsKey = "new_words_set"
    
    private init() {
        load()
    }
    
    func add(wordId: Int64) {
        newWords.insert(wordId)
        save()
    }
    
    func remove(wordId: Int64) {
        newWords.remove(wordId)
        save()
    }
    
    func toggle(wordId: Int64) {
        if newWords.contains(wordId) {
            remove(wordId: wordId)
        } else {
            add(wordId: wordId)
        }
    }
    
    func contains(wordId: Int64) -> Bool {
        return newWords.contains(wordId)
    }
    
    func getNewWords(from allWords: [Word]) -> [Word] {
        return allWords.filter { newWords.contains($0.id) }
    }
    
    private func save() {
        let array = Array(newWords)
        UserDefaults.standard.set(array, forKey: userDefaultsKey)
    }
    
    private func load() {
        if let array = UserDefaults.standard.array(forKey: userDefaultsKey) as? [Int64] {
            newWords = Set(array)
        }
    }
}
