import SwiftUI

@main
struct WordMemoryApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LearningScreen()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("学习")
                }
                .tag(0)
            
            NotebookScreen()
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("生词本")
                }
                .tag(1)
            
            StatsScreen()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("统计")
                }
                .tag(2)
            
            Text("我的")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("我的")
                }
                .tag(3)
        }
    }
}
