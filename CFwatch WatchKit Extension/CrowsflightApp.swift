//
//  CrowsflightApp.swift
//  CFwatch WatchKit Extension
//
//  Created by Che-Wei Wang on 8/26/22.
//  Copyright © 2022 CWandT. All rights reserved.
//

import SwiftUI

@main
struct CrowsflightApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
