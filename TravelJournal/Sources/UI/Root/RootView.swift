import SwiftUI
import AVFoundation

public struct RootView: View {
    @StateObject private var servicesBox = ServicesBox()
    @State private var recordingCoordinator: RecordingCoordinator?
    @State private var lastTempURL: URL?
    @State private var latestEntries: [Entry] = []

    public init() {}

    public var body: some View {
        Group {
            if let store = servicesBox.store {
                HStack(alignment: .top) {
                    TripListView(store: store)
                    Divider()
                    VStack(alignment: .leading) {
                        if let trip = store.selectedTrip {
                            Text(trip.title).font(.title2).bold()
                            EntryListView(entries: latestEntries)
                            Spacer()
                            HStack {
                                Spacer()
                                RecordButtonView(onStart: startRecording, onStop: stopRecording)
                                Spacer()
                            }
                        } else {
                            Text("Create or select a trip to start recording.")
                            Spacer()
                        }
                    }
                    .padding()
                }
                .onChange(of: store.selectedTrip?.id) { _ in reloadEntries() }
                .onAppear { reloadEntries() }
            } else {
                ProgressView("Initializing...")
            }
        }
    }

    private func startRecording() {
        guard let services = servicesBox.services, let trip = servicesBox.store?.selectedTrip else { return }
        let coordinator = RecordingCoordinator(storage: services.storage, locationService: services.location, ipService: services.ip, tripId: trip.id)
        do {
            lastTempURL = try coordinator.beginRecording()
            recordingCoordinator = coordinator
        } catch {
            print("Begin recording failed: \(error)")
        }
    }

    private func stopRecording() {
        // Here you should pass the transcript from your existing ASR
        let transcript = ""
        recordingCoordinator?.endRecording(transcript: transcript) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    reloadEntries()
                case .failure(let error):
                    print("Save entry failed: \(error)")
                }
            }
        }
        recordingCoordinator = nil
    }

    private func reloadEntries() {
        guard let store = servicesBox.store, let trip = store.selectedTrip else {
            latestEntries = []
            return
        }
        latestEntries = store.entries(for: trip)
    }
}

private final class ServicesBox: ObservableObject {
    @Published var services: AppServices?
    @Published var store: TripStore?

    init() {
        DispatchQueue.main.async {
            do {
                let services = try AppServices()
                self.services = services
                self.store = TripStore(services: services)
            } catch {
                print("Init services failed: \(error)")
            }
        }
    }
}

