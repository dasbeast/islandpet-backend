//
//  PetActivityManager.swift
//  IslandPet
//
//  Created by Bailey Kiehl on 6/10/25.
//

import ActivityKit
import Foundation

enum PetActivityManager {

    /// Call when the player adopts a pet or opens the app after install.
    static func startActivity(petID: String,
                              speciesID: String,
                              initialHunger: Int = 10,
                              initialHappiness: Int = 100) {
        Task {
            guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

            let attrs = PetAttributes(petID: petID, speciesID: speciesID)
            let state = PetAttributes.ContentState(
                            happiness: initialHappiness,
                            hunger: initialHunger)

            do {
                let activity = try await Activity.request(
                    attributes: attrs,
                    contentState: state,
                    pushType: .token)               // remote-updatable

                // Listen for the unique push token and forward it
                for await tokenData in activity.pushTokenUpdates {
                    do {
                        try await Network.sendLiveActivityToken(
                            tokenData,
                            activityID: activity.id,
                            petID: petID,
                            speciesID: speciesID
                        )
                    } catch {
                        print("❌ sendLiveActivityToken error:", error)
                    }
                }
            } catch {
                print("Failed to start Live Activity:", error)
            }
        }
    }
}

enum Network {
    /*
    // Uncomment and configure API base URL in Info.plist under "API_BASE_URL"
    static let baseURL: URL = {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as! String
        return URL(string: urlString)!
    }()
    */

    // MARK: - Codable models for API
    struct PetStateResponse: Decodable {
        let speciesID: String
        let hunger: Int
        let happiness: Int
    }

    private struct RegisterPayload: Codable {
        let activityID: String
        let token: String
        let petID: String
        let speciesID: String
    }

    private struct EndActivityPayload: Codable {
        let activityID: String
    }

    private struct UpdateStatePayload: Codable {
        let petID: String
        let state: State
        struct State: Codable {
            let hunger: Int
            let happiness: Int
        }
    }

    /// Sends the Live‑Activity push token to your backend.
    static func sendLiveActivityToken(_ data: Data,
                                      activityID: String,
                                      petID: String,
                                      speciesID: String) async throws {
        let url = URL(string: "https://islandpet-backend.onrender.com/register/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = RegisterPayload(
            activityID: activityID,
            token: data.map { String(format: "%02x", $0) }.joined(),
            petID: petID,
            speciesID: speciesID
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
    }

    /// Registers a new pet session on the backend without an APNs token.
    static func registerPetSession(activityID: String,
                                   token: String,
                                   petID: String,
                                   speciesID: String) async throws {
        print("[Network] registerPetSession called with activityID:", activityID, "token:", token)
        let url = URL(string: "https://islandpet-backend.onrender.com/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = RegisterPayload(
            activityID: activityID,
            token: token,
            petID: petID,
            speciesID: speciesID
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
    /// Tells the backend to delete a Live Activity record when the user ends the pet
    static func sendEndActivity(activityID: String) async throws {
        let url = URL(string: "https://islandpet-backend.onrender.com/end")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = EndActivityPayload(activityID: activityID)
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
    }

    /// Sends the pet’s updated hunger and happiness values to the backend.
    static func sendPetStateUpdate(petID: String,
                                   hunger: Int,
                                   happiness: Int) async throws {
        let url = URL(string: "https://islandpet-backend.onrender.com/update")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = UpdateStatePayload(
            petID: petID,
            state: .init(hunger: hunger, happiness: happiness)
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    /// Fetches persisted pet state from backend.
    static func fetchPetState(petID: String) async throws -> PetStateResponse {
        let url = URL(string: "https://islandpet-backend.onrender.com/pets/\(petID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        switch http.statusCode {
        case 200:
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(PetStateResponse.self, from: data)
        case 404:
            // No session yet: return default “just-born” state
            print("⚠️ fetchPetState 404 for petID \(petID), returning default state")
            return PetStateResponse(speciesID: petID, hunger: 0, happiness: 100)
        default:
            throw URLError(.badServerResponse)
        }
    }

    /// Renames an existing session's activity_id on the server.
    static func updateSessionActivityID(oldActivityID: String,
                                        newActivityID: String) async throws {
        let url = URL(string: "https://islandpet-backend.onrender.com/register/rename-session")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = [
            "oldActivityID": oldActivityID,
            "newActivityID": newActivityID
        ]
        request.httpBody = try JSONEncoder().encode(payload)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    static func endPetCompletely(petID: String) async throws {
        // Clear all pet data for this specific pet
        let url = URL(string: "https://islandpet-backend.onrender.com/pets/\(petID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}
