import SwiftUI

struct ScanPreviewView: View {
    @EnvironmentObject var viewModel: ScannerViewModel
    @State private var zoomScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            if let image = viewModel.previewImage {
                let nsImage = image
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(zoomScale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                zoomScale = max(1.0, min(value, 5.0))
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation {
                            zoomScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color(nsColor: .windowBackgroundColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
