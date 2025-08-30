import SwiftUI

public struct RecordButtonView: View {
    public var onStart: () -> Void
    public var onStop: () -> Void

    @State private var isPressing = false

    public init(onStart: @escaping () -> Void, onStop: @escaping () -> Void) {
        self.onStart = onStart
        self.onStop = onStop
    }

    public var body: some View {
        Circle()
            .fill(isPressing ? Color.red.opacity(0.9) : Color.red)
            .frame(width: 72, height: 72)
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 4)
            .scaleEffect(isPressing ? 0.95 : 1.0)
            .gesture(LongPressGesture(minimumDuration: 0, maximumDistance: 50)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        onStart()
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    onStop()
                }
            )
            .accessibilityLabel("Hold to record")
    }
}

