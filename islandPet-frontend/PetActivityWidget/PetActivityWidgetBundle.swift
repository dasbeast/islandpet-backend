//
//  PetActivityWidgetBundle.swift
//  PetActivityWidget
//
//  Created by Bailey Kiehl on 5/22/25.
//

import WidgetKit
import SwiftUI

@main
struct PetActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        PetActivityWidget()
        PetStatusWidget()
    }
}
