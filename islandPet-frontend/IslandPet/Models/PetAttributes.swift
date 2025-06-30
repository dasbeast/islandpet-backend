//
//  PetAttributes.swift
//  IslandPet
//
//  Created by Bailey Kiehl on 5/22/25.
//

import ActivityKit

struct PetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var happiness: Int   // 0–100
        var hunger: Int      // 0–100
    }
    /// Unique instance identifier for this pet/activity
    var petID: String

    /// Species identifier matching the assetName (e.g., "shelby")
    var speciesID: String
    
}
