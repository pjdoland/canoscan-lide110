import ScannerKit
import SwiftUI

struct AdvancedSettingsPopover: View {
    @EnvironmentObject var viewModel: ScannerViewModel

    var body: some View {
        Form {
            Section("Image") {
                Picker("Color Mode", selection: $viewModel.settings.colorMode) {
                    ForEach(ColorMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Picker("Bit Depth", selection: $viewModel.settings.bitDepth) {
                    ForEach(ScanSettings.availableBitDepths, id: \.self) { depth in
                        Text("\(depth)-bit").tag(depth)
                    }
                }
                .disabled(viewModel.settings.colorMode == .lineart)
            }

            Section("Adjustments") {
                HStack {
                    Text("Brightness")
                        .frame(width: 70, alignment: .leading)
                    Slider(value: brightnessBinding, in: -100...100, step: 1)
                    Text("\(viewModel.settings.brightness)")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }

                HStack {
                    Text("Contrast")
                        .frame(width: 70, alignment: .leading)
                    Slider(value: contrastBinding, in: -100...100, step: 1)
                    Text("\(viewModel.settings.contrast)")
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                }

                if viewModel.settings.brightness != 0 || viewModel.settings.contrast != 0 {
                    Button("Reset Adjustments") {
                        viewModel.settings.brightness = 0
                        viewModel.settings.contrast = 0
                    }
                }
            }

            Section("Output") {
                Picker("Format", selection: $viewModel.settings.outputFormat) {
                    ForEach(OutputFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 300)
        .padding()
    }

    private var brightnessBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.settings.brightness) },
            set: { viewModel.settings.brightness = Int($0) }
        )
    }

    private var contrastBinding: Binding<Double> {
        Binding(
            get: { Double(viewModel.settings.contrast) },
            set: { viewModel.settings.contrast = Int($0) }
        )
    }
}
