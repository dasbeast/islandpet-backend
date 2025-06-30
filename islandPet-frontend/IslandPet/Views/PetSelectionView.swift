//
//  PetSelectionView.swift
//  IslandPet
//
//  Created by Bailey Kiehl on 5/29/25.
//

import SwiftUI


struct PetSelectionView: View {
    @AppStorage("speciesID") private var storedSpeciesID: String = ""
    @AppStorage("sessionID") private var storedSessionID: String = ""
    @AppStorage("petID") private var storedPetID: String = ""
    @State private var selection: Pet = Pet.all.first ?? .winnie
    @State private var showAlert = false
    @State private var alertMessage: String = ""
    var onAdopt: (Pet) -> Void      // callback to dashboard

    var body: some View {
        VStack(spacing: 32) {
            Text("Choose Your Island Pet")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            // swipeable carousel
            TabView(selection: $selection) {
                ForEach(Pet.all) { pet in
                    pet.image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 220)
                        .tag(pet)
                        .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 300)
            .padding(.bottom, 20)

            Text(selection.name)
                .font(.title2.bold())

            Button {
                // Prevent duplicate adoption calls
                guard storedSessionID.isEmpty else {
                    // Already adopted; just proceed
                    onAdopt(selection)
                    return
                }
                Task {
                    // Create a new pet instance to get a unique pet ID
                    let instance = Pet.makeInstance(from: selection)
                    // 1. Generate a unique session ID for this pet life
                    let newSessionID = UUID().uuidString
                    storedSessionID = newSessionID
                    
                    do {
                        // 2. Register the new pet session on the server with this session ID
                        try await Network.registerPetSession(
                            activityID: newSessionID,
                            token: "",
                            petID: instance.id,
                            speciesID: instance.assetName
                        )
                        // 3. Persist the chosen species and invoke the adopt callback
                        storedSpeciesID = instance.assetName
                        storedPetID = instance.id
                        onAdopt(instance)
                    } catch {
                        alertMessage = "Failed to adopt pet: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            } label: {
                Label("Adopt \(selection.name)", systemImage: "pawprint.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.accentColor)
            .padding(.horizontal, 40)
            .disabled(!storedSessionID.isEmpty)
        }
        .padding()
        .onAppear {
            if !storedSpeciesID.isEmpty,
               let saved = Pet.all.first(where: { $0.assetName == storedSpeciesID }) {
                selection = saved
            }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
