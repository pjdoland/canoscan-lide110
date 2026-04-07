import ScannerKit
import SwiftUI

struct ScanSettingsPanel: View {
    @EnvironmentObject var viewModel: ScannerViewModel
    @State private var showAdvancedSettings = false

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

            Button {
                showAdvancedSettings.toggle()
            } label: {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .popover(isPresented: $showAdvancedSettings) {
                AdvancedSettingsPopover()
                    .environmentObject(viewModel)
            }
        }
    }

    private var areaPresetBinding: Binding<ScanAreaPreset> {
        Binding(
            get: { viewModel.currentPreset },
            set: { viewModel.applyPreset($0) }
        )
    }
}
