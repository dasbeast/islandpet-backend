import WidgetKit
import SwiftUI
import UIKit
import ActivityKit
import AppIntents

@main
struct PetActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PetAttributes.self) { context in
            // Lock‑screen / notification banner UI
            let imageName = context.attributes.speciesID
            let uiImage = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")!
            HStack(alignment: .center, spacing: 12) {
                // Big pet image on the left (dynamic asset)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                // Right‑hand column with name, stats, and buttons
                VStack(alignment: .leading, spacing: 6) {
                    // Top row: centered name with Play button on the right
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
                            .frame(minWidth: 100)          // uniform width
                        }
                    }
                    .padding(.top, 20)

                    // Middle rows: progress bars
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

                    // Bottom row: Feed button aligned to trailing
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
                            .frame(minWidth: 100)          // uniform width
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.trailing, 12)
            }
            .activityBackgroundTint(Color.black.opacity(0.45))   // semi‑transparent frosted glass
            .activitySystemActionForegroundColor(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded regions
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
                            barWidth: 80               // narrower
                        )
                        statRow(
                            title: "Hunger",
                            value: context.state.hunger,
                            tint: .pink,
                            barWidth: 80               // narrower
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
                HStack(spacing: 2) {
                                    // Combine hunger and happiness for more info at a glance
                    Image(systemName: "heart.fill")
                                           .font(.system(size: 10))
                                           .foregroundStyle(.mint)
                                       Text("\(context.state.happiness)%")
                                           .font(.caption2)
                                           .foregroundStyle(.mint)
                                       Image(systemName: "fork.knife")
                                           .font(.system(size: 10))
                                           .foregroundStyle(.pink)
                                       Text("\(context.state.hunger)%")
                                           .font(.caption2)
                                           .foregroundStyle(.pink)
                                }
            } minimal: {
                // Optimized for Apple Watch & iPhone Dynamic Island minimal
                let imageName = context.attributes.speciesID
                let uiImage = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")!
                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 15, height: 15) // Extremely small for minimal
                                    //.clipShape(Circle())
                                    //.font(.system(size: 12))
                                    //.symbolRenderingMode(.multicolor)
                                    //.fallbackToSystemImage(ifImageNotFound: "pawprint.fill")
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
