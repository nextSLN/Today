import SwiftUI

struct WeeklyActivityChart: View {
    let weeklySteps: [Int]
    private let weekDays = ["S", "M", "T", "W", "T", "F", "S"]
    @State private var selectedDay: Int? = nil
    @State private var isShowingTooltip = false
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing * 1.2) { // Increased spacing
            // Header section with more padding
            HStack {
                Text("Weekly Steps")
                    .font(Theme.Typography.headline)
                
                Spacer()
                
                Text("Total: \(weeklySteps.reduce(0, +))")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.secondaryText)
            }
            .padding(.horizontal, 8)
            
            // Chart section with animations
            HStack(alignment: .bottom, spacing: Theme.Layout.standardSpacing) {
                ForEach(Array(weeklySteps.enumerated()), id: \.offset) { index, steps in
                    VStack(spacing: 8) { // Increased spacing between elements
                        // Step count label
                        Text("\(steps/100)")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.secondaryText)
                            .opacity(selectedDay == index ? 1 : 0.7)
                        
                        // Bar chart column
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 30, height: 120)
                            
                            Rectangle()
                                .fill(selectedDay == index ? Theme.premiumRed : Theme.accentBlue.opacity(0.8))
                                .frame(width: 30, height: animateChart ? CGFloat(min(steps, 10000)) / 10000.0 * 120 : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateChart)
                        }
                        .cornerRadius(Theme.Layout.cornerRadius)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedDay == index {
                                    selectedDay = nil
                                } else {
                                    selectedDay = index
                                }
                            }
                        }
                        
                        // Day label with more emphasis on selected day
                        Text(weekDays[index])
                            .font(Theme.Typography.caption)
                            .foregroundColor(selectedDay == index ? Theme.premiumRed : Theme.secondaryText)
                            .fontWeight(selectedDay == index ? .bold : .regular)
                    }
                    .overlay {
                        if selectedDay == index {
                            // Enhanced tooltip
                            VStack {
                                Text("\(steps) steps")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Theme.premiumRed)
                                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    )
                                    .offset(y: -40)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }
            
            // Progress indicators with more emphasis
            HStack(spacing: Theme.Layout.standardSpacing * 1.5) {
                ProgressIndicator(
                    title: "Daily Average",
                    value: "\(weeklySteps.reduce(0, +) / 7)",
                    color: Theme.accentBlue
                )
                
                ProgressIndicator(
                    title: "Best Day",
                    value: "\(weeklySteps.max() ?? 0)",
                    color: Theme.premiumRed
                )
            }
            .padding(.top, Theme.Layout.smallSpacing)
        }
        .onAppear {
            // Animate the chart bars when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.8)) {
                    animateChart = true
                }
            }
        }
        .onDisappear {
            animateChart = false
        }
    }
}

struct ProgressIndicator: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
            
            Text(value)
                .font(Theme.Typography.caption.bold())
                .foregroundColor(Theme.textColor)
        }
    }
}