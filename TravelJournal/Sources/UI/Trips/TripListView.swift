import SwiftUI

public struct TripListView: View {
    @ObservedObject var store: TripStore

    public init(store: TripStore) {
        self.store = store
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Trips").font(.title).bold()
                Spacer()
                Button("New Trip") { store.createTrip(title: defaultTripTitle()) }
            }
            List(selection: Binding(get: { store.selectedTrip?.id }, set: { id in
                if let id = id { store.selectedTrip = store.trips.first(where: { $0.id == id }) }
            })) {
                ForEach(store.trips, id: \.id) { trip in
                    HStack {
                        Text(trip.title)
                        Spacer()
                        Text(trip.createdAt, style: .date).foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { store.selectedTrip = trip }
                    .contextMenu {
                        Button(role: .destructive) { store.deleteTrip(trip) } label: { Text("Delete") }
                    }
                }
            }
        }
        .padding()
    }

    private func defaultTripTitle() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return "Trip " + df.string(from: Date())
    }
}

