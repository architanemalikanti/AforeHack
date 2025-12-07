import SwiftUI

// MARK: - Private Profile Handler
// Shows PrivateProfileView for locked/private profiles

struct PrivateProfileHandler: View {
    let user: SearchUserResult
    let viewerID: String  // The person viewing the profile
    @Binding var navigateBack: Bool

    @State private var profileImageURL: String? = nil
    @State private var userGender: String = ""
    @State private var isLoading = true
    @State private var showRegularPrivate = false

    init(user: SearchUserResult, viewerID: String, navigateBack: Binding<Bool> = .constant(false)) {
        self.user = user
        self.viewerID = viewerID
        self._navigateBack = navigateBack
    }

    var body: some View {
        ZStack {
            if showRegularPrivate {
                // No profile image - show regular PrivateProfileView
                PrivateProfileView(user: user, navigateBack: $navigateBack)
                    .transition(.opacity)
            } else if isLoading {
                // Loading state
                ZStack {
                    Color.black.ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showRegularPrivate)
        .onAppear {
            fetchProfileData()
        }
    }

    private func fetchProfileData() {
        // Fetch profile image
        NetworkManager.shared.fetchUserProfileImage(userID: user.user_id) { imageResponse in
            // Fetch gender
            guard let accessToken = KeychainManager.shared.get(forKey: "access_token") else {
                print("❌ No access token found")
                navigateToRegularPrivate()
                return
            }

            NetworkManager.shared.fetchUserGender(userID: user.user_id, accessToken: accessToken) { genderResponse in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.userGender = genderResponse?.gender ?? ""
                    print("✅ Showing PrivateProfileView")
                    navigateToRegularPrivate()
                }
            }
        }
    }

    private func navigateToRegularPrivate() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.showRegularPrivate = true
        }
    }
}
