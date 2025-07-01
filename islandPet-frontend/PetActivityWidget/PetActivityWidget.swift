import WidgetKit
import SwiftUI
import UIKit
import ActivityKit
import AppIntents

// A helper view to contain the logic for switching between widget families.
struct PetActivityView: View {
    // This environment variable lets us check where the widget is being displayed.
    @Environment(\.activityFamily) var activityFamily
    let context: ActivityViewContext<PetAttributes>

    var body: some View {
        // This is the main view for the Lock Screen.
        // We'll use a switch statement to provide a different, non-interactive
        // view specifically for the Apple Watch.
        switch activityFamily {
        case .small:
            // This custom view will be used for the Apple Watch Smart Stack.
            // It's non-interactive and only shows the pet.
            HStack(spacing: 10) {
                            let imageName = context.attributes.speciesID
                            let uiImage = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")!
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Button(intent: PlayPetIntent(
                                        petID: context.attributes.petID,
                                        hunger: context.state.hunger,
                                        happiness: context.state.happiness,
                                        speciesID: context.attributes.speciesID
                                        )
                                    ) {
                                       Image(systemName: "heart.fill")
                                    }
                                    .tint(.mint.opacity(0.8))
                                    
                                    Text("\(context.state.happiness)%")
                                        .font(.caption)
                                }
                                HStack {
                                    Button(intent: FeedPetIntent(
                                        petID: context.attributes.petID,
                                        hunger: context.state.hunger,
                                        happiness: context.state.happiness,
                                        speciesID: context.attributes.speciesID
                                        )
                                    ) {
                                        Image(systemName: "fork.knife")
                                    }
                                    .tint(.pink.opacity(0.8))
                                    Text("\(context.state.hunger)%")
                                        .font(.caption)
                                }
                            }
                        }
        default:
            // This is the standard Lock Screen view for the iPhone.
            let imageName = context.attributes.speciesID
            let uiImage = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")!
            HStack(alignment: .center, spacing: 12) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(context.attributes.speciesID.capitalized)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        if #available(iOS 16.1, *) {
                            Button(intent: PlayPetIntent(
                                petID: context.attributes.petID,
                                hunger: context.state.hunger,
                                happiness: context.state.happiness,
                                speciesID: context.attributes.speciesID
                                )
                            ) {
                                Label("Play", systemImage: "gamecontroller")
                                    .labelStyle(.titleAndIcon)
                            }
                            .font(.subheadline)
                            .tint(.mint)
                            .frame(minWidth: 100)
                        }
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 4) {
                        statRow(
                            title: "Happiness",
                            value: context.state.happiness,
                            tint: .mint
                        )
                        statRow(
                            title: "Hunger",
                            value: context.state.hunger,
                            tint: .pink
                        )
                    }

                    HStack {
                        Spacer()
                        if #available(iOS 16.1, *) {
                            Button(intent: FeedPetIntent(
                                petID: context.attributes.petID,
                                hunger: context.state.hunger,
                                happiness: context.state.happiness,
                                speciesID: context.attributes.speciesID
                                )
                            ) {
                                Label("Feed", systemImage: "fork.knife")
                                    .labelStyle(.titleAndIcon)
                            }
                            .font(.subheadline)
                            .tint(.pink)
                            .frame(minWidth: 100)
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.trailing, 12)
            }
            .activityBackgroundTint(Color.black.opacity(0.45))
            .activitySystemActionForegroundColor(.black)
        }
    }
}


@main
struct PetActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetAttributes.self) { context in
            // Use the helper view to render the correct UI.
            PetActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    let imageName = context.attributes.speciesID
                    let uiImage = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")!
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .center, spacing: 6) {
                        statRow(
                            title: "Happiness",
                            value: context.state.happiness,
                            tint: .mint,
                            barWidth: 80
                        )
                        statRow(
                            title: "Hunger",
                            value: context.state.hunger,
                            tint: .pink,
                            barWidth: 80
                        )
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(spacing: 8) {
                        if #available(iOS 16.1, *) {
                            Button(intent: PlayPetIntent(petID: context.attributes.petID, hunger: context.state.hunger, happiness: context.state.happiness, speciesID: context.attributes.speciesID)) {
                                Image(systemName: "gamecontroller")
                                    .imageScale(.large)
                            }
                            .tint(.mint)

                            Button(intent: FeedPetIntent(petID: context.attributes.petID, hunger: context.state.hunger, happiness: context.state.happiness, speciesID: context.attributes.speciesID)) {
                                Image(systemName: "fork.knife")
                                    .imageScale(.large)
                            }
                            .tint(.pink)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Spacer()
                }
            } compactLeading: {
                let imageName = context.attributes.speciesID
                let uiImage = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")!
                Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 25)
            } compactTrailing: {
                // This view is intentionally left empty.
            } minimal: {
                let imageName = context.attributes.speciesID
                let uiImage = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")!
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
            }
        }
        .supplementalActivityFamilies([.small])
    }
}
// MARK: – Helper for lock‑screen stats
@ViewBuilder
private func statRow(title: String,
                     value: Int,
                     tint: Color,
                     barWidth: CGFloat? = nil) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        HStack {
            Text(title)
                .font(.caption2)
            Spacer(minLength: 4)
            Text("\(value)%")
                .font(.caption2)
                .monospacedDigit()
        }
        ProgressView(value: Double(value), total: 100)
            .progressViewStyle(.linear)
            .frame(width: barWidth)          // constrain when width provided
            .tint(tint)
    }
}
