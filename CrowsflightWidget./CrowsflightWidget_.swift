//
//  CrowsflightWidget_.swift
//  CrowsflightWidget
//
//  Widget configuration: distance + bearing to the current destination,
//  small / medium / large.
//

import WidgetKit
import SwiftUI

struct CrowsflightWidget_: Widget {
    let kind = "CrowsflightWidget"

    // Crowsflight's off-white field — fills the whole widget, edge to edge.
    private let field = Color(red: 0xF9/255, green: 0xF9/255, blue: 0xF9/255)

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                CrowsflightWidgetEntryView(entry: entry)
                    .containerBackground(field, for: .widget)
            } else {
                CrowsflightWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Crowsflight")
        .description("Distance and bearing to your current destination.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
