//
//  PrivateProfileView.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/19/25.
//

import SwiftUI

struct PrivateProfileView: View {
    let user: SearchUserResult
    @Binding var navigateBack: Bool

    @State private var gender: String = ""
    @State private var navigateToPendingPage = false
    private let hapticManager = HapticManager()

    init(user: SearchUserResult, navigateBack: Binding<Bool> = .constant(false)) {
        self.user = user
        self._navigateBack = navigateBack
    }

    var body: some View {
        ZStack {
            if navigateToPendingPage {
                // Navigate to pending request page
                // Pass the main navigateBack binding so back button goes to explore/notifications
                PendingRequestPage(user: user, gender: gender, navigateBack: $navigateBack)
                    .transition(.opacity)
            } else {
                mainContent
            }
        }
        .animation(.easeInOut(duration: 0.5), value: navigateToPendingPage)
    }

    var mainContent: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.pink,
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
                    .opacity(0.8)
                    .ignoresSafeArea()
            )

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)

                // Right-aligned text: "dimple's profile is private"
                HStack {
                    Spacer()
                    Text("\(user.name.lowercased())'s profile is private")
                        .font(.custom("DMSans-ExtraLight", size: 30))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 30)
                }

                Spacer()
                    .frame(height: 20)

                // Smaller text based on gender
                HStack {
                    Spacer()
                    Text(genderText)
                        .font(.custom("DMSans-ExtraLight", size: 18))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 30)
                }

                Spacer()

                // Send follow request button (bottom left)
                VStack(spacing: 15) {
                    HStack {
                        GlassButton(title: "send follow request") {
                            sendFollowRequest()
                        }
                        .padding(.leading, 30)

                        Spacer()
                    }

                    // Back button
                    HStack {
                        GlassButton(title: "back") {
                            print("⬅️ Navigating back from private profile")
                            navigateBack = false
                        }
                        .padding(.leading, 30)

                        Spacer()
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            fetchGender()
        }
    }

    private var genderText: String {
        switch gender.lowercased() {
        case "woman", "female":
            return "not everyone gets access to her life"
        case "man", "male":
            return "not everyone gets access to his life"
        default:
            return "not everyone gets access to their life"
        }
    }

    // MARK: - Fetch Gender
    private func fetchGender() {
        guard let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No access token found")
            return
        }

        NetworkManager.shared.fetchUserGender(userID: user.user_id, accessToken: accessToken) { response in
            DispatchQueue.main.async {
                if let response = response, response.status == "success" {
                    self.gender = response.gender ?? ""
                    print("✅ Fetched gender: \(self.gender)")
                }
            }
        }
    }

    // MARK: - Send Follow Request
    private func sendFollowRequest() {
        guard let currentUserID = UserDefaults.standard.string(forKey: "glow_user_id"),
              let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No user ID or access token found")
            return
        }

        hapticManager.playDyingHaptic()

        print("📤 Sending follow request to \(user.name)")
        NetworkManager.shared.sendFollowRequest(
            requesterID: currentUserID,
            requestedID: user.user_id,
            accessToken: accessToken
        ) { response in
            DispatchQueue.main.async {
                if let response = response, response.status == "success" {
                    print("✅ Follow request sent!")
                    // Navigate to pending page
                    navigateToPendingPage = true
                } else {
                    print("❌ Failed to send follow request")
                }
            }
        }
    }
}

#Preview {
    PrivateProfileView(
        user: SearchUserResult(
            user_id: "user123",
            username: "sarah_j",
            name: "Sarah",
            university: "Stanford",
            occupation: "Law Student"
        )
    )
}
