//
//  PendingRequestPage.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/19/25.
//

import SwiftUI

struct PendingRequestPage: View {
    let user: SearchUserResult
    let gender: String

    @State private var isCancelling = false
    @State private var navigateBackToPrivate = false
    private let hapticManager = HapticManager()

    var body: some View {
        ZStack {
            if navigateBackToPrivate {
                // Navigate back to private profile view
                PrivateProfileView(user: user)
                    .transition(.opacity)
            } else {
                mainContent
            }
        }
        .animation(.easeInOut(duration: 0.5), value: navigateBackToPrivate)
    }

    var mainContent: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green,
                    Color.blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .overlay(
                Image("GlitterBackground")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.3)
                    .ignoresSafeArea()
            )

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 100)

                // "you just requested dimple"
                HStack {
                    Spacer()
                    Text("you just requested \(user.name.lowercased())")
                        .font(.custom("DMSans-ExtraLight", size: 30))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 30)
                }

                Spacer()
                    .frame(height: 20)

                // "patience, babe. dimple's worth the wait"
                HStack {
                    Spacer()
                    Text(patienceText)
                        .font(.custom("DMSans-ExtraLight", size: 18))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.trailing)
                        .padding(.trailing, 30)
                }

                Spacer()

                // "Requested" button (bottom left) - tap to cancel
                HStack {
                    GlassButton(title: isCancelling ? "cancelling..." : "requested") {
                        cancelFollowRequest()
                    }
                    .opacity(isCancelling ? 0.3 : 0.5)
                    .disabled(isCancelling)
                    .padding(.leading, 30)

                    Spacer()
                }
                .padding(.bottom, 100)
            }
        }
    }

    private var patienceText: String {
        return "patience, babe. \(user.name.lowercased())'s worth the wait"
    }

    // MARK: - Cancel Follow Request
    private func cancelFollowRequest() {
        guard let currentUserID = UserDefaults.standard.string(forKey: "glow_user_id"),
              let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No user ID or access token found")
            return
        }

        isCancelling = true
        hapticManager.playDyingHaptic()

        print("🚫 Cancelling follow request to \(user.name)")
        NetworkManager.shared.cancelFollowRequest(
            requesterID: currentUserID,
            requestedID: user.user_id,
            accessToken: accessToken
        ) { response in
            DispatchQueue.main.async {
                isCancelling = false
                if let response = response, response.status == "success" {
                    print("✅ Follow request cancelled!")
                    // Navigate back to private profile view
                    navigateBackToPrivate = true
                } else {
                    print("❌ Failed to cancel follow request")
                }
            }
        }
    }
}

#Preview {
    PendingRequestPage(
        user: SearchUserResult(
            user_id: "user123",
            username: "dimple",
            name: "Dimple",
            university: nil,
            occupation: nil
        ),
        gender: "woman"
    )
}
