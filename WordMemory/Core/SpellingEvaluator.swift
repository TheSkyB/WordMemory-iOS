import Foundation

class SpellingEvaluator {
    
    static let shared = SpellingEvaluator()
    
    /// Evaluate spelling attempt against target word
    /// Returns: (outcome, hint string if applicable)
    func evaluate(input: String, target: String) -> (SpellingOutcome, String?) {
        let normalizedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedTarget = target.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Perfect match
        if normalizedInput == normalizedTarget {
            return (.perfect, nil)
        }
        
        // Calculate edit distance
        let distance = levenshteinDistance(normalizedInput, normalizedTarget)
        let maxLen = max(normalizedInput.count, normalizedTarget.count)
        let similarity = 1.0 - Double(distance) / Double(maxLen)
        
        // Retry success: very close (1-2 chars off, >80% similar)
        if distance <= 2 && similarity > 0.8 {
            return (.retrySuccess, nil)
        }
        
        // Hinted: somewhat close (3-4 chars off, >60% similar)
        if distance <= 4 && similarity > 0.6 {
            let hint = generateHint(input: normalizedInput, target: normalizedTarget)
            return (.hinted, hint)
        }
        
        // Failed
        let hint = generateHint(input: normalizedInput, target: normalizedTarget)
        return (.failed, hint)
    }
    
    /// Generate a hint showing correct and incorrect letters
    private func generateHint(input: String, target: String) -> String {
        var result = ""
        let inputChars = Array(input)
        let targetChars = Array(target)
        
        for (i, char) in targetChars.enumerated() {
            if i < inputChars.count {
                if inputChars[i] == char {
                    result.append(char) // Correct
                } else {
                    result.append("_") // Wrong position
                }
            } else {
                result.append("?") // Missing
            }
        }
        
        return result
    }
    
    /// Levenshtein distance algorithm
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let chars1 = Array(s1)
        let chars2 = Array(s2)
        let m = chars1.count
        let n = chars2.count
        
        guard m > 0 else { return n }
        guard n > 0 else { return m }
        
        var previousRow = Array(0...n)
        var currentRow = Array(repeating: 0, count: n + 1)
        
        for i in 1...m {
            currentRow[0] = i
            
            for j in 1...n {
                let cost = (chars1[i-1] == chars2[j-1]) ? 0 : 1
                currentRow[j] = min(
                    previousRow[j] + 1,      // deletion
                    currentRow[j-1] + 1,      // insertion
                    previousRow[j-1] + cost   // substitution
                )
            }
            
            previousRow = currentRow
            currentRow = Array(repeating: 0, count: n + 1)
        }
        
        return previousRow[n]
    }
    
    /// Get letter hint (reveal first N letters)
    func getLetterHint(for word: String, revealedCount: Int) -> String {
        let chars = Array(word)
        var result = ""
        for (i, char) in chars.enumerated() {
            if i < revealedCount {
                result.append(char)
            } else if char == " " || char == "-" {
                result.append(char)
            } else {
                result.append("_")
            }
        }
        return result
    }
}
