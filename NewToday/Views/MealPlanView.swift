import SwiftUI

struct MealPlanView: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var mealService: MealService
    @State private var selectedDate = Date()
    @State private var showingMealDetail = false
    @State private var selectedMeal: Meal?
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var selectedFilters: Set<DietaryRestriction> = []
    @State private var mealTypeFilter: MealType? = nil
    
    // Change access level from private to internal
    static let imageCache = NSCache<NSString, UIImage>()
    
    // Add lazy loading state
    @State private var visibleMealTypes: Set<MealType> = []
    
    var mealPlan: DailyMealPlan? {
        mealService.getDailyMealPlan(for: selectedDate)
    }
    
    var filteredMeals: [Meal] {
        var meals = [
            mealPlan?.breakfast,
            mealPlan?.lunch,
            mealPlan?.dinner
        ].compactMap { $0 }
        meals.append(contentsOf: mealPlan?.snacks ?? [])
        
        return meals.filter { meal in
            let matchesSearch = searchText.isEmpty || 
                meal.name.localizedCaseInsensitiveContains(searchText) ||
                meal.ingredients.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            
            let matchesType = mealTypeFilter == nil || meal.mealType == mealTypeFilter
            
            let matchesFilters = selectedFilters.isEmpty || 
                !selectedFilters.contains(where: { restriction in
                    meal.ingredients.contains(where: { ingredient in
                        switch restriction {
                        case .vegan, .vegetarian:
                            return ingredient.localizedCaseInsensitiveContains("meat") ||
                                   ingredient.localizedCaseInsensitiveContains("chicken") ||
                                   ingredient.localizedCaseInsensitiveContains("beef")
                        case .glutenFree:
                            return ingredient.localizedCaseInsensitiveContains("flour") ||
                                   ingredient.localizedCaseInsensitiveContains("bread")
                        case .dairyFree:
                            return ingredient.localizedCaseInsensitiveContains("milk") ||
                                   ingredient.localizedCaseInsensitiveContains("cheese")
                        case .nutFree:
                            return ingredient.localizedCaseInsensitiveContains("nut") ||
                                   ingredient.localizedCaseInsensitiveContains("almond")
                        case .none:
                            return false
                        }
                    })
                })
            
            return matchesSearch && matchesType && matchesFilters
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Layout.largeSpacing) {
                // Search and Filter Bar
                searchAndFilterBar
                    .padding(.top)
                
                // Date Selection
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(Theme.premiumRed)
                    .onChange(of: selectedDate) { _ in
                        if mealService.getDailyMealPlan(for: selectedDate) == nil {
                            mealService.generateFullDayMealPlan(for: selectedDate)
                        }
                    }
                    .cardStyle()
                
                // Nutrition Summary
                nutritionSummary
                
                if !searchText.isEmpty || !selectedFilters.isEmpty || mealTypeFilter != nil {
                    // Search Results
                    searchResultsList
                } else {
                    LazyVStack(spacing: Theme.Layout.standardSpacing) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            mealSection(for: mealType)
                                .onAppear {
                                    visibleMealTypes.insert(mealType)
                                }
                                .onDisappear {
                                    visibleMealTypes.remove(mealType)
                                }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.backgroundBlack)
        .navigationTitle("Meal Plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: generateMealPlan) {
                    HStack(spacing: 4) {
                        Text("Regenerate")
                        Image(systemName: "arrow.clockwise")
                    }
                    .foregroundColor(Theme.premiumRed)
                }
            }
        }
        .overlay {
            if mealService.isGenerating {
                Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            ProgressView()
                                .tint(Theme.premiumRed)
                                .scaleEffect(1.5)
                                .padding()
                            Text("Generating your meal plan...")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(25)
                        .background(Theme.secondaryBlack)
                        .cornerRadius(15)
                    )
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: mealService.isGenerating)
        .sheet(isPresented: $showingFilters) {
            FilterSheet(
                selectedFilters: $selectedFilters,
                mealTypeFilter: $mealTypeFilter
            )
        }
        .sheet(isPresented: $showingMealDetail) {
            if let meal = selectedMeal {
                MealDetailSheet(meal: meal)
            }
        }
        .onAppear {
            // Generate meal plan for the current date if it doesn't exist
            if mealService.getDailyMealPlan(for: selectedDate) == nil {
                mealService.generateFullDayMealPlan(for: selectedDate)
            }
        }
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: Theme.Layout.smallSpacing) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.secondaryText)
                
                TextField("Search meals or ingredients", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(Theme.textColor)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.secondaryText)
                    }
                }
                
                Button(action: { showingFilters = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle\(selectedFilters.isEmpty && mealTypeFilter == nil ? "" : ".fill")")
                        .foregroundColor(Theme.premiumRed)
                }
            }
            .padding()
            .background(Theme.secondaryBlack)
            .cornerRadius(Theme.Layout.cornerRadius)
            
            // Active Filters
            if !selectedFilters.isEmpty || mealTypeFilter != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if let mealType = mealTypeFilter {
                            FilterTag(text: mealType.rawValue) {
                                mealTypeFilter = nil
                            }
                        }
                        
                        ForEach(Array(selectedFilters), id: \.self) { filter in
                            FilterTag(text: filter.rawValue) {
                                selectedFilters.remove(filter)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var searchResultsList: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Search Results")
                .font(Theme.Typography.headline)
            
            if filteredMeals.isEmpty {
                Text("No meals found matching your criteria")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(filteredMeals) { meal in
                    MealRow(meal: meal) {
                        selectedMeal = meal
                        showingMealDetail = true
                    }
                }
            }
        }
        .cardStyle()
    }
    
    private var nutritionSummary: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            Text("Daily Nutrition")
                .font(Theme.Typography.headline)
            
            HStack {
                NutritionProgressBar(
                    value: Double(mealPlan?.totalCalories ?? 0),
                    target: Double(userProfileManager.userProfile?.dailyCalorieNeeds ?? 2000),
                    title: "Calories",
                    unit: "kcal",
                    color: Theme.premiumRed
                )
                
                NutritionProgressBar(
                    value: mealPlan?.totalProtein ?? 0,
                    target: 150,
                    title: "Protein",
                    unit: "g",
                    color: Theme.accentBlue
                )
                
                NutritionProgressBar(
                    value: mealPlan?.totalCarbs ?? 0,
                    target: 250,
                    title: "Carbs",
                    unit: "g",
                    color: Theme.accentGreen
                )
                
                NutritionProgressBar(
                    value: mealPlan?.totalFats ?? 0,
                    target: 70,
                    title: "Fats",
                    unit: "g",
                    color: Color.yellow
                )
            }
        }
        .cardStyle()
    }
    
    private var mealsList: some View {
        VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
            ForEach(MealType.allCases, id: \.self) { mealType in
                mealSection(for: mealType)
            }
        }
    }
    
    private func mealSection(for type: MealType) -> some View {
        VStack(alignment: .leading, spacing: Theme.Layout.smallSpacing) {
            HStack {
                Text(type.rawValue)
                    .font(Theme.Typography.headline)
                
                Spacer()
                
                Button(action: {
                    mealService.generateMeal(for: type, on: selectedDate)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Theme.premiumRed)
                }
            }
            
            if let meal = getMeal(for: type) {
                MealRow(meal: meal) {
                    selectedMeal = meal
                    showingMealDetail = true
                }
            } else {
                EmptyMealRow()
            }
        }
        .cardStyle()
    }
    
    private func getMeal(for type: MealType) -> Meal? {
        return mealService.getMeal(for: type, on: selectedDate)
    }
    
    private func generateMealPlan() {
        mealService.generateFullDayMealPlan(for: selectedDate)
    }
    
    private func loadCachedImage(from urlString: String) -> UIImage? {
        if let cached = MealPlanView.imageCache.object(forKey: urlString as NSString) {
            return cached
        }
        return nil
    }
    
    private func cacheImage(_ image: UIImage, for urlString: String) {
        MealPlanView.imageCache.setObject(image, forKey: urlString as NSString)
    }
}

struct NutritionProgressBar: View {
    let value: Double
    let target: Double
    let title: String
    let unit: String
    let color: Color
    
    private var progress: Double {
        min(value / target, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
            
            ThemeCircleProgress(
                progress: progress,
                color: color,
                size: 50,
                showText: false
            )
            
            Text("\(Int(value))/\(Int(target))")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textColor)
            
            Text(unit)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.secondaryText)
        }
    }
}

// Optimize MealRow to use cached images
struct MealRow: View {
    let meal: Meal
    let onTap: () -> Void
    @State private var imageLoadTime = Date()  // Add this to force image refresh
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let imageURL = meal.imageURL.flatMap(URL.init) {
                    CachedAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .cornerRadius(Theme.Layout.smallSpacing)
                    } placeholder: {
                        Rectangle()
                            .fill(Theme.secondaryBlack)
                            .frame(width: 60, height: 60)
                            .cornerRadius(Theme.Layout.smallSpacing)
                    }
                    .id(imageURL.absoluteString + String(imageLoadTime.timeIntervalSince1970))
                }
                
                // Meal info
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(Theme.Typography.subheadline)
                        .foregroundColor(Theme.textColor)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(meal.calories)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Theme.premiumRed)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "p.circle.fill")
                                .font(.system(size: 10))
                            Text("\(Int(meal.protein))g")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Theme.accentBlue)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "c.circle.fill")
                                .font(.system(size: 10))
                            Text("\(Int(meal.carbs))g")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(Theme.accentGreen)
                    }
                    .foregroundColor(Theme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.secondaryText)
            }
            .padding()
            .background(Theme.secondaryBlack)
            .cornerRadius(Theme.Layout.cornerRadius)
        }
        .onAppear {
            imageLoadTime = Date()  // Force refresh when view appears
        }
        .onChange(of: meal.imageURL) { _ in
            imageLoadTime = Date()  // Force refresh when URL changes
        }
    }
}

struct EmptyMealRow: View {
    var body: some View {
        HStack {
            Text("No meal planned")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.secondaryText)
            Spacer()
        }
        .padding()
        .background(Theme.secondaryBlack)
        .cornerRadius(Theme.Layout.cornerRadius)
    }
}

struct MealDetailSheet: View {
    let meal: Meal
    @Environment(\.dismiss) private var dismiss
    @State private var imageLoadTime = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                    // Meal image with CachedAsyncImage
                    if let imageURL = meal.imageURL.flatMap(URL.init) {
                        CachedAsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Theme.secondaryBlack)
                                .frame(height: 200)
                        }
                        .cornerRadius(Theme.Layout.cornerRadius)
                        .id(imageURL.absoluteString + String(imageLoadTime.timeIntervalSince1970))
                    }
                    
                    // Meal name
                    Text(meal.name)
                        .font(Theme.Typography.title)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                    
                    // Nutrition info
                    VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                        Text("Nutrition Info")
                            .font(Theme.Typography.headline)
                        
                        HStack {
                            NutritionInfo(label: "Calories", value: "\(meal.calories)", unit: "kcal", color: Theme.premiumRed)
                            NutritionInfo(label: "Protein", value: "\(Int(meal.protein))", unit: "g", color: Theme.accentBlue)
                            NutritionInfo(label: "Carbs", value: "\(Int(meal.carbs))", unit: "g", color: Theme.accentGreen)
                            NutritionInfo(label: "Fats", value: "\(Int(meal.fats))", unit: "g", color: Color.yellow)
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                        Text("Ingredients")
                            .font(Theme.Typography.headline)
                        
                        ForEach(meal.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(Theme.premiumRed)
                                    .padding(.top, 6)
                                
                                Text(ingredient)
                                    .font(Theme.Typography.body)
                            }
                        }
                    }
                    .padding()
                    .cardStyle()
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: Theme.Layout.standardSpacing) {
                        Text("Instructions")
                            .font(Theme.Typography.headline)
                        
                        ForEach(Array(meal.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 10) {
                                Text("\(index + 1).")
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.premiumRed)
                                    .frame(width: 20, alignment: .leading)
                                
                                Text(instruction)
                                    .font(Theme.Typography.body)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                    .cardStyle()
                }
                .padding()
            }
            .background(Theme.backgroundBlack)
            .navigationTitle(meal.mealType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            imageLoadTime = Date()
        }
    }
}

struct FilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFilters: Set<DietaryRestriction>
    @Binding var mealTypeFilter: MealType?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meal Type") {
                    ForEach(MealType.allCases, id: \.self) { type in
                        HStack {
                            Text(type.rawValue)
                            Spacer()
                            if mealTypeFilter == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Theme.premiumRed)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if mealTypeFilter == type {
                                mealTypeFilter = nil
                            } else {
                                mealTypeFilter = type
                            }
                        }
                    }
                }
                
                Section("Dietary Restrictions") {
                    ForEach(DietaryRestriction.allCases.filter { $0 != .none }, id: \.self) { restriction in
                        Toggle(restriction.rawValue, isOn: Binding(
                            get: { selectedFilters.contains(restriction) },
                            set: { isOn in
                                if isOn {
                                    selectedFilters.insert(restriction)
                                } else {
                                    selectedFilters.remove(restriction)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedFilters.removeAll()
                        mealTypeFilter = nil
                    }
                    .foregroundColor(Theme.premiumRed)
                }
            }
        }
    }
}

struct FilterTag: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(Theme.Typography.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Theme.secondaryBlack)
        .cornerRadius(12)
    }
}