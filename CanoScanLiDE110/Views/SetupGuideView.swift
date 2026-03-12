import SwiftUI

struct SetupGuideView: View {
    @EnvironmentObject var viewModel: ScannerViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Setup Required")
                .font(.title)
                .fontWeight(.semibold)

            Text("CanoScan LiDE 110 requires SANE backends from Homebrew to communicate with the scanner.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            VStack(alignment: .leading, spacing: 12) {
                stepView(number: 1, title: "Install Homebrew", code: "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
                stepView(number: 2, title: "Install SANE backends", code: "brew install sane-backends")
                stepView(number: 3, title: "Connect scanner via USB", code: nil)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))

            Button("Check Again") {
                Task { await viewModel.checkEnvironment() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func stepView(number: Int, title: String, code: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(.blue))
                    .foregroundColor(.white)

                Text(title)
                    .fontWeight(.medium)
            }

            if let code {
                HStack {
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(4)

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(code, forType: .string)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Copy to clipboard")
                }
                .padding(.leading, 30)
            }
        }
    }
}
