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

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                CrowsflightWidgetEntryView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                CrowsflightWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("Crowsflight")
        .description("Distance and bearing to your current destination.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
