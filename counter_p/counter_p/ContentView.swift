import SwiftUI

enum AppTheme: String, CaseIterable {
    case original = "Orijinal"
    case red = "Kırmızı"
    case pink = "Pembe"
    case puce = "Mor"
}

struct ContentView: View {
    @State private var elapsedTime: Double = 0.00
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var selectedTheme: AppTheme = .original
    @State private var ringRotate = false
    @State private var heartPulse = false
    @State private var showSettings = false
    
    // Ayar Değerleri
    @AppStorage("isCountdownMode") private var isCountdownMode = false
    @AppStorage("countdownStartTime") private var countdownStartTime = 60
    @AppStorage("autoStart") private var autoStart = false
    @AppStorage("enableAnimations") private var enableAnimations = true
    @AppStorage("nightMode") private var nightMode = false
    @AppStorage("selectedFont") private var selectedFont = "Monospaced"
    @AppStorage("enableNotifications") private var enableNotifications = false
    @AppStorage("notificationTime") private var notificationTime = 5
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack {
                    // Üst Bar
                    HStack {
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(foregroundColor)
                                .padding(14)
                                .background(foregroundColor.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .navigationDestination(isPresented: $showSettings) {
                            SettingsView(selectedTheme: $selectedTheme) {
                                showSettings = false
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Sayaç Görseli
                    ZStack {
                        if enableAnimations {
                            if selectedTheme == .original || selectedTheme == .red {
                                Circle()
                                    .trim(from: 0, to: 1)
                                    .stroke(
                                        strokeColor,
                                        style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [CGFloat(12), CGFloat(8)])
                                    )
                                    .frame(width: 220, height: 220)
                                    .rotationEffect(.degrees(ringRotate ? 360 : 0))
                                    .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: ringRotate)
                                    .onAppear { ringRotate = true }
                            } else if selectedTheme == .pink {
                                Image(systemName: "heart.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .foregroundColor(.white.opacity(0.8))
                                    .scaleEffect(heartPulse ? 1.1 : 0.9)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: heartPulse)
                                    .onAppear { heartPulse = true }
                            }
                        }
                        
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 52, weight: .bold, design: fontDesign))
                            .foregroundColor(foregroundColor)
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 1, y: 1)
                    }
                    
                    Spacer()
                    
                    // Butonlar
                    if selectedTheme == .red {
                        HStack(spacing: 16) {
                            startStopButton
                            resetButton
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 12) {
                            startStopButton
                            if !isRunning && elapsedTime > 0 {
                                resetButton
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .onAppear {
                if isCountdownMode {
                    elapsedTime = Double(countdownStartTime)
                    if autoStart { startTimer() }
                }
            }
        }
    }
    
    // MARK: - Tema Renkleri
    var backgroundColor: Color {
        if nightMode { return Color.black }
        switch selectedTheme {
        case .original: return Color(UIColor.systemBackground)
        case .red: return Color.red
        case .pink: return Color.pink
        case .puce: return Color.purple
        }
    }
    
    var foregroundColor: Color {
        switch selectedTheme {
        case .original: return Color.primary
        default: return Color.white
        }
    }
    
    var strokeColor: Color {
        switch selectedTheme {
        case .original: return Color.yellow.opacity(0.8)
        default: return Color.white.opacity(0.9)
        }
    }
    
    var fontDesign: Font.Design {
        switch selectedFont {
        case "Rounded": return .rounded
        case "Serif": return .serif
        case "Sans-serif": return .default
        default: return .monospaced
        }
    }
    
    var startButtonColor: Color {
        switch selectedTheme {
        case .original: return Color.yellow
        case .red: return Color.green.opacity(0.85)
        case .pink: return Color.white.opacity(0.85)
        case .puce: return Color.black.opacity(0.85)
        }
    }
    
    var resetButtonColor: Color {
        switch selectedTheme {
        case .original: return Color.red
        case .red: return Color.white
        case .pink: return Color.black.opacity(0.9)
        case .puce: return Color.white.opacity(0.3)
        }
    }
    
    var resetButtonTextColor: Color {
        switch selectedTheme {
        case .red: return Color.red
        default: return Color.white
        }
    }
    
    // MARK: - Butonlar
    var startStopButton: some View {
        Button(action: {
            if isRunning { stopTimer() } else { startTimer() }
        }) {
            Text(isRunning ? "Durdur" : "Başlat")
                .foregroundColor(isRunning ? startButtonColor : .white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(isRunning ? foregroundColor : startButtonColor)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
        }
    }
    
    var resetButton: some View {
        Button(action: {
            elapsedTime = isCountdownMode ? Double(countdownStartTime) : 0.0
        }) {
            Text("Sıfırla")
                .foregroundColor(resetButtonTextColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(resetButtonColor)
                .cornerRadius(25)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
        }
    }
    
    // MARK: - Sayaç Formatı
    func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time - floor(time)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, centiseconds)
    }
    
    // MARK: - Timer Fonksiyonları
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if isCountdownMode {
                if elapsedTime > 0 {
                    elapsedTime -= 0.01
                } else {
                    stopTimer()
                    if enableNotifications {
                        // Bildirim gönderme (gerçek cihazda)
                        print("Süre bitti! Bildirim gönderilecek.")
                    }
                }
            } else {
                elapsedTime += 0.01
            }
        }
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Ayarlar Ekranı
struct SettingsView: View {
    @Binding var selectedTheme: AppTheme
    var onThemeSelected: (() -> Void)? = nil
    
    @AppStorage("isCountdownMode") private var isCountdownMode = false
    @AppStorage("countdownStartTime") private var countdownStartTime = 60
    @AppStorage("autoStart") private var autoStart = false
    @AppStorage("enableAnimations") private var enableAnimations = true
    @AppStorage("nightMode") private var nightMode = false
    @AppStorage("selectedFont") private var selectedFont = "Monospaced"
    @AppStorage("enableNotifications") private var enableNotifications = false
    @AppStorage("notificationTime") private var notificationTime = 5
    
    var fonts = ["Monospaced", "Rounded", "Serif", "Sans-serif"]
    
    var body: some View {
        List {
            // Tema
            Section(header: Text("Tema Seç")) {
                ForEach(AppTheme.allCases, id: \.self) { theme in
                    Button {
                        selectedTheme = theme
                        onThemeSelected?()
                    } label: {
                        HStack {
                            Text(theme.rawValue)
                            if selectedTheme == theme {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .foregroundColor(selectedTheme == theme ? .accentColor : .primary)
                }
                Picker("Yazı Tipi", selection: $selectedFont) {
                    ForEach(fonts, id: \.self) { font in
                        Text(font)
                    }
                }
            }
            
            // Sayaç
            Section(header: Text("Sayaç")) {
                Toggle("Geri Sayım Modu", isOn: $isCountdownMode)
                if isCountdownMode {
                    Stepper("Başlangıç Süresi: \(countdownStartTime) sn", value: $countdownStartTime, in: 5...600, step: 5)
                }
                Toggle("Otomatik Başlat", isOn: $autoStart)
            }
            
            // Görünüm
            Section(header: Text("Görünüm")) {
                Toggle("Animasyonları Aç", isOn: $enableAnimations)
            }
            
            // Bildirimler
            Section(header: Text("Bildirimler")) {
                Toggle("Süre Bittiğinde Uyar", isOn: $enableNotifications)
                if enableNotifications {
                    Stepper("Uyarı Süresi: \(notificationTime) sn", value: $notificationTime, in: 1...60)
                }
            }
            
            // Hakkında
            Section(header: Text("Hakkında")) {
                HStack {
                    Text("Sürüm")
                    Spacer()
                    Text("v1.0.0").foregroundColor(.secondary)
                }
                Link("Geri Bildirim Gönder", destination: URL(string: "mailto:destek@idemir.com")!)
                Link("Destek Ol", destination: URL(string: "https://www.buymeacoffee.com/idemir")!)
            }
            
            // İmza
            Section {
                HStack {
                    Spacer()
                    Text("Developer by iDemir")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .navigationTitle("Ayarlar")
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
