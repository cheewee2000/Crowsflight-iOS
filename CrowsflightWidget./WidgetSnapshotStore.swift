// COPY of SharedPlaces/Sources/SharedPlaces/WidgetSnapshotStore.swift — canonical + unit-tested in the SharedPlaces SPM package.
// This project shares code by target membership (Xcode file-system synchronized group),
// not a linked module, so the widget compiles its own copy. Keep the two in sync.

import Foundation

public enum WidgetSnapshotStore {
    public static let suiteName = "group.com.cwandt.crowsflight"
    public static let key = "widgetSnapshot"

    public static func write(_ snapshot: WidgetSnapshot, to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    public static func read(from defaults: UserDefaults) -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
