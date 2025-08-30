import SwiftUI
import MapKit

public struct EntryListView: View {
    let entries: [Entry]

    public init(entries: [Entry]) {
        self.entries = entries
    }

    public var body: some View {
        List(entries, id: \.id) { entry in
            NavigationLink(destination: EntryDetailView(entry: entry)) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.createdAt, style: .time).font(.subheadline).foregroundColor(.secondary)
                    if let place = entry.location?.placemarkDescription {
                        Text(place).font(.subheadline)
                    } else if let loc = entry.location {
                        Text("\(loc.latitude), \(loc.longitude)").font(.subheadline)
                    }
                    if let ip = entry.publicIP {
                        Text("IP: \(ip)").font(.caption).foregroundColor(.secondary)
                    }
                    Text(entry.transcript).lineLimit(4)
                }
                .padding(.vertical, 8)
            }
        }
    }
}

