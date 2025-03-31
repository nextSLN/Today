import SwiftUI

internal struct ThemeCircleProgress: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 10
    var size: CGFloat = 100
    var showText: Bool = true
    var icon: String? = nil
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(CGFloat(progress), 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
            
            if showText {
                Text("\(Int(progress * 100))%")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
            }
            
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size * 0.3))
                    .foregroundColor(color)
            }
        }
        .frame(width: size, height: size)
    }
}