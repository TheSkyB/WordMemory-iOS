import Foundation

class SM2Scheduler {
    
    static let shared = SM2Scheduler()
    
    private let defaultEase: Float = 2.5
    private let minEase: Float = 1.3
    private let minEaseSpelling: Float = 1.1
    private let maxEase: Float = 3.0
    private let maxGrowthFactor: Float = 2.5
    private let hardGrowthFactor: Float = 1.2
    private let oneMinute: TimeInterval = 60
    private let tenMinutes: TimeInterval = 600
    private let dayRefreshHour = 4
    
    // V3
    private let masteredIntervalV3 = 21
    private let masteredMinReviewV3 = 2
    
    // V4
    private let masteredIntervalV4 = 30
    private let masteredMinReviewV4 = 4
    private let masteredMinEase: Float = 2.3
    private let shortTermDecayHours: TimeInterval = 12
    private let ebbinghausLadder = [1, 2, 6, 14, 30]
    
    struct ScheduleResult {
        let repetitions: Int
        let intervalDays: Int
        let easeFactor: Float
        let nextReviewTime: TimeInterval
        let status: Int
    }
    
    func schedule(
        current: Progress?,
        rating: StudyRating,
        now: TimeInterval = Date().timeIntervalSince1970,
        algorithm: AlgorithmVersion = .v3
    ) -> ScheduleResult {
        if algorithm == .v4 {
            return scheduleV4(current: current, rating: rating, now: now)
        }
        return scheduleV3(current: current, rating: rating, now: now)
    }
    
    private func scheduleV3(current: Progress?, rating: StudyRating, now: TimeInterval) -> ScheduleResult {
        var ease = updateEase(current?.easeFactor ?? defaultEase, rating.quality, minEase)
        let prevReps = current?.repetitions ?? 0
        let prevInterval = current?.intervalDays ?? 0
        let prevReviewCount = current?.reviewCount ?? 0
        let isLearning = isLearningPhase(current)
        
        if rating == .again {
            ease = max(ease - 0.2, minEase)
            return ScheduleResult(
                repetitions: 0,
                intervalDays: 1,
                easeFactor: ease,
                nextReviewTime: nextReviewByDays(now, 1),
                status: Progress.Status.learning
            )
        }
        
        if isLearning {
            let interval = rating == .hard ? 1 : 2
            return ScheduleResult(
                repetitions: prevReps + 1,
                intervalDays: interval,
                easeFactor: ease,
                nextReviewTime: nextReviewByDays(now, interval),
                status: resolveStatus(interval, prevReviewCount + 1, ease, algorithm: .v3)
            )
        }
        
        let oldInterval = max(prevInterval, 1)
        let interval = rating == .hard
            ? conservativeInterval(oldInterval, ease)
            : standardInterval(oldInterval, ease)
        
        return ScheduleResult(
            repetitions: prevReps + 1,
            intervalDays: interval,
            easeFactor: ease,
            nextReviewTime: nextReviewByDays(now, interval),
            status: resolveStatus(interval, prevReviewCount + 1, ease, algorithm: .v3)
        )
    }
    
    private func scheduleV4(current: Progress?, rating: StudyRating, now: TimeInterval) -> ScheduleResult {
        var ease = updateEase(current?.easeFactor ?? defaultEase, rating.quality, minEase)
        let prevReps = current?.repetitions ?? 0
        let prevInterval = current?.intervalDays ?? 0
        let prevReviewCount = current?.reviewCount ?? 0
        let isLearning = isLearningPhase(current)
        
        if rating == .again {
            ease = max(ease - 0.2, minEase)
            return ScheduleResult(
                repetitions: 0,
                intervalDays: 0,
                easeFactor: ease,
                nextReviewTime: now + oneMinute,
                status: Progress.Status.learning
            )
        }
        
        var interval: Int
        if isLearning {
            interval = rating == .hard ? 0 : nextEbbinghausStep(prevInterval)
        } else {
            let oldInterval = max(prevInterval, 1)
            let raw = rating == .hard
                ? conservativeInterval(oldInterval, ease)
                : standardInterval(oldInterval, ease)
            interval = closestEbbinghausStep(raw)
        }
        
        if interval > 1 && reviewedWithinHours(current, now, shortTermDecayHours) {
            interval = 1
        }
        
        return ScheduleResult(
            repetitions: prevReps + 1,
            intervalDays: interval,
            easeFactor: ease,
            nextReviewTime: interval > 0 ? nextReviewByDays(now, interval) : now + tenMinutes,
            status: resolveStatus(interval, prevReviewCount + 1, ease, algorithm: .v4)
        )
    }
    
    func scheduleSpelling(
        current: Progress?,
        outcome: SpellingOutcome,
        now: TimeInterval = Date().timeIntervalSince1970,
        algorithm: AlgorithmVersion = .v3
    ) -> ScheduleResult {
        if algorithm == .v4 {
            return scheduleSpellingV4(current: current, outcome: outcome, now: now)
        }
        return scheduleSpellingV3(current: current, outcome: outcome, now: now)
    }
    
    private func scheduleSpellingV3(current: Progress?, outcome: SpellingOutcome, now: TimeInterval) -> ScheduleResult {
        var ease = updateEase(current?.easeFactor ?? defaultEase, outcome.quality, minEaseSpelling)
        let prevReviewCount = current?.reviewCount ?? 0
        let prevInterval = current?.intervalDays ?? 0
        let prevReps = current?.repetitions ?? 0
        let isLearning = isLearningPhase(current)
        
        if outcome == .failed {
            ease = max(ease - 0.2, minEaseSpelling)
            return ScheduleResult(
                repetitions: 0,
                intervalDays: 1,
                easeFactor: ease,
                nextReviewTime: nextReviewByDays(now, 1),
                status: Progress.Status.learning
            )
        }
        
        let interval: Int
        if isLearning {
            interval = (outcome == .retrySuccess) ? 1 : 2
        } else if outcome == .retrySuccess {
            interval = conservativeInterval(max(prevInterval, 1), ease)
        } else if outcome == .hinted {
            interval = standardInterval(max(prevInterval, 1), ease)
        } else {
            let base = standardInterval(max(prevInterval, 1), ease)
            interval = max(Int(Float(base) * 1.1), 1)
        }
        
        return ScheduleResult(
            repetitions: prevReps + 1,
            intervalDays: interval,
            easeFactor: ease,
            nextReviewTime: nextReviewByDays(now, interval),
            status: resolveStatus(interval, prevReviewCount + 1, ease, algorithm: .v3)
        )
    }
    
    private func scheduleSpellingV4(current: Progress?, outcome: SpellingOutcome, now: TimeInterval) -> ScheduleResult {
        var ease = updateEase(current?.easeFactor ?? defaultEase, outcome.quality, minEaseSpelling)
        let prevReviewCount = current?.reviewCount ?? 0
        let prevInterval = current?.intervalDays ?? 0
        let prevReps = current?.repetitions ?? 0
        let isLearning = isLearningPhase(current)
        
        if outcome == .failed {
            ease = max(ease - 0.2, minEaseSpelling)
            return ScheduleResult(
                repetitions: 0,
                intervalDays: 0,
                easeFactor: ease,
                nextReviewTime: now + oneMinute,
                status: Progress.Status.learning
            )
        }
        
        var interval: Int
        if isLearning {
            interval = (outcome == .retrySuccess) ? 0 : nextEbbinghausStep(prevInterval)
        } else {
            let oldInterval = max(prevInterval, 1)
            let raw: Int
            switch outcome {
            case .retrySuccess:
                raw = conservativeInterval(oldInterval, ease)
            case .hinted:
                raw = standardInterval(oldInterval, ease)
            case .perfect:
                let base = standardInterval(oldInterval, ease)
                raw = max(Int(Float(base) * 1.1), 1)
            case .failed:
                raw = 1
            }
            interval = closestEbbinghausStep(raw)
        }
        
        if interval > 1 && reviewedWithinHours(current, now, shortTermDecayHours) {
            interval = 1
        }
        
        return ScheduleResult(
            repetitions: prevReps + 1,
            intervalDays: interval,
            easeFactor: ease,
            nextReviewTime: interval > 0 ? nextReviewByDays(now, interval) : now + tenMinutes,
            status: resolveStatus(interval, prevReviewCount + 1, ease, algorithm: .v4)
        )
    }
    
    private func isLearningPhase(_ progress: Progress?) -> Bool {
        guard let p = progress else { return true }
        if p.status == Progress.Status.new { return true }
        return p.intervalDays <= 0 || p.repetitions <= 0
    }
    
    private func updateEase(_ current: Float, _ quality: Int, _ min: Float) -> Float {
        let updated = current - 0.8 + 0.28 * Float(quality) - 0.02 * Float(quality * quality)
        return min(max(updated, min), maxEase)
    }
    
    private func conservativeInterval(_ old: Int, _ ease: Float) -> Int {
        let byHard = Int(Float(old) * hardGrowthFactor)
        let byEase = Int(Float(old) * ease)
        return max(min(byHard, byEase), 1)
    }
    
    private func standardInterval(_ old: Int, _ ease: Float) -> Int {
        let grown = max(Int(Float(old) * ease), 1)
        let maxAllowed = max(Int(Float(old) * maxGrowthFactor), 1)
        return min(grown, maxAllowed)
    }
    
    private func reviewedWithinHours(_ progress: Progress?, _ now: TimeInterval, _ hours: TimeInterval) -> Bool {
        guard let p = progress, p.reviewCount > 0, p.nextReviewTime > 0 else { return false }
        let lastReview = estimateLastReviewTime(p) ?? 0
        let elapsed = now - lastReview
        return elapsed > 0 && elapsed <= hours * 3600
    }
    
    func estimateLastReviewTime(_ progress: Progress?) -> TimeInterval? {
        guard let p = progress, p.reviewCount > 0, p.nextReviewTime > 0 else { return nil }
        if p.intervalDays > 0 {
            return p.nextReviewTime - TimeInterval(p.intervalDays) * 86400
        }
        return p.nextReviewTime - tenMinutes
    }
    
    private func nextEbbinghausStep(_ current: Int) -> Int {
        guard current > 0 else { return ebbinghausLadder.first! }
        return ebbinghausLadder.first { $0 > current } ?? ebbinghausLadder.last!
    }
    
    private func closestEbbinghausStep(_ interval: Int) -> Int {
        let safe = max(interval, 1)
        var nearest = ebbinghausLadder.first!
        for step in ebbinghausLadder {
            let stepDiff = abs(step - safe)
            let nearestDiff = abs(nearest - safe)
            if stepDiff < nearestDiff || (stepDiff == nearestDiff && step > nearest) {
                nearest = step
            }
        }
        return nearest
    }
    
    private func resolveStatus(_ interval: Int, _ reviewCount: Int, _ ease: Float, algorithm: AlgorithmVersion) -> Int {
        let masteredInterval = (algorithm == .v4) ? masteredIntervalV4 : masteredIntervalV3
        let masteredMinReview = (algorithm == .v4) ? masteredMinReviewV4 : masteredMinReviewV3
        
        if interval >= masteredInterval && reviewCount >= masteredMinReview && ease >= masteredMinEase {
            return Progress.Status.mastered
        }
        return Progress.Status.learning
    }
    
    private func nextReviewByDays(_ now: TimeInterval, _ days: Int) -> TimeInterval {
        let safeDays = max(days, 1)
        let date = Date(timeIntervalSince1970: now)
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        
        let learningDate = (components.hour ?? 0) < dayRefreshHour
            ? calendar.date(byAdding: .day, value: -1, to: date)!
            : date
        
        var nextComponents = calendar.dateComponents([.year, .month, .day], from: learningDate)
        nextComponents.day! += safeDays
        nextComponents.hour = dayRefreshHour
        nextComponents.minute = 0
        nextComponents.second = 0
        
        return calendar.date(from: nextComponents)!.timeIntervalSince1970
    }
}
