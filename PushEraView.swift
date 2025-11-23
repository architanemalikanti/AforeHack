//
//  PushEraView.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/18/25.
//

import SwiftUI

struct PushEraView: View {
    @State private var eraText: String = ""
    @State private var isLoading: Bool = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue,
                    Color.purple
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

            VStack(spacing: 40) {
                // Title
                Text("archita, tell everyone about ur life")
                    .font(.custom("DMSans-ExtraLight", size: 50))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 60)

                Spacer()

                // Liquid glass rectangle with era text
                GlassContainer {
                    VStack(spacing: 30) {
                        // Scrollable text area
                        ScrollView {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                            } else {
                                Text(eraText.isEmpty ? "catching ur vibe..." : eraText)
                                    .font(.custom("DMSans-ExtraLight", size: 30))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 10)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(maxHeight: 250)
                        .scrollIndicators(.hidden)

                        // Buttons
                        HStack(spacing: 10) {
                            // Push This Era Button
                            GlassButton(
                                title: "push this era",
                                action: pushEra,
                                fontSize: 14,
                                horizontalPadding: 16,
                                verticalPadding: 10
                            )

                            // Regenerate Era Button
                            GlassButton(
                                title: "regenerate era",
                                action: regenerateEra,
                                fontSize: 14,
                                horizontalPadding: 16,
                                verticalPadding: 10
                            )
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.5 : 1.0)
                        }
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
        .onAppear {
            fetchCurrentEra()
        }
    }

    private func fetchCurrentEra() {
        isLoading = true

        guard let userID = UserDefaults.standard.string(forKey: "glow_user_id"),
              let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No user ID or access token found")
            isLoading = false
            eraText = "couldn't catch your era, bestie."
            return
        }

        NetworkManager.shared.getCurrentEra(userID: userID, accessToken: accessToken) { response in
            DispatchQueue.main.async {
                isLoading = false
                if let response = response, let era = response.era {
                    self.eraText = era
                } else {
                    self.eraText = "couldn't catch your era, bestie—it's giving mysterious main character energy though."
                }
            }
        }
    }

    private func regenerateEra() {
        fetchCurrentEra()
    }

    private func pushEra() {
        guard let userID = UserDefaults.standard.string(forKey: "glow_user_id"),
              let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No user ID or access token found")
            return
        }

        print("🚀 Pushing era: \(eraText)")

        NetworkManager.shared.pushEra(userID: userID, eraText: eraText, accessToken: accessToken) { response in
            DispatchQueue.main.async {
                if let response = response, response.status == "success" {
                    print("✅ Era pushed successfully!")
                    // Store the pushed era text for FeedView to display
                    UserDefaults.standard.set(self.eraText, forKey: "last_pushed_era")
                    // Navigate back to profile (which will show feed with the era)
                    NotificationCenter.default.post(name: NSNotification.Name("NavigateToFeed"), object: nil)
                } else {
                    print("❌ Failed to push era")
                }
            }
        }
    }
}

#Preview {
    PushEraView()
}
