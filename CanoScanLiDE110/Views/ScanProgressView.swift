import SwiftUI

struct ScanProgressView: View {
    @EnvironmentObject var viewModel: ScannerViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Scanning…")
                    .font(.headline)

                Button("Cancel") {
                    Task { await viewModel.cancelScan() }
                }
                .buttonStyle(.bordered)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
