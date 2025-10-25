//
//  ContentView.swift
//  superPiyan
//
//  Created by user20 on 2025/10/9.
//

import SwiftUI
import WebKit

struct ModelInfo: Codable, Hashable {
    let title: String
    let url: String?
    
    // Use a Codable-friendly representation for the image (e.g., an asset name or a URL string)
    let image: String?
    let parameters: String
    let download_last_month: String?
    let model_tree: [String]

    enum CodingKeys: String, CodingKey {
        case title
        case url
        case image
        case parameters
        case download_last_month
        case model_tree
    }

    init(
        title: String,
        url: String?,
        image: String?,
        parameters: String,
        download_last_month: String?,
        model_tree: [String]
    ) {
        self.title = title
        self.url = url
        self.image = image
        self.parameters = parameters
        self.download_last_month = download_last_month
        self.model_tree = model_tree
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // Provide safe defaults for potentially null/missing fields
        self.title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.url = try c.decodeIfPresent(String.self, forKey: .url)
        self.image = try c.decodeIfPresent(String.self, forKey: .image)
        self.parameters = try c.decodeIfPresent(String.self, forKey: .parameters) ?? ""
        self.download_last_month = try c.decodeIfPresent(String.self, forKey: .download_last_month)
        self.model_tree = try c.decodeIfPresent([String].self, forKey: .model_tree) ?? []
    }
}

struct Model_name_View: View {
    var Modelinfo: ModelInfo

    var body: some View {
        HStack {
            if let imageName = Modelinfo.image, !imageName.isEmpty, UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50 , height: 50)
                    .cornerRadius(16.0)
            } else {
                // Placeholder when image is missing or not found in assets
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.gray.opacity(0.2))
                    Image(systemName: "photo")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50, height: 50)
            }

            Text(Modelinfo.title.isEmpty ? "Untitled Model" : Modelinfo.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                // 核心：玻璃質感的材質背景（iOS 15+）
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                // 玻璃邊緣高光的描邊
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                // 柔和陰影，讓卡片更浮起來
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)

        }
    }
}

struct model_detail: View {
    var Modelinfo: ModelInfo
    
    @State private var selectedTab: DetailTab = .overview
    @State private var webProgress: Double = 0.0
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var isSpinning: Bool = false
    
    enum DetailTab: String, CaseIterable, Identifiable {
        case overview = "詳細資訊"
        case webpage = "網頁"
        
        var id: String { rawValue }
    }
    
    // A safe, single string to display for downloads
    private var downloadsText: String {
        let value = Modelinfo.download_last_month ?? ""
        if value == "Downloads are not tracked for this model.How to track" {
            return "no data"
        }
        return value.isEmpty ? "—" : value
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.35),
                    Color.purple.opacity(0.35),
                    Color.black.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    
                    Picker("", selection: $selectedTab) {
                        ForEach(DetailTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    Group {
                        switch selectedTab {
                        case .overview:
                            overviewSection
                        case .webpage:
                            webSection
                        }
                    }
                    .animation(.easeInOut, value: selectedTab)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
            
        }
        .navigationTitle("Model")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Components
    
    private var headerCard: some View {
        HStack(alignment: .center, spacing: 16) {
            modelImage
                .frame(width: 72, height: 72)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
            
            Text(Modelinfo.title)
                .font(.system(size: 20))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Specifications: parameters + download_last_month
            VStack(alignment: .leading, spacing: 12) {
                Text("Specifications")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 10) {
                    labeledValue(icon: "slider.horizontal.3", title: "Parameters", value: Modelinfo.parameters.isEmpty ? "—" : Modelinfo.parameters)
                    
                    labeledValue(icon: "arrow.down.circle.fill",
                                 title: "Downloads (last month)",
                                 value: downloadsText)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            )
            
            // Model Tree section
            if !Modelinfo.model_tree.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Model Tree")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    tagGrid(tags: Modelinfo.model_tree)
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
            }
            
            // Hugging Face link preview
            if let urlString = Modelinfo.url, let url = URL(string: urlString) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hugging Face")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(url.absoluteString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                    
                    HStack {
                        Spacer()
                        Link(destination: url) {
                            Label("在 Safari 開啟", systemImage: "safari")
                                .font(.callout.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.15), in: Capsule())
                        }
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }
    
    private var webSection: some View {
        VStack(spacing: 0) {
            if let urlString = Modelinfo.url, let url = URL(string: urlString) {
                ProgressView(value: webProgress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .opacity(webProgress < 1.0 ? 1 : 0)
                    .animation(.easeInOut, value: webProgress)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                
                WebView(url: url, progress: $webProgress)
                    .frame(minHeight:(horizontalSizeClass == .compact) ? 400 : 1000)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.25), lineWidth: 1)
                    )
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(.yellow)
                    Text("沒有可用的 Hugging Face 連結")
                        .font(.headline)
                    Text("這個模型缺少網址或網址格式不正確。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }
    
    private var modelImage: some View {
        Group {
            if let imageString = Modelinfo.image, !imageString.isEmpty {
                if imageString.lowercased().hasPrefix("http"),
                   let url = URL(string: imageString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.gray.opacity(0.2))
                                ProgressView()
                            }
                        case .success(let img):
                            img
                                .resizable()
                                .scaledToFill()
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        case .failure:
                            placeholderImage
                        @unknown default:
                            placeholderImage
                        }
                    }
                } else if UIImage(named: imageString) != nil {
                    Image(imageString)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    placeholderImage
                }
            } else {
                placeholderImage
            }
        }
    }
    
    private var placeholderImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.gray.opacity(0.2))
            Image(systemName: "photo")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
    

    private func labeledValue(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
    
    private func tagGrid(tags: [String]) -> some View {
        let columns = [GridItem(.adaptive(minimum: 100), spacing: 8)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(.primary)
            }
        }
    }
}

// MARK: - A lightweight SwiftUI WebView (WKWebView)
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var progress: Double
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        
        // KVO for progress
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No-op
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard keyPath == "estimatedProgress",
                  let webView = object as? WKWebView else { return }
            DispatchQueue.main.async {
                self.parent.progress = webView.estimatedProgress
            }
        }
    }
}

struct ContentView: View {
    @State private var tts_infos: [ModelInfo] = []
    @State private var chat_infos: [ModelInfo] = []
    @State private var ocr_infos: [ModelInfo] = []
    @State private var isRootSpinning: Bool = false

    private func loadNames(file: String) -> [ModelInfo] {
        // Load tts_model_info.json from the app bundle
        guard let url = Bundle.main.url(forResource: file, withExtension: "json") else {
            print("找不到 \(file)")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let models = try JSONDecoder().decode([ModelInfo].self, from: data)
            return models
        } catch {
            print("解析失敗：\(error)")
            return []
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 背景做一個有層次的漸層，凸顯玻璃材質
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.35),
                    Color.purple.opacity(0.35),
                    Color.black.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView {

                // TTS model tab
                NavigationStack {
                    ScrollView {
                        ForEach(tts_infos, id: \.self) { tts_info in
                            NavigationLink {
                                model_detail(Modelinfo: tts_info)
                            } label: {
                                Model_name_View(Modelinfo: tts_info)
                            }
                            
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background() {
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.35),
                                Color.purple.opacity(0.35),
                                Color.black.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                    }

                }
                .tabItem {
                    Label("TTS model", systemImage: "waveform")
                }

                // OCR model tab
                NavigationStack {
                    ScrollView {
                        ForEach(ocr_infos, id: \.self) { ocr_info in
                            NavigationLink{
                                model_detail(Modelinfo: ocr_info)

                            } label: {
                                Model_name_View(Modelinfo: ocr_info)

                            }
                            
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background() {
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.35),
                                Color.purple.opacity(0.35),
                                Color.black.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                    }

                }
                .tabItem {
                    Label("OCR model", systemImage: "viewfinder.circle.fill")
                }

                // Chating model tab
                NavigationStack {
                    ScrollView {
                        ForEach(chat_infos, id: \.self) { chat_info in
                            NavigationLink{
                                model_detail(Modelinfo: chat_info)
                            } label: {
                                Model_name_View(Modelinfo: chat_info)

                            }
                            
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background() {
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.35),
                                Color.purple.opacity(0.35),
                                Color.black.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                    }
                }
                .tabItem {
                    Label("Chat model", systemImage: "bubble.left.and.text.bubble.right.fill")
                }
            }
            
            // Spinning gear on the initial (root) page
            Image(systemName: "gearshape")
                .imageScale(.large)
                .foregroundStyle(.secondary)
                .padding(16)
                .rotationEffect(.degrees(isRootSpinning ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isRootSpinning)
                .onAppear { isRootSpinning = true }
                .allowsHitTesting(false) // 不擋住底下的操作
                .accessibilityLabel("Loading")
        }
        .onAppear {
            tts_infos = loadNames(file: "TTSModels_info")
            chat_infos = loadNames(file: "ChatModels_info")
            ocr_infos = loadNames(file: "OCRModels_info")
        }
    }
}

#Preview("iPhone 16 Pro") {
    ContentView()
}

#Preview("iPad 13-inch") {
    ContentView()
}
