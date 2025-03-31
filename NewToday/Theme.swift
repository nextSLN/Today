import SwiftUI

/// App-wide theming system providing consistent styling across the application
struct Theme {
    // MARK: - Core Colors
    static let backgroundBlack = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let secondaryBlack = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let premiumRed = Color(red: 0.93, green: 0.26, blue: 0.26)
    static let textColor = Color.white
    static let secondaryText = Color.gray
    static let accentBlue = Color(red: 0.0, green: 0.5, blue: 0.9)
    static let accentGreen = Color(red: 0.32, green: 0.75, blue: 0.40)
    
    // MARK: - Semantic Colors
    static let success = accentGreen
    static let warning = Color.yellow
    static let error = premiumRed
    static let info = accentBlue
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle
        static let title = Font.title
        static let title2 = Font.title2
        static let title3 = Font.title3
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
        static let footnote = Font.footnote
    }
    
    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 12
        static let standardPadding: CGFloat = 16
        static let standardSpacing: CGFloat = 8
        static let largeSpacing: CGFloat = 16
        static let smallSpacing: CGFloat = 4
    }
    
    // MARK: - View Modifiers
    struct CardStyle: ViewModifier {
        var padding: CGFloat
        
        init(padding: CGFloat = Layout.standardPadding) {
            self.padding = padding
        }
        
        func body(content: Content) -> some View {
            content
                .padding(padding)
                .background(secondaryBlack)
                .cornerRadius(Layout.cornerRadius)
        }
    }
    
    struct PrimaryButtonStyle: ViewModifier {
        var isEnabled: Bool = true
        
        func body(content: Content) -> some View {
            content
                .padding()
                .background(isEnabled ? premiumRed : premiumRed.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(Layout.cornerRadius)
                .shadow(color: isEnabled ? premiumRed.opacity(0.3) : Color.clear, 
                        radius: 10, x: 0, y: 5)
                .animation(.easeInOut(duration: 0.2), value: isEnabled)
        }
    }
    
    struct SecondaryButtonStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color.black.opacity(0.3))
                .foregroundColor(textColor)
                .cornerRadius(Layout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .stroke(premiumRed, lineWidth: 1)
                )
        }
    }
    
    struct TextFieldStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(Layout.cornerRadius)
                .foregroundColor(textColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .stroke(secondaryText.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(padding: CGFloat = Theme.Layout.standardPadding) -> some View {
        modifier(Theme.CardStyle(padding: padding))
    }
    
    func primaryButton(isEnabled: Bool = true) -> some View {
        modifier(Theme.PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButton() -> some View {
        modifier(Theme.SecondaryButtonStyle())
    }
    
    func themedTextField() -> some View {
        modifier(Theme.TextFieldStyle())
    }
    
    func standardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}