import SwiftUI

struct NutritionInfo: View {
    let label: String
    let value: String
    let unit: String
    var color: Color = Theme.textColor
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
            
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(color)
                .fontWeight(.bold)
            
            Text(unit)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}