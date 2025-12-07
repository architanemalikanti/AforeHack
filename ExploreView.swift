import SwiftUI

struct ExploreView: View {
    @Binding var dismissToVogueWelcome: Bool

    @State private var searchQuery = ""
    @State private var searchResults: [SearchUserResult] = []
    @State private var isSearching = false
    @State private var selectedUser: SearchUserResult? = nil
    @State private var navigateToOtherProfile = false
    @State private var navigateToPrivateProfile = false
    @State private var navigateToPendingRequest = false
    @State private var userGender: String = ""
    private let hapticManager = HapticManager()

    init(dismissToVogueWelcome: Binding<Bool> = .constant(false)) {
        self._dismissToVogueWelcome = dismissToVogueWelcome
    }

    var body: some View {
        ZStack {
            // Navigation destinations
            if navigateToOtherProfile, let user = selectedUser {
                // Someone else's profile (following) - show their posts
                UserProfileView(userID: user.user_id)
                    .transition(.opacity)
            } else if navigateToPrivateProfile, let user = selectedUser {
                // Private/locked profile - check for profile image first
                PrivateProfileHandler(
                    user: user,
                    viewerID: UserDefaults.standard.string(forKey: "glow_user_id") ?? "",
                    navigateBack: $navigateToPrivateProfile
                )
                .transition(.opacity)
            } else if navigateToPendingRequest, let user = selectedUser {
                // Pending request
                PendingRequestPage(user: user, gender: userGender, navigateBack: $navigateToPendingRequest)
                    .transition(.opacity)
            } else {
                mainContent
            }
        }
        .animation(.easeInOut(duration: 0.5), value: navigateToOtherProfile)
        .animation(.easeInOut(duration: 0.5), value: navigateToPrivateProfile)
        .animation(.easeInOut(duration: 0.5), value: navigateToPendingRequest)
    }

    var mainContent: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            // Glitter overlay
            Image("GlitterBackground")
                .resizable()
                .scaledToFill()
                .opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Title centered
                Text("find ur friends")
                    .font(.custom("DMSans-ExtraLight", size: 40))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                // Search bar right under title
                searchBar
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 16)

                // Search results right below search bar
                if isSearching {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                        .padding(.top, 30)
                } else if !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(searchResults, id: \.user_id) { user in
                                userResultCard(user: user)
                                    .frame(maxWidth: 400)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                } else if !searchQuery.isEmpty {
                    Text("no results found")
                        .font(.custom("DMSans-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 30)
                }

                Spacer()
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping anywhere
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Search Bar
    var searchBar: some View {
        ZStack(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 30)
                .fill(.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .strokeBorder(
                            LinearGradient(
                                colors: [],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .frame(height: 56)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)

            HStack {
                TextField("", text: $searchQuery, prompt: Text("find your friends")
                    .font(.custom("DMSans-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.5)))
                    .foregroundColor(.white)
                    .font(.custom("DMSans-Regular", size: 18))
                    .padding(.leading, 24)

                Button {
                    guard !searchQuery.isEmpty else { return }
                    hapticManager.playDyingHaptic()
                    performSearch()
                } label: {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.1))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1.5)
                            )
                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .padding(.trailing, 6)
            }
        }
    }

    // MARK: - User Result Card
    func userResultCard(user: SearchUserResult) -> some View {
        Button {
            handleUserTap(user: user)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Name (largest)
                Text(user.name.lowercased())
                    .font(.custom("DMSans-Regular", size: 24))
                    .foregroundColor(.white)

                // Username (smaller)
                Text(user.username.lowercased())
                    .font(.custom("DMSans-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.7))

                // University (if exists)
                if let university = user.university {
                    Text(university.lowercased())
                        .font(.custom("DMSans-Regular", size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Perform Search
    private func performSearch() {
        guard let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No access token found")
            return
        }

        isSearching = true
        searchResults = []

        NetworkManager.shared.searchUsers(query: searchQuery, accessToken: accessToken) { response in
            DispatchQueue.main.async {
                isSearching = false
                if let response = response {
                    searchResults = response.results
                    print("✅ Found \(response.count) users")
                } else {
                    print("❌ Search failed")
                }
            }
        }
    }

    // MARK: - Handle User Tap
    private func handleUserTap(user: SearchUserResult) {
        hapticManager.playDyingHaptic()

        guard let currentUserID = UserDefaults.standard.string(forKey: "glow_user_id"),
              let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No current user ID or access token found")
            return
        }

        selectedUser = user

        // Check if tapped user is the logged-in user
        if user.user_id == currentUserID {
            print("👤 Tapped on own profile - switching to Profile tab")
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToProfile"), object: nil)
            return
        }

        // Fetch profile to determine follow status
        print("🔍 Fetching profile for \(user.name)...")
        NetworkManager.shared.getProfile(
            viewerID: currentUserID,
            profileID: user.user_id,
            accessToken: accessToken
        ) { response in
            DispatchQueue.main.async {
                guard let response = response else {
                    print("❌ Failed to fetch profile")
                    return
                }

                let isPublic = response.is_public ?? false

                // Check if profile is public first
                if isPublic {
                    print("🌍 Public profile - showing posts")
                    self.navigateToOtherProfile = true
                } else {
                    // Private profile - check follow status
                    switch response.follow_status {
                    case "not_following":
                        print("🔒 Private profile - not following")
                        self.navigateToPrivateProfile = true
                    case "pending":
                        print("⏳ Follow request pending")
                        // Fetch gender before navigating
                        self.fetchGenderAndNavigate(userID: user.user_id)
                    case "following":
                        print("✅ Following private profile - showing posts")
                        self.navigateToOtherProfile = true
                    default:
                        print("⚠️ Unknown follow status: \(response.follow_status)")
                    }
                }
            }
        }
    }

    // MARK: - Fetch Gender and Navigate
    private func fetchGenderAndNavigate(userID: String) {
        guard let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
            print("❌ No access token found")
            // Navigate anyway with empty gender
            self.navigateToPendingRequest = true
            return
        }

        NetworkManager.shared.fetchUserGender(userID: userID, accessToken: accessToken) { response in
            DispatchQueue.main.async {
                if let response = response, response.status == "success" {
                    self.userGender = response.gender ?? ""
                    print("✅ Fetched gender: \(self.userGender)")
                } else {
                    self.userGender = ""
                }
                // Navigate to pending page
                self.navigateToPendingRequest = true
            }
        }
    }

}

#Preview {
    ExploreView()
}
