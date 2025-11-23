//
//  GirlyGirlBoldDisplayView.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/19/25.
//

import SwiftUI
import AVFoundation

struct GirlyGirlBoldDisplayView: View {
    let design: DesignItem
    let onReload: () -> Void

    private let hapticManager = HapticManager()
    @State private var audioPlayer: AVAudioPlayer?
    @State private var captions: [CaptionItem] = []
    @State private var revealedCaptions: Set<Int> = []
    @State private var currentlyTypingIndex: Int? = nil
    @State private var isAtBottom: Bool = false

    @State private var hasRequestedNotifications = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(
                Image("GlitterBackground")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.85)
                    .ignoresSafeArea()
            )

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(captions.enumerated()), id: \.offset) { index, captionItem in
                        CaptionItemView(
                            caption: captionItem,
                            index: index,
                            isRevealed: revealedCaptions.contains(index)
                        )
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        checkAndRevealCaption(index: index, midY: geo.frame(in: .global).midY)
                                    }
                                    .onChange(of: geo.frame(in: .global).midY) { oldValue, newValue in
                                        checkAndRevealCaption(index: index, midY: newValue)
                                    }
                            }
                        )

                        // Add spacing after each caption
                        if index < captions.count - 1 {
                            Spacer()
                                .frame(height: {
                                    if index == 0 { return 0 }
                                    else if index == 1 { return 100 }
                                    else if index == 2 { return 120 }
                                    else if index < 7 { return 90 }
                                    else { return 35 }
                                }())
                        }
                    }

                    // Reload button at the bottom
                    Spacer()
                        .frame(height: 80)

                    GlassButton(title: "reload profile") {
                        reloadProfile()
                    }
                    .opacity(isAtBottom ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5), value: isAtBottom)
                    .padding(.bottom, 120)

                    // Detector for reaching bottom
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ViewOffsetKey.self, value: geo.frame(in: .global).minY)
                    }
                    .frame(height: 1)
                }
                .padding(.top, 100)
            }
            .scrollIndicators(.hidden)
            .onPreferenceChange(ViewOffsetKey.self) { value in
                let screenHeight = UIScreen.main.bounds.height
                if value > 0 && value < screenHeight {
                    isAtBottom = true
                } else {
                    isAtBottom = false
                }
            }
        }
        .onAppear {
            buildCaptionsFromDesign()
            playSong()
            requestNotificationPermissionIfNeeded()
        }
        .onDisappear {
            audioPlayer?.stop()
            audioPlayer = nil
        }
    }

    // MARK: - Build Captions
    private func buildCaptionsFromDesign() {
        var newCaptions: [CaptionItem] = []

        // Parse introduction - last word becomes the name
        let introText = design.intro_caption
        let words = introText.components(separatedBy: " ")
        if let name = words.last {
            let introLine = words.dropLast().joined(separator: " ")
            newCaptions.append(CaptionItem(text: introLine, fontSize: 15, alignment: .trailing, revealPercentage: 0.0, fontName: "DMSans-ExtraLight", imageName: nil))
            newCaptions.append(CaptionItem(text: name, fontSize: 70, alignment: .trailing, revealPercentage: 0.05, fontName: "LeagueScript", imageName: nil))
        }

        // Add first bold caption
        if design.two_captions.count > 0 {
            newCaptions.append(CaptionItem(text: design.two_captions[0], fontSize: 50, alignment: .leading, revealPercentage: 0.1, fontName: "DMSans-ExtraLight", imageName: nil))
        }

        // Add first 4 captions
        for i in 0..<min(4, design.eight_captions.count) {
            let alignment: Alignment = (i % 2 == 0) ? .trailing : .leading
            newCaptions.append(CaptionItem(text: design.eight_captions[i], fontSize: 20, alignment: alignment, revealPercentage: 0.2 + Double(i) * 0.1, fontName: "DMSans-ExtraLight", imageName: nil))
        }

        // Add second bold caption
        if design.two_captions.count > 1 {
            newCaptions.append(CaptionItem(text: design.two_captions[1], fontSize: 46, alignment: .center, revealPercentage: 0.6, fontName: "DMSans-ExtraLight", imageName: nil))
        }

        // Add remaining 4 captions
        if design.eight_captions.count > 4 {
            for i in 4..<min(8, design.eight_captions.count) {
                let alignment: Alignment = (i % 2 == 0) ? .trailing : .leading
                newCaptions.append(CaptionItem(text: design.eight_captions[i], fontSize: 20, alignment: alignment, revealPercentage: 0.7 + Double(i - 4) * 0.1, fontName: "DMSans-ExtraLight", imageName: nil))
            }
        }

        captions = newCaptions
        print("✅ Built \(newCaptions.count) captions for \(design.design_name)")
    }

    // MARK: - Play Song
    private func playSong() {
        let audioFileName: String
        switch design.song {
        case "Future - Low Life (Lyrics) ft. The Weeknd", "Low Life":
            audioFileName = "Future - Low Life (Lyrics) ft. The Weeknd"
        default:
            audioFileName = design.song
        }

        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") else {
            print("❌ Audio file not found: \(audioFileName).mp3")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.8
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("✅ Playing: \(audioFileName)")
        } catch {
            print("❌ Error playing audio: \(error.localizedDescription)")
        }
    }

    // MARK: - Reload Profile
    private func reloadProfile() {
        hapticManager.playDyingHaptic()

        // Stop music
        audioPlayer?.stop()
        audioPlayer = nil

        // Reset state
        revealedCaptions.removeAll()
        currentlyTypingIndex = nil

        // Call reload handler
        onReload()
    }

    // MARK: - Request Notification Permission
    private func requestNotificationPermissionIfNeeded() {
        // Only request once per session
        guard !hasRequestedNotifications else { return }

        NotificationManager.shared.shouldRequestPermission { shouldRequest in
            if shouldRequest {
                // Small delay so user sees their profile first
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    NotificationManager.shared.requestPermission { granted in
                        if granted {
                            print("✅ Notification permission granted")
                        }
                    }
                }
            }
        }

        hasRequestedNotifications = true
    }

    // MARK: - Caption Reveal Logic
    private func checkAndRevealCaption(index: Int, midY: CGFloat) {
        let screenHeight = UIScreen.main.bounds.height

        if midY > 0 && midY < screenHeight && !revealedCaptions.contains(index) {
            if currentlyTypingIndex == nil {
                if index == 0 || revealedCaptions.contains(index - 1) {
                    revealCaption(at: index)
                }
            }
        }
    }

    private func revealCaption(at index: Int) {
        guard !revealedCaptions.contains(index) else { return }
        guard currentlyTypingIndex == nil else { return }

        currentlyTypingIndex = index
        revealedCaptions.insert(index)

        hapticManager.playDyingHaptic()

        let caption = captions[index]
        let typingDuration = Double(caption.text.count) * 0.06 + 0.5

        DispatchQueue.main.asyncAfter(deadline: .now() + typingDuration) {
            currentlyTypingIndex = nil
        }
    }
}
