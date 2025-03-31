import SwiftUI

struct ThemeTag: View {
    let text: String
    var color: Color = Theme.premiumRed
    
    var body: some View {
        Text(text)
            .font(.system(.caption, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}