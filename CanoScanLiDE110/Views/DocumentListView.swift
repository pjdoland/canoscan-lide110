import SwiftUI

struct DocumentListView: View {
    @EnvironmentObject var viewModel: ScannerViewModel

    var body: some View {
        List(selection: $viewModel.selectedPageID) {
            Section {
                ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                    HStack(spacing: 8) {
                        Image(nsImage: page.thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 80)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(4)
                            .shadow(radius: 1)

                        Text("Page \(index + 1)")
                            .font(.caption)
                    }
                    .tag(page.id)
                    .contextMenu {
                        Button("Delete Page") {
                            viewModel.removePage(page)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Pages (\(viewModel.pages.count))")
                    Spacer()
                    if !viewModel.pages.isEmpty {
                        Button(role: .destructive) {
                            viewModel.removeAllPages()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Remove all pages")
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
