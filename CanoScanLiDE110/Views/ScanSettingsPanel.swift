import ScannerKit
import SwiftUI

struct ScanSettingsPanel: View {
    @EnvironmentObject var viewModel: ScannerViewModel

    var body: some View {
        HStack(spacing: 12) {
            Picker("Area", selection: areaPresetBinding) {
                ForEach(ScanAreaPreset.allCases) { preset in
                    Text(preset.rawValue).tag(preset)
                }
            }
            .frame(width: 130)

            Picker("DPI", selection: $viewModel.settings.resolution) {
                ForEach(ScanSettings.availableResolutions, id: \.self) { res in
                    Text("\(res) DPI").tag(res)
                }
            }
            .frame(width: 120)

            Picker("Mode", selection: $viewModel.settings.colorMode) {
                ForEach(ColorMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .frame(width: 130)

            Picker("Format", selection: $viewModel.settings.outputFormat) {
                ForEach(OutputFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .frame(width: 100)
        }
    }

    private var areaPresetBinding: Binding<ScanAreaPreset> {
        Binding(
            get: { viewModel.currentPreset },
            set: { viewModel.applyPreset($0) }
        )
    }
}
