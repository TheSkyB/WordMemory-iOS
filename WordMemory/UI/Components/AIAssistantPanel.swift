import SwiftUI

struct AIAssistantPanel: View {
    let word: Word
    @State private var aiContent: String = ""
    @State private var isLoading = false
    @State private var selectedType: AIRequestType = .exampleSentence
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Type selector
            Picker("AI 功能", selection: $selectedType) {
                Text("例句").tag(AIRequestType.exampleSentence)
                Text("助记").tag(AIRequestType.memoryAid)
                Text("分析").tag(AIRequestType.wordAnalysis)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Content area
            ScrollView {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("AI 思考中...")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !aiContent.isEmpty {
                    Text(aiContent)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 40))
                            .foregroundColor(.purple)
                        Text("点击生成 AI 内容")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .frame(maxHeight: 200)
            
            // Generate button
            Button(action: { generateContent() }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("生成")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .cornerRadius(14)
            }
            .disabled(isLoading)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .alert("错误", isPresented: $showError) {
            Button("确定") {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: selectedType) { _ in
            aiContent = ""
        }
    }
    
    private func generateContent() {
        isLoading = true
        aiContent = ""
        
        switch selectedType {
        case .exampleSentence:
            AIService.shared.generateExampleSentence(for: word.word, meaning: word.meaning) { result in
                handleResult(result)
            }
        case .memoryAid:
            AIService.shared.generateMemoryAid(for: word.word, meaning: word.meaning) { result in
                handleResult(result)
            }
        case .wordAnalysis:
            AIService.shared.analyzeWord(word: word.word) { result in
                handleResult(result)
            }
        }
    }
    
    private func handleResult(_ result: Result<String, Error>) {
        isLoading = false
        switch result {
        case .success(let content):
            aiContent = content
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
