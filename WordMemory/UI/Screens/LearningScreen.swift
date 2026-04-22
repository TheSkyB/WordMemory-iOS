import SwiftUI

struct LearningScreen: View {
    @StateObject private var viewModel = LearningViewModel()
    @StateObject private var pronunciation = PronunciationService.shared
    @State private var words: [Word] = []
    @State private var showSettings = false
    @State private var showAIAssistant = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.showCompletion {
                    CompletionView(viewModel: viewModel)
                } else if let word = viewModel.currentWord {
                    LearningContentView(
                        viewModel: viewModel,
                        pronunciation: pronunciation,
                        word: word,
                        showAIAssistant: $showAIAssistant
                    )
                } else {
                    EmptyStateView()
                }
            }
            .navigationTitle("学习")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // AI button
                        Button(action: { showAIAssistant = true }) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                        }
                        
                        // Settings
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
        }
        .onAppear {
            if words.isEmpty {
                words = WordbookLoader.shared.loadFromProjectBundle()
                viewModel.loadWords(words)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel, pronunciation: pronunciation)
        }
        .sheet(isPresented: $showAIAssistant) {
            if let word = viewModel.currentWord {
                NavigationView {
                    AIAssistantPanel(word: word)
                        .navigationTitle("AI 助手")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("完成") { showAIAssistant = false }
                            }
                        }
                }
            }
        }
    }
}

struct LearningContentView: View {
    @ObservedObject var viewModel: LearningViewModel
    @ObservedObject var pronunciation: PronunciationService
    let word: Word
    @Binding var showAIAssistant: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Mode selector
            ModeSelectorView(viewModel: viewModel)
            
            // Progress bar
            ProgressBarView(current: viewModel.currentIndex, total: viewModel.totalCount)
            
            // Content based on mode
            if viewModel.learningMode == .recognition {
                WordCardView(
                    viewModel: viewModel,
                    pronunciation: pronunciation,
                    word: word
                )
                .padding(.horizontal)
                
                Spacer()
                
                RecognitionActionView(viewModel: viewModel)
            } else {
                SpellingView(viewModel: viewModel, word: word)
            }
        }
        .padding(.vertical)
    }
}

struct WordCardView: View {
    @ObservedObject var viewModel: LearningViewModel
    @ObservedObject var pronunciation: PronunciationService
    let word: Word
    @State private var offset: CGSize = .zero
    @State private var showSwipeHint = true
    
    var body: some View {
        ZStack {
            // Swipe background indicators
            SwipeBackgroundView(offset: offset)
            
            // Card
            FlipCard(isFlipped: viewModel.isCardFlipped) {
                // Front
                CardFrontView(word: word, pronunciation: pronunciation)
            } back: {
                // Back
                CardBackView(word: word, viewModel: viewModel, pronunciation: pronunciation)
            }
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        showSwipeHint = false
                    }
                    .onEnded { value in
                        let width = value.translation.width
                        let threshold: CGFloat = 100
                        
                        if width < -threshold {
                            // Swipe left - too easy
                            withAnimation {
                                offset = CGSize(width: -500, height: 0)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                viewModel.submitAnswer(.good)
                                offset = .zero
                            }
                        } else if width > threshold {
                            // Swipe right - add to notebook
                            withAnimation {
                                offset = CGSize(width: 500, height: 0)
                            }
                            viewModel.toggleNewWord()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                viewModel.submitAnswer(.hard)
                                offset = .zero
                            }
                        } else {
                            withAnimation {
                                offset = .zero
                            }
                        }
                    }
            )
            .onTapGesture {
                viewModel.flipCard()
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct CardFrontView: View {
    let word: Word
    @ObservedObject var pronunciation: PronunciationService
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Pronunciation button
            Button(action: {
                pronunciation.pronounce(word: word.word)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: pronunciation.isPlaying && pronunciation.currentWord == word.word ? "speaker.wave.3.fill" : "speaker.wave.2")
                        .foregroundColor(.blue)
                    Text(word.word)
                        .font(.system(size: adaptiveFontSize(word.word), weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .minimumScaleFactor(0.5)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            }
            
            if !word.phonetic.isEmpty {
                Text(word.phonetic)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text("轻触卡片查看释义")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    private func adaptiveFontSize(_ text: String) -> CGFloat {
        let length = text.count
        if length <= 8 { return 48 }
        if length <= 12 { return 40 }
        if length <= 16 { return 34 }
        if length <= 24 { return 28 }
        return 22
    }
}

struct CardBackView: View {
    let word: Word
    @ObservedObject var viewModel: LearningViewModel
    @ObservedObject var pronunciation: PronunciationService
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Word header with pronunciation
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.word)
                            .font(.title2.bold())
                        
                        if !word.phonetic.isEmpty {
                            Text(word.phonetic)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        pronunciation.pronounce(word: word.word)
                    }) {
                        Image(systemName: pronunciation.isPlaying && pronunciation.currentWord == word.word ? "speaker.wave.3.fill" : "speaker.wave.2")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                // Meaning
                if !word.meaning.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("释义")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                        Text(word.meaning)
                            .font(.body)
                    }
                }
                
                // Example
                if !word.example.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("例句")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                        Text(word.example)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(12)
                    }
                }
                
                // Extra sections
                ExtraSection(title: "短语", content: word.phrases)
                ExtraSection(title: "近义词", content: word.synonyms)
                ExtraSection(title: "同根词", content: word.relWords)
                
                // Progress info
                if let progress = viewModel.getProgress(for: word.id) {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EF系数: \(String(format: "%.2f", progress.easeFactor))")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("间隔: \(progress.intervalDays)天 · 复习: \(progress.reviewCount)次")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.05), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

struct ExtraSection: View {
    let title: String
    let content: String
    
    var body: some View {
        guard !content.isEmpty else { return EmptyView().eraseToAnyView() }
        
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.blue)
            Text(content)
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.08))
        .cornerRadius(12)
        .eraseToAnyView()
    }
}

struct FlipCard<Front: View, Back: View>: View {
    let front: Front
    let back: Back
    var isFlipped: Bool
    
    init(isFlipped: Bool, @ViewBuilder front: () -> Front, @ViewBuilder back: () -> Back) {
        self.isFlipped = isFlipped
        self.front = front()
        self.back = back()
    }
    
    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .animation(.easeInOut(duration: 0.3), value: isFlipped)
    }
}

struct SwipeBackgroundView: View {
    let offset: CGSize
    
    var body: some View {
        HStack {
            if offset.width < 0 {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("太简单")
                }
                .foregroundColor(.green)
                .padding()
                .background(Color.green.opacity(0.2))
                .cornerRadius(12)
                Spacer()
            }
            
            if offset.width > 0 {
                Spacer()
                HStack {
                    Text("生词本")
                    Image(systemName: "star.fill")
                }
                .foregroundColor(.orange)
                .padding()
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 30)
        .opacity(Swift.min(Swift.abs(offset.width) / 100.0, 1.0))
    }
}

struct RecognitionActionView: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "不认识",
                color: .red,
                isEnabled: !viewModel.isAnswering,
                action: { viewModel.submitAnswer(.again) }
            )
            
            ActionButton(
                title: "模糊",
                color: .orange,
                isEnabled: !viewModel.isAnswering,
                action: { viewModel.submitAnswer(.hard) }
            )
            
            ActionButton(
                title: "认识",
                color: .green,
                isEnabled: !viewModel.isAnswering,
                action: { viewModel.submitAnswer(.good) }
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

struct ActionButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color.opacity(0.15))
                .cornerRadius(14)
        }
        .disabled(!isEnabled)
    }
    
    init(title: String, color: Color, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
    }
}

struct ModeSelectorView: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        Picker("模式", selection: $viewModel.learningMode) {
            Text("认词模式").tag(LearningMode.recognition)
            Text("拼写模式").tag(LearningMode.spelling)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

struct ProgressBarView: View {
    let current: Int
    let total: Int
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("学习进度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(current)/\(total)")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: total > 0 ? geo.size.width * CGFloat(current) / CGFloat(total) : 0, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: current)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal)
    }
}

struct CompletionView: View {
    @ObservedObject var viewModel: LearningViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("今日学习完成")
                .font(.title2.bold())
            
            HStack(spacing: 32) {
                StatItem(label: "今日学习", value: "\(viewModel.todayStudyCount)", unit: "词")
                StatItem(label: "连续打卡", value: "\(viewModel.streakDays)", unit: "天")
            }
            
            Button(action: { viewModel.resetSession() }) {
                Text("继续学习")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("暂无单词")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: LearningViewModel
    @ObservedObject var pronunciation: PronunciationService
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = ""
    @State private var showSaved = false
    @State private var notificationsEnabled = false
    @State private var reminderTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section("算法版本") {
                    Picker("版本", selection: $viewModel.algorithmVersion) {
                        Text("V3 稳定").tag(AlgorithmVersion.v3)
                        Text("V4 验证").tag(AlgorithmVersion.v4)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("发音设置") {
                    Picker("发音来源", selection: $pronunciation.currentSource) {
                        ForEach(PronunciationService.PronunciationSource.allCases, id: \.self) { source in
                            HStack {
                                Image(systemName: source.icon)
                                Text(source.rawValue)
                            }
                            .tag(source)
                        }
                    }
                }
                
                Section("学习提醒") {
                    Toggle("每日提醒", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { enabled in
                            if enabled {
                                NotificationManager.shared.requestAuthorization()
                                let calendar = Calendar.current
                                let hour = calendar.component(.hour, from: reminderTime)
                                let minute = calendar.component(.minute, from: reminderTime)
                                NotificationManager.shared.scheduleDailyReminder(hour: hour, minute: minute)
                            } else {
                                NotificationManager.shared.cancelAllNotifications()
                            }
                        }
                    
                    if notificationsEnabled {
                        DatePicker("提醒时间", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _ in
                                let calendar = Calendar.current
                                let hour = calendar.component(.hour, from: reminderTime)
                                let minute = calendar.component(.minute, from: reminderTime)
                                NotificationManager.shared.scheduleDailyReminder(hour: hour, minute: minute)
                            }
                    }
                }
                
                Section("AI 助手") {
                    SecureField("DeepSeek API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                    Button("保存 API Key") {
                        AIService.setAPIKey(apiKey)
                        showSaved = true
                    }
                    if showSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("已保存")
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .font(.subheadline)
                    }
                }
                
                Section("统计") {
                    HStack {
                        Text("今日学习")
                        Spacer()
                        Text("\(viewModel.todayStudyCount) 词")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("待复习")
                        Spacer()
                        Text("\(viewModel.dueReviewCount) 词")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("打卡") {
                        viewModel.checkIn()
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear {
                apiKey = UserDefaults.standard.string(forKey: "ai_api_key") ?? ""
                showSaved = false
                NotificationManager.shared.checkNotificationStatus { enabled in
                    notificationsEnabled = enabled
                }
            }
        }
    }
}

// Helper extension
extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
