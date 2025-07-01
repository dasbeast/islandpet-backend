//
//  Pet.swift
//  IslandPet
//
//  Created by Bailey Kiehl on 5/29/25.
//

import SwiftUI

struct Pet: Identifiable, Hashable, Codable {
    let id: String
    let name       : String
    let assetName  : String        // name in Assets.xcassets

    init(id: String, name: String, assetName: String) {
        self.id = id
        self.name = name
        self.assetName = assetName
    }

    // Computed property; NOT part of the hash
    var image: Image { Image(assetName) }

    static let winnie = Pet(id: "winnie", name: "Winnie", assetName: "winnie")
    static let finley = Pet(id: "finley", name: "Finley", assetName: "finley")
    static let maggie = Pet(id: "maggie", name: "Maggie", assetName: "maggie")
    static let shelby = Pet(id: "shelby", name: "Shelby", assetName: "shelby")
    static let hugo = Pet(id: "hugo", name: "Hugo", assetName: "hugo")
    static let luna = Pet(id: "luna", name: "Luna", assetName: "luna")
    static let macy = Pet(id: "macy", name: "Macy", assetName: "macy")
    static let goose = Pet(id: "goose", name: "Goose", assetName: "goose")

    static let all: [Pet] = [.winnie, .finley, .maggie, .shelby, .hugo, .luna, .macy, .goose]

    /// Create a new pet instance with a unique ID from a given species template.
    static func makeInstance(from species: Pet) -> Pet {
        return Pet(
            id: UUID().uuidString,
            name: species.name,
            assetName: species.assetName
        )
    }
}
