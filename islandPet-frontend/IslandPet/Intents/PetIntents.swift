//
//  FeedPetIntent.swift
//  IslandPet
//
//  Created by Bailey Kiehl on 5/27/25.
//

import OSLog
import AppIntents
import ActivityKit
import Foundation
import SwiftUI   // for LocalizedStringResource

private let intentLog = Logger(subsystem: "com.superbailey.IslandPet",
                               category: "PetIntents")

class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        queue.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
}

// Create a single debouncer instance to be shared by both intents.
private let networkDebouncer = Debouncer(delay: 5.0)


/// “Feed” button background intent
@available(iOS 17.0, *)
struct FeedPetIntent: LiveActivityIntent, AppIntent {
    static var title: LocalizedStringResource = "Feed Pet"
    static var description: LocalizedStringResource = "Feed your virtual pet."
   
    @Parameter(title: "Pet ID")
    var petID: String
    
    @Parameter(title: "Current Hunger")
    var hunger: Int
    
    @Parameter(title: "Current Happiness")
    var happiness: Int

    @Parameter(title: "Species ID")
    var speciesID: String
    
    init() {
        self.petID = "invalid pet id"
        self.hunger = 0
        self.happiness = 0
        self.speciesID = ""
    }
    
    init(petID: String, hunger: Int, happiness: Int, speciesID: String) {
        self.petID = petID
        self.hunger = hunger
        self.happiness = happiness
        self.speciesID = speciesID
    }

        // Default initializer (required if you provide a custom one)
    

    func perform() async throws -> some IntentResult  & ReturnsValue<String> {
        intentLog.info("🍖 FeedPetIntent fired")

                // 1. Find the Live Activity first.
                guard let activity = Activity<PetAttributes>.activities.first(where: { $0.attributes.petID == petID }) else {
                    intentLog.error("No Live Activity matching ID: \(self.petID, privacy: .public)")
                    return .result(value: "error feeding")
                }

                // 2. Calculate the new state.
                let newHunger = max(0, activity.content.state.hunger - 20)
                let newHappiness = activity.content.state.happiness
                let newState = PetAttributes.ContentState(happiness: newHappiness, hunger: newHunger)

                // 3. Update the Live Activity UI immediately for a responsive feel.
                await activity.update(using: newState)
                intentLog.info("UI updated instantly for petID: \(self.petID, privacy: .public)")

                // 4. Debounce the network call to send the final state.
                networkDebouncer.debounce {
                    Task {
                        do {
                            try await Network.sendPetStateUpdate(
                                petID: self.petID,
                                hunger: newHunger,
                                happiness: newHappiness
                            )
                            intentLog.info("Network update sent for petID: \(self.petID, privacy: .public)")
                        } catch {
                            intentLog.error("sendPetStateUpdate error: \(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
                
        return .result(value: "Pet fed.")
    }
}

/// “Play” button background intent
@available(iOS 17.0, *)
struct PlayPetIntent: LiveActivityIntent, AppIntent {
    
    static var title: LocalizedStringResource = "Play with Pet"
    static var openAppWhenRun: Bool = false
    static var description: LocalizedStringResource = "Play with your virtual pet to increase its happiness."

    @Parameter(title: "Pet ID")
    var petID: String
    
    @Parameter(title: "Current Hunger")
    var hunger: Int
    
    @Parameter(title: "Current Happiness")
    var happiness: Int

    @Parameter(title: "Species ID")
    var speciesID: String

    init(petID: String, hunger: Int, happiness: Int, speciesID: String) {
        self.petID = petID
        self.hunger = hunger
        self.happiness = happiness
        self.speciesID = speciesID
    }

    // Default initializer (required if you provide a custom one)
    init() {
        self.petID = "invalid pet id"
        self.hunger = 0
        self.happiness = 0
        self.speciesID = ""
    }
    

    func perform() async throws -> some IntentResult  & ReturnsValue<String> {
        intentLog.info("🎮 PlayPetIntent fired ")

                // 1. Find the Live Activity first.
                guard let activity = Activity<PetAttributes>.activities.first(where: { $0.attributes.petID == petID }) else {
                    intentLog.error("No Live Activity matching ID: \(self.petID, privacy: .public)")
                    return .result(value: "Error playing")
                }

                // 2. Calculate the new state.
                let newHunger = activity.content.state.hunger
                let newHappiness = min(100, activity.content.state.happiness + 20)
                let newState = PetAttributes.ContentState(happiness: newHappiness, hunger: newHunger)
                
                // 3. Update the Live Activity UI immediately.
                await activity.update(using: newState)
                intentLog.info("UI updated instantly for petID: \(self.petID, privacy: .public)")

                // 4. Debounce the network call.
                networkDebouncer.debounce {
                    Task {
                        do {
                            try await Network.sendPetStateUpdate(
                                petID: self.petID,
                                hunger: newHunger,
                                happiness: newHappiness
                            )
                            intentLog.info("Network update sent for petID: \(self.petID, privacy: .public)")
                        } catch {
                            intentLog.error("sendPetStateUpdate error: \(error.localizedDescription, privacy: .public)")
                        }
                    }
                }
        return .result(value: "Played with pet.")
    }
}
