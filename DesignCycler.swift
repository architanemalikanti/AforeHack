//
//  DesignCycler.swift
//  GlowProject
//
//  Created by Archita Nemalikanti on 11/19/25.
//

import Foundation

/// Manages cycling through a user's designs
class DesignCycler: ObservableObject {
    @Published var currentDesign: DesignItem?
    @Published var isLoading: Bool = false

    private var designs: [DesignItem] = []
    private var currentIndex: Int = 0
    private let userID: String
    private let accessToken: String

    init(userID: String, accessToken: String) {
        self.userID = userID
        self.accessToken = accessToken
    }

    /// Load designs from backend (called on first reload)
    func loadDesigns(completion: @escaping (Bool) -> Void) {
        guard designs.isEmpty else {
            // Already loaded, just cycle to next
            cycleToNext()
            completion(true)
            return
        }

        print("🔄 Loading designs for user \(userID)...")
        isLoading = true

        NetworkManager.shared.getUserDesigns(userID: userID, accessToken: accessToken) { [weak self] response in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                guard let response = response, response.status == "success" else {
                    print("❌ Failed to load designs")
                    completion(false)
                    return
                }

                self.designs = response.designs

                if !self.designs.isEmpty {
                    // Start at index 1 (second design) since first design is already showing
                    // If only one design, start at 0
                    self.currentIndex = self.designs.count > 1 ? 1 : 0
                    self.currentDesign = self.designs[self.currentIndex]

                    print("✅ Loaded \(self.designs.count) designs")
                    print("   Starting at design \(self.currentIndex + 1): \(self.designs[self.currentIndex].design_name)")
                    completion(true)
                } else {
                    print("⚠️ No designs found for user")
                    completion(false)
                }
            }
        }
    }

    /// Cycle to next design
    func cycleToNext() {
        guard !designs.isEmpty else {
            print("⚠️ No designs to cycle through")
            return
        }

        currentIndex = (currentIndex + 1) % designs.count
        currentDesign = designs[currentIndex]

        print("🔄 Cycled to design \(currentIndex + 1)/\(designs.count)")
        print("   Design: \(designs[currentIndex].design_name)")
        print("   Song: \(designs[currentIndex].song)")
    }

    /// Reset to first design
    func reset() {
        currentIndex = 0
        if !designs.isEmpty {
            currentDesign = designs[0]
        }
    }
}
