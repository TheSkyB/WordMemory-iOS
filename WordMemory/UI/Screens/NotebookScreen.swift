import SwiftUI

struct NotebookScreen: View {
    @State private var notebookWords: [Word] = []
    private let notebook = NotebookManager.shared
    
    var body: some View {
        NavigationView {
            List {
                if notebookWords.isEmpty {
                    Text("暂无生词")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(notebookWords) { word in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(word.word)
                                    .font(.headline)
                                Spacer()
                                Button(action: {
                                    notebook.removeFromNotebook(wordId: word.id)
                                    loadNotebook()
                                }) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            Text(word.meaning)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("生词本")
            .onAppear {
                loadNotebook()
            }
        }
    }
    
    private func loadNotebook() {
        notebookWords = notebook.getNotebookWords()
    }
}
