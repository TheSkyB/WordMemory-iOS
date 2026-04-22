import SwiftUI

struct ProfileScreen: View {
    @StateObject private var viewModel = LearningViewModel()
    @ObservedObject private var pronunciation = PronunciationService.shared
    @State private var todayStudyCount: Int = 0
    @State private var streakDays: Int = 0
    @State private var totalWords: Int = 0
    @State private var masteredWords: Int = 0
    @State private var wordbookCount: Int = 0
    @State private var showCheckInAlert = false
    @State private var checkInMessage = ""
    
    private let db = SQLiteManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // User card
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("考研战士")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("坚持就是胜利 💪")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Today's stats
                Section("今日") {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("今日学习")
                        Spacer()
                        Text("\(todayStudyCount) 词")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        Text("连续打卡")
                        Spacer()
                        Text("\(streakDays) 天")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                }
                
                // Learning progress
                Section("学习进度") {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("已学单词")
                        Spacer()
                        Text("\(totalWords) 词")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24)
                        Text("已掌握")
                        Spacer()
                        Text("\(masteredWords) 词")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(.indigo)
                            .frame(width: 24)
                        Text("词库总量")
                        Spacer()
                        Text("\(wordbookCount) 词")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                }
                
                // Actions
                Section("操作") {
                    Button {
                        viewModel.checkIn()
                        let stats = db.getTodayStats()
                        checkInMessage = "打卡成功！今日已学习 \(stats.studyCount) 词，连续 \(stats.streakDays) 天 🔥"
                        showCheckInAlert = true
                        loadStats()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            Text("每日打卡")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink {
                        SettingsView(viewModel: viewModel, pronunciation: pronunciation)
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text("设置")
                        }
                    }
                }
                
                // About
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("算法")
                        Spacer()
                        Text("SM-2 间隔重复")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
            .alert("打卡成功", isPresented: $showCheckInAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(checkInMessage)
            }
            .onAppear {
                loadStats()
            }
        }
    }
    
    private func loadStats() {
        let stats = db.getTodayStats()
        todayStudyCount = stats.studyCount
        streakDays = stats.streakDays
        totalWords = db.getTotalWordCount()
        masteredWords = db.getMasteredWordCount()
        wordbookCount = WordbookLoader.shared.loadFromProjectBundle().count
    }
}
