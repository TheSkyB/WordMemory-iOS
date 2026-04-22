import SwiftUI

struct StatsScreen: View {
    @State private var todayCount: Int = 0
    @State private var streakDays: Int = 0
    @State private var totalWords: Int = 0
    @State private var masteredWords: Int = 0
    
    private let db = SQLiteManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("今日统计") {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                        Text("今日学习")
                        Spacer()
                        Text("\(todayCount) 词")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("连续打卡")
                        Spacer()
                        Text("\(streakDays) 天")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("总体进度") {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.green)
                        Text("已学单词")
                        Spacer()
                        Text("\(totalWords) 词")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.purple)
                        Text("已掌握")
                        Spacer()
                        Text("\(masteredWords) 词")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("统计")
            .onAppear {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        let stats = db.getTodayStats()
        todayCount = stats.studyCount
        streakDays = stats.streakDays
        totalWords = db.getTotalWordCount()
        masteredWords = db.getMasteredWordCount()
    }
}
