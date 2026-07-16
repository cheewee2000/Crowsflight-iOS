//
//  CrowsflightWidgetEntryView.swift
//  CrowsflightWidget
//
//  Family layouts, readout, stale dimming, placeholder, and deep-link URL.
//

import SwiftUI
import WidgetKit

struct CrowsflightWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CrowsflightEntry

    private let field = Color(red: 0xF9/255, green: 0xF9/255, blue: 0xF8/255)
    private let number = Color(white: 0.1)
    private let name = Color(white: 0.2)
    private let accuracy = Color(white: 0.33)
    private let monoGray = Color(white: 0.54)

    var body: some View {
        ZStack {
            field
            if let model = entry.model {
                dial(model)
            } else {
                placeholder
            }
        }
        .widgetURL(entry.destinationIndex.map { URL(string: "crowsflight://destination/\($0)")! })
    }

    @ViewBuilder private func dial(_ model: RenderModel) -> some View {
        GeometryReader { geo in
            let u = DialView.underlayRadius(for: geo.size)
            let numberSize = u * 0.52
            ZStack {
                DialView(model: model, underlayRadius: u)
                // Destination name near the top.
                Text(model.destinationName)
                    .font(.system(size: u * 0.30, weight: .light))
                    .foregroundColor(name).lineLimit(1)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2 - u * 1.9)
                // Centered readout: accuracy / number / unit.
                VStack(spacing: 1) {
                    Text(model.accuracyText).font(.system(size: u * 0.16, weight: .light)).foregroundColor(accuracy)
                    Text(model.distanceValue).font(.system(size: numberSize, weight: .thin)).foregroundColor(number)
                    Text(model.distanceUnit).font(.system(size: u * 0.15, weight: .light)).foregroundColor(number.opacity(0.85))
                }
                .opacity(model.isStale ? 0.45 : 1)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                // Page + freshness.
                Text(model.pageText).font(.system(size: u * 0.15, design: .monospaced)).foregroundColor(monoGray)
                    .position(x: geo.size.width - u * 0.5, y: geo.size.height - u * 0.4)
            }
        }
        .padding(family == .systemSmall ? 2 : 6)
    }

    private var placeholder: some View {
        VStack(spacing: 6) {
            Text("Crowsflight").font(.system(size: 15, weight: .light)).foregroundColor(name)
            Text("Open to set a destination").font(.system(size: 11, weight: .light)).foregroundColor(accuracy)
        }
    }
}

// Classic PreviewProvider (compiles at the widget's iOS 16 deployment target; the
// #Preview widget macro is iOS 17+). Gives Xcode canvas previews for all states.
struct CrowsflightWidget_Previews: PreviewProvider {
    static let staleModel = RenderModel(
        destinationName: "Home", distanceValue: "2.30", distanceUnit: "MILES",
        accuracyText: "± 48'", bearingDegrees: 42, progress: 104, sweptDegrees: 256,
        spreadDegrees: 30, pageText: "1/5", isStale: true)

    static var previews: some View {
        Group {
            CrowsflightWidgetEntryView(entry: CrowsflightEntry(date: .now, model: Provider.sampleModel, destinationIndex: 0))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small")
            CrowsflightWidgetEntryView(entry: CrowsflightEntry(date: .now, model: Provider.sampleModel, destinationIndex: 0))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium")
            CrowsflightWidgetEntryView(entry: CrowsflightEntry(date: .now, model: staleModel, destinationIndex: 0))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large stale")
            CrowsflightWidgetEntryView(entry: CrowsflightEntry(date: .now, model: nil, destinationIndex: nil))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("No destination")
        }
    }
}
