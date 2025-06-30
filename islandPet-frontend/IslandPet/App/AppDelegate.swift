//
//  AppDelegate.swift
//  IslandPet
//
//  Created by Bailey Kiehl on 6/11/25.
//


import UIKit
import ActivityKit
import UserNotifications    // for UNUserNotificationCenter

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Let iOS deliver silent pushes to us
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    // This gets called whenever a push arrives (including silent Live-Activity pushes)
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard
          let aps = userInfo["aps"] as? [String: Any],
          let contentState = aps["content-state"] as? [String: Any],
          let hunger = contentState["hunger"] as? Int,
          let happiness = contentState["happiness"] as? Int
        else {
            completionHandler(.noData)
            return
        }

        Task {
            // Find your running Live Activity (there should only be one)
            if let activity = Activity<PetAttributes>.activities.first {
                var state = activity.contentState
                state.hunger    = hunger
                state.happiness = happiness
                // Update it locally
                await activity.update(using: state)
            }
            completionHandler(.newData)
        }
    }
}
