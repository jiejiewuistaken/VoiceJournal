import SwiftUI
import MapKit

public struct EntryDetailView: View {
    let entry: Entry

    public init(entry: Entry) {
        self.entry = entry
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let region = mapRegion(entry: entry) {
                    Map(initialPosition: .region(region))
                        .frame(height: 220)
                        .cornerRadius(12)
                }
                Text(entry.createdAt, style: .date)
                    .font(.subheadline).foregroundColor(.secondary)
                if let place = entry.location?.placemarkDescription { Text(place).bold() }
                if let ip = entry.publicIP { Text("IP: \(ip)").foregroundColor(.secondary) }
                Divider()
                Text(entry.transcript)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding()
        }
        .navigationTitle("Entry")
    }

    private func mapRegion(entry: Entry) -> MKCoordinateRegion? {
        guard let loc = entry.location else { return nil }
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude), span: span)
    }
}

