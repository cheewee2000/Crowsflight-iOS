//
//  CrowsflightApp.swift
//  CF-Watch WatchKit Extension
//
//  Created by Che-Wei Wang on 8/29/22.
//  Copyright © 2022 CWandT. All rights reserved.
//

import SwiftUI

@main
struct CrowsflightApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var delegate

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        //WKNotificationScene(controller: NotificationController.self, category: "myCategory")
            
    }
}