//
//  ProfileDisplayLogic.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/19/25.
//

import SwiftUI

struct ProfileDisplayLogic: View {
    let initialProfileResponse: ProfileResponse

    @StateObject private var designCycler: DesignCycler
    @State private var currentDesign: DesignItem?
    @State private var isLoading: Bool = false

    init(profileResponse: ProfileResponse) {
        self.initialProfileResponse = profileResponse

        // Initialize design cycler
        let accessToken = KeychainManager.shared.get(forKey: "access_token") ?? ""
        _designCycler = StateObject(wrappedValue: DesignCycler(
            userID: profileResponse.user.id,
            accessToken: accessToken
        ))
    }

    var body: some View {
        Group {
            if let design = currentDesign {
                // Route to appropriate view based on design_name
                switch design.design_name {
                case "GirlyGirlBold":
                    GirlyGirlBoldViewWrapper(
                        design: design,
                        onReload: handleReload
                    )
                default:
                    NoDesignView(user: initialProfileResponse.user)
                }
            } else if let initialDesign = initialProfileResponse.design {
                // Show initial design from ProfileResponse
                switch initialDesign.design_name {
                case "GirlyGirlBold":
                    GirlyGirlBoldViewWrapper(
                        design: convertToDesignItem(initialDesign),
                        onReload: handleReload
                    )
                default:
                    NoDesignView(user: initialProfileResponse.user)
                }
            } else {
                // No design available
                NoDesignView(user: initialProfileResponse.user)
            }
        }
    }

    // Handle reload button
    private func handleReload() {
        print("🔄 Reloading design...")
        isLoading = true

        designCycler.loadDesigns { success in
            guard success else {
                isLoading = false
                return
            }

            // Update current design
            currentDesign = designCycler.currentDesign
            isLoading = false
        }
    }

    // Convert ProfileDesign to DesignItem
    private func convertToDesignItem(_ profileDesign: ProfileDesign) -> DesignItem {
        return DesignItem(
            id: profileDesign.id,
            two_captions: profileDesign.two_captions,
            intro_caption: profileDesign.intro_caption,
            eight_captions: profileDesign.eight_captions,
            design_name: profileDesign.design_name,
            song: profileDesign.song,
            created_at: profileDesign.created_at
        )
    }
}

// MARK: - GirlyGirlBold Wrapper
struct GirlyGirlBoldViewWrapper: View {
    let design: DesignItem
    let onReload: () -> Void

    var body: some View {
        GirlyGirlBoldDisplayView(design: design, onReload: onReload)
    }
}

// MARK: - No Design View
struct NoDesignView: View {
    let user: ProfileUser

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.purple.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("no design available")
                    .font(.custom("DMSans-ExtraLight", size: 28))
                    .foregroundColor(.white)

                Text(user.name)
                    .font(.custom("LeagueScript-Regular", size: 50))
                    .foregroundColor(.white)

                Text("@\(user.username)")
                    .font(.custom("DMSans-ExtraLight", size: 20))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
