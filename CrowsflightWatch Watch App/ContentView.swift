// CrowsflightWatch Watch App/ContentView.swift
//
// Vertical page per destination (crown/swipe), same face as the phone/widget.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WatchDestinationStore
    @EnvironmentObject var location: WatchLocationProvider

    @State private var selection = 0

    private let field = Color(red: 0xF9/255, green: 0xF9/255, blue: 0xF9/255)
    private let name = Color(white: 0.2)
    private let dim = Color(white: 0.45)

    var body: some View {
        ZStack {
            field.ignoresSafeArea()
            if store.destinations.isEmpty {
                message("Open Crowsflight on your iPhone")
            } else if location.authorized == false {
                message("Allow location for Crowsflight in watch Settings")
            } else {
                TabView(selection: $selection) {
                    ForEach(Array(store.destinations.enumerated()), id: \.offset) { i, dest in
                        DestinationPage(destination: dest, units: store.units).tag(i)
                    }
                }
                .tabViewStyle(.verticalPage)
                .onChange(of: store.destinations.count) { _, n in
                    if selection >= n { selection = max(0, n - 1) }
                }
            }
        }
        .onAppear { location.start() }
    }

    private func message(_ text: String) -> some View {
        VStack(spacing: 6) {
            Text("Crowsflight").font(.system(size: 16, weight: .light)).foregroundColor(name)
            Text(text).font(.system(size: 12, weight: .light)).foregroundColor(dim)
                .multilineTextAlignment(.center).padding(.horizontal, 8)
        }
    }
}

struct DestinationPage: View {
    @EnvironmentObject var location: WatchLocationProvider
    let destination: WatchSyncPayload.Destination
    let units: String

    private let number = Color(white: 0.1)
    private let name = Color(white: 0.2)
    private let dim = Color(white: 0.45)

    var body: some View {
        GeometryReader { geo in
            let u = DialView.underlayRadius(for: geo.size)
            if location.hasFix {
                let model = makeRenderModel(
                    destinationName: destination.name, destinationIndex: 0, destinationCount: 1,
                    destLat: destination.lat, destLng: destination.lng,
                    userLat: location.userLat, userLng: location.userLng,
                    accuracyMeters: location.accuracyMeters,
                    units: units, course: location.course, heading: location.heading,
                    fixTimestamp: Date(), now: Date(), staleThreshold: .infinity)
                ZStack {
                    DialView(model: model, underlayRadius: u)
                    Text(model.destinationName.uppercased())
                        .font(.system(size: u * 0.30, weight: .light))
                        .foregroundColor(name).lineLimit(1)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2 - u * 1.9)
                    VStack(spacing: 1) {
                        Text(model.distanceValue)
                            .font(.system(size: u * 0.52, weight: .light)).foregroundColor(number)
                        Text(model.distanceUnit)
                            .font(.system(size: u * 0.15, weight: .light))
                            .foregroundColor(number.opacity(0.85))
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            } else {
                VStack(spacing: 6) {
                    Text(destination.name.uppercased())
                        .font(.system(size: 13, weight: .light)).foregroundColor(name).lineLimit(1)
                    Text("Locating…").font(.system(size: 12, weight: .light)).foregroundColor(dim)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}
