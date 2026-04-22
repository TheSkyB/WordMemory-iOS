import SwiftUI

struct NotebookScreen: View {
    @StateObject private var notebook = NotebookManager.shared
    @State private var words: [Word] = []
    @State private var searchText = ""
    
    var filteredWords: [Word] {
        if searchText.isEmpty {
            return notebook.getNewWords(from: words)
        }
        return notebook.getNewWords(from: words).filter {
            $0.word.localizedCaseInsensitiveContains(searchText) ||
            $0.meaning.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if filteredWords.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "star")
                                    .font(.system(size: 50))
                                    .foregroundColor(.secondary)
                                Text("生词本为空")
                                    .foregroundColor(.secondary)
                                Text("学习时右滑单词可加入生词本")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            Spacer()
                        }
                    }
                } else {
                    Section("\(filteredWords.count) 个生词") {
                        ForEach(filteredWords) { word in
                            NotebookWordRow(word: word, notebook: notebook)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("生词本")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .onAppear {
                if words.isEmpty {
                    words = WordbookLoader.shared.loadFromProjectBundle()
                }
            }
        }
    }
}

struct NotebookWordRow: View {
    let word: Word
    @ObservedObject var notebook: NotebookManager
    @State private var showDetail = false
    
    var body: some View {
        Button(action: { showDetail = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(word.word)
                        .font(.headline)
                    Text(word.meaning)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button(action: {
                    notebook.remove(wordId: word.id)
                }) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            WordDetailSheet(word: word)
        }
    }
}

struct WordDetailSheet: View {
    let word: Word
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Word header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(word.word)
                            .font(.system(size: 36, weight: .bold))
                        
                        if !word.phonetic.isEmpty {
                            Text(word.phonetic)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Meaning
                    DetailSection(title: "释义", content: word.meaning)
                    
                    // Example
                    if !word.example.isEmpty {
                        DetailSection(title: "例句", content: word.example)
                    }
                    
                    // Phrases
                    if !word.phrases.isEmpty {
                        DetailSection(title: "短语", content: word.phrases)
                    }
                    
                    // Synonyms
                    if !word.synonyms.isEmpty {
                        DetailSection(title: "近义词", content: word.synonyms)
                    }
                    
                    // Related words
                    if !word.relWords.isEmpty {
                        DetailSection(title: "同根词", content: word.relWords)
                    }
                }
                .padding()
            }
            .navigationTitle("单词详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(content)
                .font(.body)
        }
    }
}
