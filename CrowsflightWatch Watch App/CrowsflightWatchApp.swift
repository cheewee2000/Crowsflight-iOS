// CrowsflightWatch Watch App/CrowsflightWatchApp.swift
import SwiftUI

@main
struct CrowsflightWatchApp: App {
    @StateObject private var store = WatchDestinationStore()
    @StateObject private var location = WatchLocationProvider()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(location)
        }
    }
}
