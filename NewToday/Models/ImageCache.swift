import SwiftUI
import Foundation

actor ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 1024 * 1024 * 100 // 100 MB limit
        
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func image(for url: URL) async -> UIImage? {
        // Check memory cache first
        if let cachedImage = memoryCache.object(forKey: url.absoluteString as NSString) {
            return cachedImage
        }
        
        // Check disk cache
        let imagePath = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if let data = try? Data(contentsOf: imagePath),
           let image = UIImage(data: data) {
            // Store in memory cache
            memoryCache.setObject(image, forKey: url.absoluteString as NSString)
            return image
        }
        
        // Download and cache if not found
        guard let image = await downloadImage(from: url) else { return nil }
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: url.absoluteString as NSString)
        
        // Store in disk cache
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: imagePath)
        }
        
        return image
    }
    
    private func downloadImage(from url: URL) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = UIImage(data: data) else {
                return nil
            }
            
            return image
        } catch {
            print("Error downloading image: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func removeImage(for url: URL) {
        memoryCache.removeObject(forKey: url.absoluteString as NSString)
        let imagePath = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        try? fileManager.removeItem(at: imagePath)
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let scale: CGFloat
    let transaction: Transaction
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadedURL: URL?
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image, loadedURL == url {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard !isLoading, let url = url else { return }
        isLoading = true
        
        // Reset image if URL changed
        if loadedURL != url {
            image = nil
        }
        
        if let loadedImage = await ImageCache.shared.image(for: url) {
            withAnimation {
                image = loadedImage
                loadedURL = url
            }
        }
        
        isLoading = false
    }
}