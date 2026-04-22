import SwiftUI

struct StatsScreen: View {
    @State private var todayStats: DailyStats?
    @State private var weeklyData: [DailyStats] = []
    @State private var totalWords: Int = 0
    @State private var masteredWords: Int = 0
    @State private var learningWords: Int = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Today's stats card
                    TodayStatsCard(stats: todayStats)
                    
                    // Word mastery progress
                    MasteryProgressCard(
                        total: totalWords,
                        mastered: masteredWords,
                        learning: learningWords
                    )
                    
                    // Weekly chart
                    WeeklyChartCard(weeklyData: weeklyData)
                    
                    // Streak card
                    StreakCard(streakDays: todayStats?.streakDays ?? 0)
                }
                .padding()
            }
            .navigationTitle("学习统计")
            .onAppear {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        let db = SQLiteManager.shared
        todayStats = db.getTodayStats()
        
        // Load weekly data
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        weeklyData = (0..<7).compactMap { dayOffset in
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) {
                let dateStr = formatter.string(from: date)
                return db.loadDailyStats(date: dateStr)
            }
            return nil
        }.reversed()
        
        // Load progress summary
        let allProgress = db.loadAllProgress()
        totalWords = allProgress.count
        masteredWords = allProgress.values.filter { $0.status == Progress.Status.mastered }.count
        learningWords = allProgress.values.filter { $0.status == Progress.Status.learning }.count
    }
}

struct TodayStatsCard: View {
    let stats: DailyStats?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("今日学习")
                    .font(.headline)
                Spacer()
                if let stats = stats, stats.checkedIn {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已打卡")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            HStack(spacing: 24) {
                StatBox(value: "\(stats?.studyCount ?? 0)", label: "学习单词")
                StatBox(value: "\(stats?.reviewCount ?? 0)", label: "复习单词")
                StatBox(value: "\(stats?.masteredCount ?? 0)", label: "新掌握")
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
}

struct StatBox: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.blue)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MasteryProgressCard: View {
    let total: Int
    let mastered: Int
    let learning: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("掌握进度")
                    .font(.headline)
                Spacer()
                Text("\(total) 词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 24)
                    
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                            .frame(width: total > 0 ? geo.size.width * CGFloat(mastered) / CGFloat(total) : 0, height: 24)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .frame(width: total > 0 ? geo.size.width * CGFloat(learning) / CGFloat(total) : 0, height: 24)
                    }
                }
            }
            .frame(height: 24)
            
            HStack {
                Label("已掌握 \(mastered)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Label("学习中 \(learning)", systemImage: "book.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.green.opacity(0.08))
        .cornerRadius(16)
    }
}

struct WeeklyChartCard: View {
    let weeklyData: [DailyStats]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("本周学习")
                    .font(.headline)
                Spacer()
            }
            
            if weeklyData.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyData.indices, id: \.self) { index in
                        let stats = weeklyData[index]
                        let maxValue = max(weeklyData.map { $0.studyCount }.max() ?? 1, 1)
                        let height = CGFloat(stats.studyCount) / CGFloat(maxValue)
                        
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(stats.studyCount > 0 ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 30, height: max(height * 100, 4))
                            
                            Text(dayLabel(for: index))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }
    
    private func dayLabel(for index: Int) -> String {
        let days = ["日", "一", "二", "三", "四", "五", "六"]
        let calendar = Calendar.current
        if let date = calendar.date(byAdding: .day, value: -(6-index), to: Date()) {
            let weekday = calendar.component(.weekday, from: date) - 1
            return days[weekday]
        }
        return ""
    }
}

struct StreakCard: View {
    let streakDays: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("连续打卡")
                    .font(.headline)
                Text("\(streakDays) 天")
                    .font(.title.bold())
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
}
