import SwiftUI

struct AdaptiveBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    var isFlipped: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? (isFlipped
                            ? [Color.green.opacity(0.15), Color.black]
                            : [Color.blue.opacity(0.2), Color.black])
                        : (isFlipped
                            ? [Color.green.opacity(0.05), Color.white]
                            : [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(24)
            .shadow(
                color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.1),
                radius: 10,
                x: 0,
                y: 4
            )
    }
}

extension View {
    func adaptiveBackground() -> some View {
        modifier(AdaptiveBackground())
    }
    
    func cardBackground(isFlipped: Bool = false) -> some View {
        modifier(CardBackground(isFlipped: isFlipped))
    }
}

// Color extensions for dark mode
extension Color {
    static let adaptiveBackground = Color(uiColor: .systemBackground)
    static let adaptiveSecondary = Color(uiColor: .secondarySystemBackground)
    static let adaptiveLabel = Color(uiColor: .label)
    static let adaptiveSecondaryLabel = Color(uiColor: .secondaryLabel)
}
