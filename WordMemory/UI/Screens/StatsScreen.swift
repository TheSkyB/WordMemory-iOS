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
                    NavigationLink(destination: WordListView(
                        title: "今日学习",
                        wordIds: db.getTodayStudiedWordIds(),
                        emptyText: "今天还没有学习任何单词"
                    )) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundColor(.blue)
                            Text("今日学习")
                            Spacer()
                            Text("\(todayCount) 词")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
                    NavigationLink(destination: WordListView(
                        title: "已学单词",
                        wordIds: db.getAllStudiedWordIds(),
                        emptyText: "还没有学习任何单词"
                    )) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.green)
                            Text("已学单词")
                            Spacer()
                            Text("\(totalWords) 词")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: WordListView(
                        title: "已掌握",
                        wordIds: db.getMasteredWordIds(),
                        emptyText: "还没有掌握任何单词"
                    )) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.purple)
                            Text("已掌握")
                            Spacer()
                            Text("\(masteredWords) 词")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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

// MARK: - Word List Detail View

struct WordListView: View {
    let title: String
    let wordIds: [Int64]
    let emptyText: String
    
    /// Resolve word IDs to Word objects using cached loader
    private var words: [Word] {
        let allWords = WordbookLoader.shared.loadFromProjectBundle()
        let idSet = Set(wordIds)
        return allWords.filter { idSet.contains($0.id) }
    }
    
    var body: some View {
        List {
            if words.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(emptyText)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                HStack {
                    Text("共 \(words.count) 词")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
                
                ForEach(words) { word in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(word.word)
                                .font(.headline)
                            if !word.phonetic.isEmpty {
                                Text(word.phonetic)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text(word.meaning)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(title)
    }
}
