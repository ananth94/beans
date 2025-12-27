import SwiftUI
import WebKit
import SwiftData

struct ReaderView: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("readerTheme") private var themeRawValue: String = "sepia"
    @AppStorage("readerFont") private var fontRawValue: String = "georgia"
    @State private var fontSize: CGFloat = 18
    @State private var showCelebration = false
    @State private var celebrationType: CelebrationType = .longArticle
    @State private var showFavoriteBurst = false
    @State private var showChrome = true
    @State private var tappedHighlight: Highlight?
    @State private var showHighlightActions = false
    @State private var showShareSheet = false
    @State private var shareText = ""
    
    private var theme: ReaderTheme {
        get { ReaderTheme(rawValue: themeRawValue) ?? .sepia }
    }
    
    private var readerFont: ReaderFont {
        get { ReaderFont(rawValue: fontRawValue) ?? .georgia }
    }
    
    enum ReaderFont: String, CaseIterable {
        case georgia, system, palatino
        
        var fontName: String {
            switch self {
            case .georgia: return "Georgia"
            case .system: return "-apple-system-font"
            case .palatino: return "Palatino"
            }
        }
        
        var displayName: String {
            switch self {
            case .georgia: return "Georgia"
            case .system: return "System"
            case .palatino: return "Palatino"
            }
        }
    }
    
    enum ReaderTheme: String, CaseIterable {
        case light, sepia, dark, midnight
        
        var backgroundColor: Color {
            switch self {
            case .light: return Color(white: 0.98)
            case .sepia: return Color(red: 0.96, green: 0.92, blue: 0.85)
            case .dark: return Color(red: 0.1, green: 0.08, blue: 0.05)
            case .midnight: return .black
            }
        }
        
        var textColor: Color {
            switch self {
            case .light: return .black
            case .sepia: return Color(red: 0.25, green: 0.15, blue: 0.05)
            case .dark: return Color(red: 0.9, green: 0.85, blue: 0.75)
            case .midnight: return Color(white: 0.7)
            }
        }
        
        var uiColor: UIColor {
            UIColor(backgroundColor)
        }
        
        var textUIColor: UIColor {
            UIColor(textColor)
        }
    }
    
    var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: theme)
            
            VStack(spacing: 0) {
                ReaderWebView(
                    html: article.content, 
                    title: article.title, 
                    author: article.author,
                    theme: theme,
                    font: readerFont,
                    fontSize: fontSize,
                    highlights: article.highlights,
                    initialProgress: article.readingProgress,
                    onProgressChange: { progress in
                        article.readingProgress = progress
                        
                        // Mark as In-Progress at 10%+
                        if progress >= 0.1 && article.status == .toRead {
                            article.status = .inProgress
                            try? modelContext.save()
                        }
                        
                        // Auto-complete at 90%
                        if progress >= 0.9 && article.status != .read {
                            article.status = .read
                            try? modelContext.save()
                            
                            // Check for milestone
                            if let milestone = MilestoneService.shared.articleRead(readingTimeMinutes: article.readingTimeMinutes) {
                                celebrationType = milestone
                                showCelebration = true
                            }
                        }
                    },
                    onScrollDirectionChange: { isScrollingUp in
                        withAnimation {
                            showChrome = isScrollingUp
                        }
                    },
                    onHighlight: { selectedText in
                        // Save highlight to article
                        let highlight = Highlight(text: selectedText, article: article)
                        article.highlights.append(highlight)
                        try? modelContext.save()
                        
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    },
                    onHighlightTap: { highlightId in
                        // Find the highlight and show action sheet
                        if let highlight = article.highlights.first(where: { $0.highlightId.uuidString == highlightId }) {
                            tappedHighlight = highlight
                            showHighlightActions = true
                        }
                    }
                )
                .edgesIgnoringSafeArea(.bottom)
            }
            
            // Progress Bar & Time Remaining Overlay
            VStack {
                // Progress Bar
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.orange)
                        .frame(width: geo.size.width * article.readingProgress, height: 4)
                        .opacity(article.readingProgress > 0 ? 1 : 0)
                }
                .frame(height: 4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.1))
                
                // Time Remaining Pill
                if article.readingProgress < 0.9 && article.readingProgress > 0 {
                    HStack {
                        Spacer()
                        Text("\(max(1, Int((1 - article.readingProgress) * Double(article.readingTimeMinutes)))) min left")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(.trailing, 16)
                            .padding(.top, 8)
                    }
                    .transition(.opacity)
                }
                
                Spacer()
            }
            
            if showCelebration {
                CelebrationView(type: celebrationType, isPresented: $showCelebration)
            }
            
            if showFavoriteBurst {
                FavoriteStarBurst()
            }
            if showFavoriteBurst {
                FavoriteStarBurst()
            }
        }
        .toolbar(showChrome ? .visible : .hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: showChrome)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Theme", selection: Binding(
                        get: { theme },
                        set: { themeRawValue = $0.rawValue }
                    )) {
                        ForEach(ReaderTheme.allCases, id: \.self) { t in
                            Text(t.rawValue.capitalized).tag(t)
                        }
                    }
                    
                    Picker("Font", selection: Binding(
                        get: { readerFont },
                        set: { fontRawValue = $0.rawValue }
                    )) {
                        ForEach(ReaderFont.allCases, id: \.self) { f in
                            Text(f.displayName).tag(f)
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        fontSize += 2
                    } label: {
                        Label("Increase Font", systemImage: "plus")
                    }
                    
                    Button {
                        fontSize = max(12, fontSize - 2)
                    } label: {
                        Label("Decrease Font", systemImage: "minus")
                    }
                    
                    Divider()
                    
                    Button {
                        article.status = .read
                        article.lastReadDate = Date()
                        article.readingProgress = 1.0
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Label("Mark as Read", systemImage: "checkmark.circle")
                    }
                    
                    Button {
                        let wasFavorite = article.isFavorite
                        article.isFavorite.toggle()
                        try? modelContext.save()
                        
                        // Trigger star burst animation when adding to favorites
                        if !wasFavorite {
                            showFavoriteBurst = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                showFavoriteBurst = false
                            }
                        }
                    } label: {
                        Label(article.isFavorite ? "Unfavorite" : "Favorite", 
                              systemImage: article.isFavorite ? "star.slash" : "star.fill")
                    }
                } label: {
                    Image(systemName: "textformat.size")
                        .foregroundColor(theme.textColor)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                ShareLink(item: URL(string: article.originalURL) ?? URL(string: article.url)!) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(theme.textColor)
                }
            }
        }
        .onAppear {
            article.lastReadDate = Date()
            try? modelContext.save()
        }
        .confirmationDialog(
            "Highlight",
            isPresented: $showHighlightActions,
            presenting: tappedHighlight
        ) { highlight in
            Button("Share Quote") {
                shareText = "\"\(highlight.text)\"\n\n— \(article.title)\n\(article.originalURL)"
                showShareSheet = true
            }
            Button("Remove Highlight", role: .destructive) {
                if let index = article.highlights.firstIndex(where: { $0.highlightId == highlight.highlightId }) {
                    article.highlights.remove(at: index)
                    modelContext.delete(highlight)
                    try? modelContext.save()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { highlight in
            Text(String(highlight.text.prefix(100)) + (highlight.text.count > 100 ? "..." : ""))
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: shareText)
        }
    }
}

struct ReaderWebView: UIViewRepresentable {
    let html: String
    let title: String
    let author: String?
    let theme: ReaderView.ReaderTheme
    let font: ReaderView.ReaderFont
    let fontSize: CGFloat
    var highlights: [Highlight] = []
    var initialProgress: Double = 0
    var onProgressChange: ((Double) -> Void)?
    var onScrollDirectionChange: ((Bool) -> Void)?
    var onHighlight: ((String) -> Void)?
    var onHighlightTap: ((String) -> Void)? // Callback with highlight ID
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onProgressChange: onProgressChange, onScrollDirectionChange: onScrollDirectionChange, onHighlight: onHighlight, onHighlightTap: onHighlightTap, initialProgress: initialProgress)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Add message handlers for highlights
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "highlightHandler")
        contentController.add(context.coordinator, name: "highlightTapHandler")
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.delegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        
        // Load content once in makeUIView
        let styledHtml = generateStyledHTML()
        context.coordinator.loadedContentHash = styledHtml.hashValue
        webView.loadHTMLString(styledHtml, baseURL: nil)
        
        return webView
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate, WKNavigationDelegate, WKScriptMessageHandler {
        var onProgressChange: ((Double) -> Void)?
        var onScrollDirectionChange: ((Bool) -> Void)?
        var onHighlight: ((String) -> Void)?
        var onHighlightTap: ((String) -> Void)?
        var initialProgress: Double
        weak var webView: WKWebView?
        var hasRestoredScroll = false
        var loadedContentHash: Int = 0
        var lastOffset: CGFloat = 0
        var pendingScrollRestore: CGFloat? = nil
        
        init(onProgressChange: ((Double) -> Void)?, onScrollDirectionChange: ((Bool) -> Void)?, onHighlight: ((String) -> Void)?, onHighlightTap: ((String) -> Void)?, initialProgress: Double) {
            self.onProgressChange = onProgressChange
            self.onScrollDirectionChange = onScrollDirectionChange
            self.onHighlight = onHighlight
            self.onHighlightTap = onHighlightTap
            self.initialProgress = initialProgress
        }
        
        // WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "highlightHandler", let text = message.body as? String {
                onHighlight?(text)
            } else if message.name == "highlightTapHandler", let highlightId = message.body as? String {
                onHighlightTap?(highlightId)
            }
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let currentOffset = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height - scrollView.bounds.height
            
            // Progress Logic
            guard contentHeight > 0 else { return }
            let progress = min(1, max(0, currentOffset / contentHeight))
            onProgressChange?(progress)
            
            // Scroll Direction Logic (Hysteresis)
            let diff = currentOffset - lastOffset
            if abs(diff) > 10 {
                // If scrolling down (diff > 0), hide chrome (false)
                // If scrolling up (diff < 0), show chrome (true)
                // Exception: Always show at top
                if currentOffset < 50 {
                     onScrollDirectionChange?(true)
                } else {
                     onScrollDirectionChange?(diff < 0)
                }
                lastOffset = currentOffset
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Priority 1: Restore after style change (pendingScrollRestore)
            if let pending = pendingScrollRestore {
                pendingScrollRestore = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    webView.scrollView.setContentOffset(CGPoint(x: 0, y: pending), animated: false)
                }
                return
            }
            
            // Priority 2: Restore initial progress on first load
            guard !hasRestoredScroll, initialProgress > 0.05 else { return }
            hasRestoredScroll = true
            
            // Wait a moment for content to render, then restore scroll position
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else { return }
                let scrollView = webView.scrollView
                let contentHeight = scrollView.contentSize.height - scrollView.bounds.height
                guard contentHeight > 0 else { return }
                
                let targetOffset = CGFloat(self.initialProgress) * contentHeight
                scrollView.setContentOffset(CGPoint(x: 0, y: targetOffset), animated: false)
            }
        }
    }
    
    private func generateStyledHTML() -> String {
        let css = """
        body {
            font-family: '\(font.fontName)', 'Georgia', serif;
            font-size: \(fontSize)px;
            color: \(theme.textColor.hexString);
            background-color: transparent;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
        }
        h1 {
            font-size: 1.8em;
            line-height: 1.2;
            margin-bottom: 0.2em;
            color: \(theme.textColor.hexString);
        }
        .author {
            color: \(theme.textColor.opacity(0.6).hexString);
            font-size: 0.9em;
            margin-bottom: 2em;
            font-style: italic;
        }
        img { 
            max-width: 100%; 
            height: auto; 
            border-radius: 12px; 
            margin: 1.5em 0;
        }
        p { margin-bottom: 1.2em; }
        hr { 
            border: 0; 
            border-top: 1px solid \(theme.textColor.opacity(0.1).hexString); 
            margin: 2em 0; 
        }
        .beans-highlight {
            background-color: rgba(255, 200, 50, 0.4);
            border-radius: 3px;
            padding: 1px 2px;
        }
        #highlight-btn {
            display: none;
            position: fixed;
            background: linear-gradient(135deg, #D4A574, #C19660);
            color: #1A1512;
            border: none;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: bold;
            font-family: -apple-system, sans-serif;
            box-shadow: 0 4px 12px rgba(0,0,0,0.4);
            z-index: 9999;
            cursor: pointer;
        }
        """
        
        let highlightJS = """
        <script>
        var highlightBtn = document.createElement('button');
        highlightBtn.id = 'highlight-btn';
        highlightBtn.innerHTML = '✨ Highlight';
        document.body.appendChild(highlightBtn);
        
        var selectedText = '';
        
        document.addEventListener('selectionchange', function() {
            try {
                var selection = document.getSelection();
                selectedText = selection.toString().trim();
                
                if (selectedText.length > 0 && selection.rangeCount > 0) {
                    var range = selection.getRangeAt(0);
                    var rect = range.getBoundingClientRect();
                    
                    // Position ABOVE the selection (primary)
                    var btnLeft = Math.max(10, Math.min(rect.left + rect.width / 2 - 60, window.innerWidth - 130));
                    var btnTop = rect.top - 50;
                    
                    // If too close to top, position below instead
                    if (btnTop < 60) {
                        btnTop = rect.bottom + 10;
                    }
                    
                    highlightBtn.style.display = 'block';
                    highlightBtn.style.left = btnLeft + 'px';
                    highlightBtn.style.top = btnTop + 'px';
                } else {
                    highlightBtn.style.display = 'none';
                }
            } catch(e) {
                console.log('Highlight error:', e);
            }
        });
        
        highlightBtn.addEventListener('touchend', function(e) {
            e.preventDefault();
            e.stopPropagation();
            if (selectedText.length > 0 && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.highlightHandler) {
                window.webkit.messageHandlers.highlightHandler.postMessage(selectedText);
                highlightBtn.style.display = 'none';
                window.getSelection().removeAllRanges();
            }
        });
        
        // Hide button when selection is cleared
        document.addEventListener('touchend', function(e) {
            if (e.target.id !== 'highlight-btn') {
                setTimeout(function() {
                    var sel = document.getSelection();
                    if (!sel || sel.toString().trim().length === 0) {
                        highlightBtn.style.display = 'none';
                    }
                }, 300);
            }
        });
        </script>
        """
        
        let headerHtml = """
        <h1>\(title)</h1>
        \(author != nil ? "<div class='author'>By \(author!)</div>" : "")
        <hr>
        """
        
        // Process HTML to wrap saved highlights
        var processedHtml = html
        for highlight in highlights {
            let escapedText = highlight.text
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let highlightSpan = "<span class='beans-highlight' data-highlight-id='\(highlight.highlightId.uuidString)'>\(escapedText)</span>"
            // Replace first occurrence only
            if let range = processedHtml.range(of: highlight.text) {
                processedHtml = processedHtml.replacingCharacters(in: range, with: highlightSpan)
            }
        }
        
        // Add JS for tapping existing highlights
        let highlightTapJS = """
        <script>
        document.addEventListener('click', function(e) {
            var target = e.target;
            if (target.classList.contains('beans-highlight')) {
                var highlightId = target.getAttribute('data-highlight-id');
                if (highlightId && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.highlightTapHandler) {
                    window.webkit.messageHandlers.highlightTapHandler.postMessage(highlightId);
                }
            }
        });
        </script>
        """
        
        return """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>\(css)</style>
        </head>
        <body>
            \(headerHtml)
            \(processedHtml)
            \(highlightJS)
            \(highlightTapJS)
        </body>
        </html>
        """
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update callback to avoid stale closures
        context.coordinator.onProgressChange = onProgressChange
        context.coordinator.onScrollDirectionChange = onScrollDirectionChange
        context.coordinator.onHighlight = onHighlight
        context.coordinator.onHighlightTap = onHighlightTap
        
        // Only reload if content has actually changed (e.g., theme/font change)
        let newHash = generateStyledHTML().hashValue
        if newHash != context.coordinator.loadedContentHash {
            // Capture current scroll position before reload
            context.coordinator.pendingScrollRestore = uiView.scrollView.contentOffset.y
            
            context.coordinator.loadedContentHash = newHash
            uiView.loadHTMLString(generateStyledHTML(), baseURL: nil)
        }
    }
}

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        // Ensure we are in a space that has RGB components
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Fallback for non-RGB colors (like white/black)
            if let components = uiColor.cgColor.components, components.count >= 2 {
                r = components[0]
                g = components[0]
                b = components[0]
            }
            return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
        }
        
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(r) * 255), lroundf(Float(g) * 255), lroundf(Float(b) * 255))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let text: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
