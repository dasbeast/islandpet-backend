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
        let idString = petID
        if speciesID.isEmpty {
            intentLog.error("Empty speciesID for FeedPetIntent, petID: \(petID, privacy: .public)")
        }
        intentLog.info("🎮 feedPetIntent uuid success ")
        // Compute new state
        // Hunger scale: 0 = full, 100 = starving. Feeding should *decrease* hunger.
        let newHunger = max(0, hunger - 20)
        let newHappiness = happiness
        
        intentLog.info("hunger updated")

        // Update Live Activity
        if let activity = Activity<PetAttributes>.activities.first(where: { $0.attributes.petID == petID }) {
            await activity.update(using: PetAttributes.ContentState(happiness: newHappiness, hunger: newHunger))
        } else {
            intentLog.error("No Live Activity matching ID: \(petID, privacy: .public)")
            return .result(value: "Live Activity session not found.")
        }

        // Persist to backend
        do {
            try await Network.sendPetStateUpdate(
                petID: petID,
                hunger: newHunger,
                happiness: newHappiness
            )
        } catch {
            intentLog.error("sendPetStateUpdate error: \(error.localizedDescription, privacy: .public)")
            return .result(value: "Failed to feed pet.")
        }
        
        intentLog.info("post network")

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
        if speciesID.isEmpty {
            intentLog.error("Empty speciesID for PlayPetIntent, petID: \(petID, privacy: .public)")
        }
        intentLog.info("🎮 PlayPetIntent uuid success ")
        // Compute new state
        let newHunger = hunger
        let newHappiness = min(100, happiness + 20)

        // Update Live Activity
        if let activity = Activity<PetAttributes>.activities.first(where: { $0.attributes.petID == petID }) {
            await activity.update(using: PetAttributes.ContentState(happiness: newHappiness, hunger: newHunger))
        } else {
            intentLog.error("No Live Activity matching ID: \(petID, privacy: .public)")
            return .result(value: "Live Activity session not found.")
        }

        // Persist to backend
        do {
            try await Network.sendPetStateUpdate(
                petID: petID,
                hunger: newHunger,
                happiness: newHappiness
            )
        } catch {
            intentLog.error("sendPetStateUpdate error: \(error.localizedDescription, privacy: .public)")
            return .result(value: "Failed to play with pet.")
        }

        return .result(value: "Played with pet.")
    }
}
