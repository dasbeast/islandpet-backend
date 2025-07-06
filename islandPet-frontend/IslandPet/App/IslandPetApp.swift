import SwiftUI
import ActivityKit

@main
struct IslandPetApp: App {
    init() {
        // Make the current-page dot use the label color (black in light, white in dark)
               UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.label
               // Make the other dots use a secondary label color (lighter contrast)
               UIPageControl.appearance().pageIndicatorTintColor = UIColor.secondaryLabel
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // MARK: – App‑level state
    @State private var adoptedPet: Pet? = nil          // nil ⇒ show picker
    @State private var isLoading: Bool = true          // show loading screen on launch
    // persisted pet identifiers
    @AppStorage("petID", store: UserDefaults(suiteName: "group.com.superbailey.IslandPet")) private var storedPetID: String = ""
    @AppStorage("speciesID", store: UserDefaults(suiteName: "group.com.superbailey.IslandPet")) private var storedSpeciesID: String = ""
    @AppStorage("sessionID", store: UserDefaults(suiteName: "group.com.superbailey.IslandPet")) private var storedSessionID: String = ""
    @State private var didLoad: Bool = false

    // MARK: – Main scene
    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    IslandPetLoadingView()
                } else if let pet = adoptedPet {
                    PetDashboardView(pet: pet) {
                        // clear persisted pet and navigate back to selection
                        storedPetID = ""
                        storedSpeciesID = ""
                        storedSessionID = ""
                        adoptedPet = nil
                    }
                } else {
                    PetSelectionView { newPet in
                        // Persist the chosen pet and transition to the dashboard
                        storedPetID     = newPet.id
                        storedSpeciesID = newPet.assetName
                        adoptedPet      = newPet
                    }
                }
            }
            .task {
                // Ensure the loading screen is visible for at least 3 seconds
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                // 🔍 Debug: what’s in storage right now?
               
                if !didLoad {
                    if !storedPetID.isEmpty,
                       let descriptor = Pet.all.first(where: { $0.assetName == storedSpeciesID }) {
                        adoptedPet = Pet(id: storedPetID, name: descriptor.name, assetName: descriptor.assetName)
                    } else {
                        // clear invalid persisted data
                        storedPetID = ""
                        storedSpeciesID = ""
                    }
                    isLoading = false
                    didLoad = true
                }
            }
        }
    }
}
