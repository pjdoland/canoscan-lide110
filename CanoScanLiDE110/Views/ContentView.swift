import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ScannerViewModel

    var body: some View {
        Group {
            if !viewModel.saneInstalled {
                SetupGuideView()
            } else {
                mainContent
            }
        }
        .task {
            await viewModel.checkEnvironment()
        }
    }

    private var mainContent: some View {
        NavigationSplitView {
            DocumentListView()
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 280)
        } detail: {
            ZStack {
                ScanAreaSelectionView()

                if viewModel.state == .scanning {
                    ScanProgressView()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task { await viewModel.scan() }
                } label: {
                    Label(viewModel.pages.isEmpty ? "Scan" : "Scan Page \(viewModel.pages.count + 1)",
                          systemImage: "scanner")
                }
                .disabled(!viewModel.canScan)
                .help("Scan a page (⌘↩)")

                Menu {
                    Button("Export Current Page…") {
                        Task { await viewModel.exportCurrentPage() }
                    }
                    .disabled(viewModel.selectedPage == nil)

                    Button("Export All as PDF…") {
                        Task { await viewModel.exportAllAsPDF() }
                    }
                    .disabled(viewModel.pages.isEmpty)
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(viewModel.pages.isEmpty)
            }

            ToolbarItem(placement: .automatic) {
                ScanSettingsPanel()
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { if case .error = viewModel.state { return true } else { return false } },
                set: { if !$0 { viewModel.dismissError() } }
            )
        ) {
            Button("OK") { viewModel.dismissError() }
        } message: {
            if case .error(let msg) = viewModel.state {
                Text(msg)
            }
        }
        .overlay {
            if !viewModel.scannerDetected && viewModel.pages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "scanner")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Scanner Not Detected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Connect your CanoScan LiDE 110 via USB and click Refresh.")
                        .foregroundStyle(.secondary)
                    Button("Refresh") {
                        Task { await viewModel.checkEnvironment() }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
    }
}
