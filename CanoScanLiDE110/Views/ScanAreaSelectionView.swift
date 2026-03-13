import ScannerKit
import SwiftUI

struct ScanAreaSelectionView: View {
    @EnvironmentObject var viewModel: ScannerViewModel
    @State private var dragMode: DragMode = .none
    @State private var dragStart: CGPoint = .zero

    private let handleSize: CGFloat = 8
    private let minSelectionPx: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let bedRect = bedRect(in: geometry.size)

            ZStack(alignment: .topLeading) {
                // Background
                Color(nsColor: .controlBackgroundColor)

                // Scanner bed
                bedContent(bedRect: bedRect)

                // Dimming overlay outside selection
                selectionOverlay(bedRect: bedRect)

                // Selection border and handles
                selectionChrome(bedRect: bedRect)
            }
            .gesture(dragGesture(bedRect: bedRect))
            .onTapGesture(count: 2) {
                viewModel.applyPreset(.fullPage)
            }
        }
    }

    // MARK: - Bed Content

    @ViewBuilder
    private func bedContent(bedRect: CGRect) -> some View {
        // White bed background
        Rectangle()
            .fill(Color.white)
            .frame(width: bedRect.width, height: bedRect.height)
            .offset(x: bedRect.minX, y: bedRect.minY)
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 1)

        // Scanned image placed at the area it was scanned from
        if let image = viewModel.previewImage {
            let imageArea = viewModel.lastScanArea ?? ScanArea()
            let scaleX = bedRect.width / ScanArea.bedWidth
            let scaleY = bedRect.height / ScanArea.bedHeight
            let imgRect = CGRect(
                x: bedRect.minX + imageArea.left * scaleX,
                y: bedRect.minY + imageArea.top * scaleY,
                width: imageArea.width * scaleX,
                height: imageArea.height * scaleY
            )
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imgRect.width, height: imgRect.height)
                .offset(x: imgRect.minX, y: imgRect.minY)
        }
    }

    // MARK: - Selection Overlay

    @ViewBuilder
    private func selectionOverlay(bedRect: CGRect) -> some View {
        let selRect = selectionRect(in: bedRect)

        // Dim area outside selection
        Path { path in
            path.addRect(bedRect)
            path.addRect(selRect)
        }
        .fill(Color.black.opacity(0.3), style: FillStyle(eoFill: true))
    }

    // MARK: - Selection Chrome

    @ViewBuilder
    private func selectionChrome(bedRect: CGRect) -> some View {
        let selRect = selectionRect(in: bedRect)

        // Dashed border
        Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))
            .foregroundColor(.accentColor)
            .frame(width: selRect.width, height: selRect.height)
            .offset(x: selRect.minX, y: selRect.minY)

        // Resize handles
        ForEach(HandlePosition.allCases, id: \.self) { handle in
            let pos = handlePoint(handle, in: selRect)
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 1.5))
                .frame(width: handleSize, height: handleSize)
                .offset(x: pos.x - handleSize / 2, y: pos.y - handleSize / 2)
        }
    }

    // MARK: - Geometry Helpers

    private func bedRect(in size: CGSize) -> CGRect {
        let padding: CGFloat = 24
        let available = CGSize(width: size.width - padding * 2, height: size.height - padding * 2)
        let scale = min(available.width / ScanArea.bedWidth, available.height / ScanArea.bedHeight)
        let bedW = ScanArea.bedWidth * scale
        let bedH = ScanArea.bedHeight * scale
        let x = (size.width - bedW) / 2
        let y = (size.height - bedH) / 2
        return CGRect(x: x, y: y, width: bedW, height: bedH)
    }

    private func selectionRect(in bedRect: CGRect) -> CGRect {
        let area = viewModel.settings.scanArea
        let scaleX = bedRect.width / ScanArea.bedWidth
        let scaleY = bedRect.height / ScanArea.bedHeight
        return CGRect(
            x: bedRect.minX + area.left * scaleX,
            y: bedRect.minY + area.top * scaleY,
            width: area.width * scaleX,
            height: area.height * scaleY
        )
    }

    private func mmFromPoint(_ point: CGPoint, in bedRect: CGRect) -> (x: Double, y: Double) {
        let x = (point.x - bedRect.minX) / bedRect.width * ScanArea.bedWidth
        let y = (point.y - bedRect.minY) / bedRect.height * ScanArea.bedHeight
        return (x: max(0, min(x, ScanArea.bedWidth)), y: max(0, min(y, ScanArea.bedHeight)))
    }

    // MARK: - Handles

    private enum HandlePosition: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
        case topCenter, bottomCenter, leftCenter, rightCenter
    }

    private func handlePoint(_ handle: HandlePosition, in rect: CGRect) -> CGPoint {
        switch handle {
        case .topLeft:      return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight:     return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:   return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:  return CGPoint(x: rect.maxX, y: rect.maxY)
        case .topCenter:    return CGPoint(x: rect.midX, y: rect.minY)
        case .bottomCenter: return CGPoint(x: rect.midX, y: rect.maxY)
        case .leftCenter:   return CGPoint(x: rect.minX, y: rect.midY)
        case .rightCenter:  return CGPoint(x: rect.maxX, y: rect.midY)
        }
    }

    private func hitTestHandle(at point: CGPoint, selRect: CGRect) -> HandlePosition? {
        let threshold: CGFloat = 12
        for handle in HandlePosition.allCases {
            let hp = handlePoint(handle, in: selRect)
            if abs(point.x - hp.x) < threshold && abs(point.y - hp.y) < threshold {
                return handle
            }
        }
        return nil
    }

    // MARK: - Drag

    private enum DragMode: Equatable {
        case none
        case draw
        case move
        case resize(HandlePosition)
    }

    private func dragGesture(bedRect: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragMode == .none {
                    let selRect = selectionRect(in: bedRect)
                    if let handle = hitTestHandle(at: value.startLocation, selRect: selRect) {
                        dragMode = .resize(handle)
                        dragStart = value.startLocation
                    } else if selRect.contains(value.startLocation) {
                        dragMode = .move
                        dragStart = value.startLocation
                    } else if bedRect.contains(value.startLocation) {
                        dragMode = .draw
                        dragStart = value.startLocation
                    }
                }

                switch dragMode {
                case .draw:
                    handleDraw(start: dragStart, current: value.location, bedRect: bedRect)
                case .move:
                    handleMove(translation: CGSize(
                        width: value.location.x - dragStart.x,
                        height: value.location.y - dragStart.y
                    ), bedRect: bedRect)
                    dragStart = value.location
                case .resize(let handle):
                    handleResize(handle: handle, current: value.location, bedRect: bedRect)
                case .none:
                    break
                }
            }
            .onEnded { _ in
                dragMode = .none
            }
    }

    private func handleDraw(start: CGPoint, current: CGPoint, bedRect: CGRect) {
        let s = mmFromPoint(start, in: bedRect)
        let c = mmFromPoint(current, in: bedRect)
        let left = min(s.x, c.x)
        let top = min(s.y, c.y)
        let right = max(s.x, c.x)
        let bottom = max(s.y, c.y)
        let minMM = minSelectionPx / bedRect.width * ScanArea.bedWidth
        viewModel.settings.scanArea = ScanArea(
            left: left,
            top: top,
            width: max(right - left, minMM),
            height: max(bottom - top, minMM)
        )
    }

    private func handleMove(translation: CGSize, bedRect: CGRect) {
        var area = viewModel.settings.scanArea
        let dx = translation.width / bedRect.width * ScanArea.bedWidth
        let dy = translation.height / bedRect.height * ScanArea.bedHeight
        area.left = max(0, min(area.left + dx, ScanArea.bedWidth - area.width))
        area.top = max(0, min(area.top + dy, ScanArea.bedHeight - area.height))
        viewModel.settings.scanArea = area
    }

    private func handleResize(handle: HandlePosition, current: CGPoint, bedRect: CGRect) {
        let mm = mmFromPoint(current, in: bedRect)
        var area = viewModel.settings.scanArea
        let minMM = minSelectionPx / bedRect.width * ScanArea.bedWidth

        switch handle {
        case .topLeft:
            let newLeft = min(mm.x, area.left + area.width - minMM)
            let newTop = min(mm.y, area.top + area.height - minMM)
            area.width += area.left - newLeft
            area.height += area.top - newTop
            area.left = newLeft
            area.top = newTop
        case .topRight:
            area.width = max(mm.x - area.left, minMM)
            let newTop = min(mm.y, area.top + area.height - minMM)
            area.height += area.top - newTop
            area.top = newTop
        case .bottomLeft:
            let newLeft = min(mm.x, area.left + area.width - minMM)
            area.width += area.left - newLeft
            area.left = newLeft
            area.height = max(mm.y - area.top, minMM)
        case .bottomRight:
            area.width = max(mm.x - area.left, minMM)
            area.height = max(mm.y - area.top, minMM)
        case .topCenter:
            let newTop = min(mm.y, area.top + area.height - minMM)
            area.height += area.top - newTop
            area.top = newTop
        case .bottomCenter:
            area.height = max(mm.y - area.top, minMM)
        case .leftCenter:
            let newLeft = min(mm.x, area.left + area.width - minMM)
            area.width += area.left - newLeft
            area.left = newLeft
        case .rightCenter:
            area.width = max(mm.x - area.left, minMM)
        }

        // Clamp to bed
        area.left = max(0, area.left)
        area.top = max(0, area.top)
        area.width = min(area.width, ScanArea.bedWidth - area.left)
        area.height = min(area.height, ScanArea.bedHeight - area.top)

        viewModel.settings.scanArea = area
    }
}
