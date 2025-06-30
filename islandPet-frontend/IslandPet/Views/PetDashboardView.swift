import os
import SwiftUI
import ActivityKit

struct PetDashboardView: View {
    let pet: Pet
    let onRehome: () -> Void
    @State private var currentActivity: Activity<PetAttributes>?
    @State private var hunger: Int = 0
    @State private var happiness: Int = 100
    @AppStorage("sessionID") private var storedSessionID: String = ""
    @AppStorage("petID") private var storedPetID: String = ""
    @State private var showEndConfirmation: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // MARK: – Header
                VStack(spacing: 12) {
                    Text("Island Pet – \(pet.name)")
                        .font(.largeTitle.bold())
                    Text("Take care of \(pet.name) right from the Dynamic Island!")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                // MARK: – Pet portrait
                Image(pet.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 2))
                    .shadow(radius: 10)

                // MARK: – Stats card
                VStack(spacing: 16) {
                    statRow(title: "Hunger", value: hunger, tint: .pink)
                    statRow(title: "Happiness", value: happiness, tint: .mint)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // MARK: – Actions
                VStack(spacing: 12) {
                    Button {
                        Task { await startPet() }
                    } label: {
                        Label("Start Live Activity", systemImage: "pawprint")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(currentActivity != nil)

                    HStack(spacing: 20) {
                        actionButton("Feed", systemImage: "fork.knife") {
                            Task { await feedPet() }
                        }
                        .tint(.pink)

                        actionButton("Play", systemImage: "gamecontroller") {
                            Task { await playPet() }
                        }
                        .tint(.mint)
                    }

                    Button {
                        Task { await endPet() }
                    } label: {
                        Label("Stop Live Activity", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(currentActivity == nil)
                    
                    Button(role: .destructive) {
                        showEndConfirmation = true
                    } label: {
                        Label("End Pet", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.red)

                }
            }
            .padding(24)
        }
        .onAppear {
            print("🐞 PetDashboardView onAppear - hunger:", hunger, "happiness:", happiness)
            Task {
                do {
                    let initial = try await Network.fetchPetState(petID: storedPetID)
                    await MainActor.run {
                        hunger = initial.hunger
                        happiness = initial.happiness
                    }
                } catch {
                    print("❌ fetchPetState error:", error)
                }
            }
        }
        .onChange(of: currentActivity?.content.state) { newState in
            if let state = newState {
                print("🔄 onChange currentActivity content.state → hunger:", state.hunger, "happiness:", state.happiness)
                hunger = state.hunger
                happiness = state.happiness
            }
        }
        .onChange(of: hunger) { newHunger in
            print("🔄 hunger state changed to", newHunger)
        }
        .onChange(of: happiness) { newHappiness in
            print("🔄 happiness state changed to", newHappiness)
        }
        .task(id: currentActivity?.id) {
            guard let activity = currentActivity else { return }
            print("🐛 task observing updates for id:", activity.id)
            for await update in Activity<PetAttributes>.activityUpdates {
                guard update.id == activity.id else { continue }
                let state = update.contentState
                print("📬 task got remote update → hunger:", state.hunger, "happiness:", state.happiness)
                await MainActor.run {
                    hunger = state.hunger
                    happiness = state.happiness
                }
            }
        }
        .onReceive(Timer.publish(every: 5.0, on: .main, in: .common).autoconnect()) { _ in
            Task {
                if let activity = currentActivity {
                    // Update from Live Activity
                    let state = activity.content.state
                    print("⏰ Timer updating UI (Live Activity) → hunger:", state.hunger, "happiness:", state.happiness)
                    hunger = state.hunger
                    happiness = state.happiness
                } else {
                    // No Live Activity: fetch from server
                    print("⏰ Timer fetching state from server for petID:", pet.id)
                    do {
                        let resp = try await Network.fetchPetState(petID: pet.id)
                        print("⏰ Fetched server state → hunger:", resp.hunger, "happiness:", resp.happiness)
                        hunger = resp.hunger
                        happiness = resp.happiness
                    } catch {
                        print("❌ Timer fetchPetState error:", error)
                    }
                }
            }
        }
        .alert("End Pet?", isPresented: $showEndConfirmation) {
            Button("End Pet", role: .destructive) {
                Task { await endPetCompletely() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to permanently remove this pet? This cannot be undone.")
        }
    }

    // MARK: – Sub‑views

    @ViewBuilder
    private func statRow(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(value)%")
                    .monospacedDigit()
            }
            ProgressView(value: Double(value), total: 100)
                .tint(tint)
        }
    }

    private func actionButton(_ title: String,
                              systemImage: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
}

// MARK: – Live-Activity helpers
extension PetDashboardView {
    @MainActor
    private func startPet() async {
        print("🐛 startPet tapped")          // <-- add this
          guard ActivityAuthorizationInfo().areActivitiesEnabled else {
              print("❌ Live Activities OFF in Settings")
              return
          }

        let attrs = PetAttributes(petID: pet.id, speciesID: pet.assetName)
        let contentState = PetAttributes.ContentState(happiness: happiness, hunger: hunger)
        let content = ActivityContent(state: contentState, staleDate: nil)

        do {
            let activity = try Activity.request(
                attributes: attrs,
                content: content,
                pushType: .token
            )
            currentActivity = activity
            
            // Determine if this is a fresh start or restart
            let activityIDString = String(describing: activity.id)
            let isNewSession = storedSessionID.isEmpty || storedSessionID != activityIDString
            if isNewSession {
                print("[startPet] registering new session:", activityIDString)
            } else {
                print("[startPet] updating existing session ID:", activityIDString)
            }
            
            let newID = String(describing: activity.id)
            Task.detached {
                var first = true
                for await tokenData in activity.pushTokenUpdates {
                    do {
                        if first {
                            // on first token update, register or rename session
                            if isNewSession {
                                try await Network.registerPetSession(
                                    activityID: activity.id,
                                    token: tokenData.map { String(format: "%02x", $0) }.joined(),
                                    petID: pet.id,
                                    speciesID: pet.assetName
                                )
                                print("[startPet] registerPetSession success:", newID)
                            } else {
                                try await Network.updateSessionActivityID(
                                    oldActivityID: storedSessionID,
                                    newActivityID: activity.id
                                )
                                print("[startPet] updateSessionActivityID success:", newID)
                            }
                            await MainActor.run { storedSessionID = newID }
                            first = false
                        } else {
                            // subsequent token updates refresh token only
                            try await Network.sendLiveActivityToken(
                                tokenData,
                                activityID: activity.id,
                                petID: pet.id,
                                speciesID: pet.assetName
                            )
                            print("[startPet] sendLiveActivityToken success for:", newID)
                        }
                    } catch {
                        print("❌ session registration/update error:", error)
                    }
                }
            }
        } catch {
            print("❌ Activity.request failed:", error)
        }
    }

    private func feedPet() async {
        print("🐛 feedPet called")
        os_log("🍖 Feeding pet")

        // 1. Compute new state locally
        let newHunger    = max(0, hunger - 25)
        let newHappiness = happiness

        // 2. If a Live Activity exists, update it
        if let activity = currentActivity {
            var state = activity.content.state
            state.hunger = newHunger
            await activity.update(using: state)
            print("📡 feedPet sent Activity update → hunger:", state.hunger, "happiness:", state.happiness)
        }

        // 3. Notify backend of new pet state
        print("📡 feedPet calling backend update → hunger:", newHunger, "happiness:", newHappiness)
        Task.detached {
            do {
                try await Network.sendPetStateUpdate(
                    petID: pet.id,
                    hunger: newHunger,
                    happiness: newHappiness
                )
            } catch {
                print("❌ sendPetStateUpdate error:", error)
            }
        }

        // 4. Update local UI state
        await MainActor.run {
            hunger    = newHunger
            happiness = newHappiness
        }
    }

    private func playPet() async {
        print("🐛 playPet called")
        os_log("🎮 Playing with pet")

        // 1. Compute new state locally
        let newHunger    = hunger
        let newHappiness = min(100, happiness + 20)

        // 2. If a Live Activity exists, update it
        if let activity = currentActivity {
            var state = activity.content.state
            state.happiness = newHappiness
            await activity.update(using: state)
            print("📡 playPet sent Activity update → hunger:", state.hunger, "happiness:", state.happiness)
        }

        // 3. Notify backend of new pet state
        print("📡 playPet calling backend update → hunger:", newHunger, "happiness:", newHappiness)
        Task.detached {
            do {
                try await Network.sendPetStateUpdate(
                    petID: pet.id,
                    hunger: newHunger,
                    happiness: newHappiness
                )
            } catch {
                print("❌ sendPetStateUpdate error:", error)
            }
        }

        // 4. Update local UI state
        await MainActor.run {
            hunger    = newHunger
            happiness = newHappiness
        }
    }

    private func endPet() async {
        os_log("🛑 Ending Live Activity")
        guard let activity = currentActivity else { return }
        await activity.end(dismissalPolicy: .immediate)
        currentActivity = nil
    }
    
    @MainActor
    private func endPetCompletely() async {
        // 1. Notify backend to end the pet session
        if let activity = currentActivity {
            do {
                try await Network.sendEndActivity(activityID: activity.id)
            } catch {
                print("❌ sendEndActivity error:", error)
            }
            // 2. End the Live Activity UI
            await activity.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
        do {
            try await Network.endPetCompletely(petID: pet.id)
        } catch {
            print("❌ clearAllData error:", error)
        }
        // 3. Navigate back to pet selection
        onRehome()
    }
}
