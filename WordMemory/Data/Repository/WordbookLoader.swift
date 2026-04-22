import Foundation

class WordbookLoader {
    
    static let shared = WordbookLoader()
    
    func loadFromJSON(url: URL) -> [Word] {
        guard let data = try? Data(contentsOf: url) else {
            print("Failed to load JSON from \(url)")
            return []
        }
        
        // Try array format first
        if let entries = try? JSONDecoder().decode([WordEntry].self, from: data) {
            return entries.enumerated().map { index, entry in
                Word(
                    id: Int64(index + 1),
                    word: entry.word,
                    phonetic: entry.phonetic ?? "",
                    meaning: entry.meaning,
                    example: entry.example ?? "",
                    phrases: entry.phrases ?? "",
                    synonyms: entry.synonyms ?? "",
                    relWords: entry.relWords ?? "",
                    bookId: 1
                )
            }
        }
        
        // Try object format with data key
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArray = dict["data"] as? [[String: Any]] {
            return parseDictionaryArray(dataArray)
        }
        
        // Try direct object format
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return parseDictionaryArray([dict])
        }
        
        return []
    }
    
    private func parseDictionaryArray(_ array: [[String: Any]]) -> [Word] {
        return array.enumerated().compactMap { index, dict in
            guard let word = dict["word"] as? String,
                  let meaning = dict["meaning"] as? String else { return nil }
            
            return Word(
                id: Int64(index + 1),
                word: word,
                phonetic: dict["phonetic"] as? String ?? "",
                meaning: meaning,
                example: dict["example"] as? String ?? "",
                phrases: dict["phrases"] as? String ?? "",
                synonyms: dict["synonyms"] as? String ?? "",
                relWords: dict["rel_words"] as? String ?? "",
                bookId: 1
            )
        }
    }
    
    func loadFromProjectBundle() -> [Word] {
        let fileManager = FileManager.default
        let possiblePaths = [
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("wordbook_full.json"),
            Bundle.main.url(forResource: "wordbook_full", withExtension: "json"),
        ].compactMap { $0 }
        
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path.path) {
                let words = loadFromJSON(url: path)
                if !words.isEmpty { return words }
            }
        }
        
        // Fallback: load small sample
        return sampleWords()
    }
    
    private func sampleWords() -> [Word] {
        return [
            Word(id: 1, word: "abandon", phonetic: "/əˈbændən/", meaning: "v. 放弃，遗弃", example: "He abandoned his car in the snow.", phrases: "abandon oneself to 沉溺于", synonyms: "desert, forsake", relWords: "abandoned adj. 被遗弃的", bookId: 1),
            Word(id: 2, word: "ability", phonetic: "/əˈbɪləti/", meaning: "n. 能力，才能", example: "She has the ability to speak four languages.", phrases: "to the best of one's ability 竭尽全力", synonyms: "capability, capacity", relWords: "able adj. 能够的", bookId: 1),
            Word(id: 3, word: "absence", phonetic: "/ˈæbsəns/", meaning: "n. 缺席，缺乏", example: "His absence from school was noticed.", phrases: "in the absence of 缺乏...时", synonyms: "lack, deficiency", relWords: "absent adj. 缺席的", bookId: 1),
        ]
    }
}
