import SwiftUI

struct SpellingView: View {
    @ObservedObject var viewModel: LearningViewModel
    let word: Word
    
    var body: some View {
        VStack(spacing: 20) {
            // Meaning display
            VStack(spacing: 12) {
                Text("根据释义拼写单词")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(word.meaning)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(16)
            }
            
            // Letter hint (if requested)
            if let hint = viewModel.spellingHint, viewModel.revealedLetterCount > 0 {
                Text(hint)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // Input field
            if !viewModel.showSpellingResult {
                VStack(spacing: 12) {
                    TextField("输入单词", text: $viewModel.spellingInput)
                        .font(.title2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button(action: { viewModel.requestLetterHint() }) {
                            Label("提示", systemImage: "lightbulb")
                                .foregroundColor(.orange)
                        }
                        
                        Button(action: { viewModel.submitSpelling() }) {
                            Text("提交")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Result display
            if viewModel.showSpellingResult, let outcome = viewModel.spellingOutcome {
                SpellingResultView(
                    outcome: outcome,
                    correctWord: word.word,
                    userInput: viewModel.spellingInput,
                    hint: viewModel.spellingHint
                )
                
                Button(action: { viewModel.continueAfterSpelling() }) {
                    Text("继续")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
}

struct SpellingResultView: View {
    let outcome: SpellingOutcome
    let correctWord: String
    let userInput: String
    let hint: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Result icon and text
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundColor(resultColor)
                
                Text(resultText)
                    .font(.title2.bold())
                    .foregroundColor(resultColor)
            }
            
            // Word comparison
            VStack(spacing: 8) {
                HStack {
                    Text("你的答案:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(userInput)
                        .font(.body)
                        .foregroundColor(outcome == .perfect ? .green : .red)
                }
                
                HStack {
                    Text("正确答案:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(correctWord)
                        .font(.body.bold())
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.08))
            .cornerRadius(12)
            
            // Hint display
            if let hint = hint, outcome != .perfect {
                Text("提示: \(hint)")
                    .font(.body)
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(resultColor.opacity(0.08))
        )
        .padding(.horizontal)
    }
    
    private var iconName: String {
        switch outcome {
        case .perfect: return "checkmark.circle.fill"
        case .retrySuccess: return "checkmark.circle"
        case .hinted: return "exclamationmark.circle"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private var resultText: String {
        switch outcome {
        case .perfect: return "完美！"
        case .retrySuccess: return "接近正确"
        case .hinted: return "需要练习"
        case .failed: return "再试一次"
        }
    }
    
    private var resultColor: Color {
        switch outcome {
        case .perfect: return .green
        case .retrySuccess: return .blue
        case .hinted: return .orange
        case .failed: return .red
        }
    }
}
