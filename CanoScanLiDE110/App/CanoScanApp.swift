import SwiftUI

@main
struct CanoScanApp: App {
    @StateObject private var viewModel = ScannerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Scan Page") {
                    Task { await viewModel.scan() }
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!viewModel.canScan)

                Divider()

                Button("Export Current Page…") {
                    Task { await viewModel.exportCurrentPage() }
                }
                .keyboardShortcut("e", modifiers: .command)
                .disabled(viewModel.selectedPage == nil)

                Button("Export All as PDF…") {
                    Task { await viewModel.exportAllAsPDF() }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(viewModel.pages.isEmpty)
            }
        }
    }
}
