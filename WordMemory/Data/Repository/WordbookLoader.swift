import Foundation

class WordbookLoader {
    
    static let shared = WordbookLoader()
    
    /// Cache: avoid re-parsing 26K+ word JSON on every screen appear
    private var cachedWords: [Word]?
    
    func loadFromProjectBundle() -> [Word] {
        if let cached = cachedWords { return cached }
        let words = _loadFromBundle()
        cachedWords = words
        return words
    }
    
    /// Force reload (e.g. after importing new wordbook)
    func invalidateCache() {
        cachedWords = nil
    }
    
    private func _loadFromBundle() -> [Word] {
        let fileManager = FileManager.default
        
        // Try document directory first (user-imported wordbook)
        let docPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("wordbook_full.json")
        if fileManager.fileExists(atPath: docPath.path) {
            let words = loadFromJSON(url: docPath)
            if !words.isEmpty { return words }
        }
        
        // Load both bundled wordbooks and merge (deduplicate by word)
        var allWords: [Word] = []
        var seenWords: Set<String> = []
        
        let bundleFiles = ["wordbook_full", "wordbook_full_from_e2c"]
        
        for filename in bundleFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: "json"),
               fileManager.fileExists(atPath: url.path) {
                let words = loadFromJSON(url: url)
                for word in words {
                    let key = word.word.lowercased()
                    if seenWords.insert(key).inserted {
                        allWords.append(word)
                    }
                }
            }
        }
        
        if !allWords.isEmpty { return allWords }
        
        // Fallback: load small sample
        return sampleWords()
    }
    
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
        
        // Try Youdao-style format: { "code": 200, "data": [...] }
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let dataArray = dict["data"] as? [[String: Any]] {
            let words = parseYoudaoArray(dataArray)
            if !words.isEmpty { return words }
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
    
    /// Parse Youdao-style wordbook format
    private func parseYoudaoArray(_ array: [[String: Any]]) -> [Word] {
        return array.enumerated().compactMap { index, dict in
            guard let word = dict["word"] as? String else { return nil }
            
            // Extract meaning from translations
            var meaning = ""
            if let translations = dict["translations"] as? [[String: Any]] {
                meaning = translations.compactMap { t in
                    guard let pos = t["pos"] as? String, let tran = t["tran_cn"] as? String else { return nil }
                    return "\(pos) \(tran)"
                }.joined(separator: "; ")
            }
            if meaning.isEmpty {
                meaning = dict["meaning"] as? String ?? ""
            }
            
            // Extract phonetic
            let usphone = dict["usphone"] as? String ?? ""
            let phonetic = usphone.isEmpty ? (dict["ukphone"] as? String ?? "") : usphone
            
            // Extract example from sentences
            var example = ""
            if let sentences = dict["sentences"] as? [[String: Any]], let first = sentences.first {
                let en = first["s_content"] as? String ?? ""
                let cn = first["s_cn"] as? String ?? ""
                example = en.isEmpty ? "" : "\(en) \(cn)"
            }
            if example.isEmpty {
                example = dict["example"] as? String ?? ""
            }
            
            // Extract phrases
            var phrasesStr = ""
            if let phrases = dict["phrases"] as? [[String: Any]] {
                phrasesStr = phrases.compactMap { p in
                    guard let phrase = p["p"] as? String ?? p["phrase"] as? String,
                          let meaning = p["m"] as? String ?? p["meaning"] as? String else { return nil }
                    return "\(phrase) \(meaning)"
                }.joined(separator: "; ")
            }
            if phrasesStr.isEmpty {
                phrasesStr = dict["phrases"] as? String ?? ""
            }
            
            // Extract synonyms
            var synonymsStr = ""
            if let synonyms = dict["synonyms"] as? [[String: Any]] {
                synonymsStr = synonyms.compactMap { s in
                    (s["word"] as? String)
                }.joined(separator: ", ")
            }
            if synonymsStr.isEmpty {
                synonymsStr = dict["synonyms"] as? String ?? ""
            }
            
            // Extract relWords
            var relWordsStr = ""
            if let relWords = dict["relWords"] as? [[String: Any]] {
                relWordsStr = relWords.compactMap { r in
                    guard let w = r["word"] as? String else { return nil }
                    let meaning = r["tran"] as? String ?? ""
                    return meaning.isEmpty ? w : "\(w) \(meaning)"
                }.joined(separator: "; ")
            }
            if relWordsStr.isEmpty {
                relWordsStr = dict["relWords"] as? String ?? ""
            }
            
            let bookIdStr = dict["bookId"] as? String ?? "1"
            let bookId = Int64(bookIdStr) ?? 1
            
            return Word(
                id: Int64(index + 1),
                word: word,
                phonetic: phonetic.isEmpty ? "" : "/\(phonetic)/",
                meaning: meaning,
                example: example,
                phrases: phrasesStr,
                synonyms: synonymsStr,
                relWords: relWordsStr,
                bookId: bookId
            )
        }
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
    
    // loadFromProjectBundle is now the cached version above
    
    private func sampleWords() -> [Word] {
        return [
            Word(id: 1, word: "abandon", phonetic: "/əˈbændən/", meaning: "v. 放弃，遗弃", example: "He abandoned his car in the snow.", phrases: "abandon oneself to 沉溺于", synonyms: "desert, forsake", relWords: "abandoned adj. 被遗弃的", bookId: 1),
            Word(id: 2, word: "ability", phonetic: "/əˈbɪləti/", meaning: "n. 能力，才能", example: "She has the ability to speak four languages.", phrases: "to the best of one's ability 竭尽全力", synonyms: "capability, capacity", relWords: "able adj. 能够的", bookId: 1),
            Word(id: 3, word: "absence", phonetic: "/ˈæbsəns/", meaning: "n. 缺席，缺乏", example: "His absence from school was noticed.", phrases: "in the absence of 缺乏...时", synonyms: "lack, deficiency", relWords: "absent adj. 缺席的", bookId: 1),
        ]
    }
}
