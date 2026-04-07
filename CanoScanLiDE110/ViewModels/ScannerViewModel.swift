import AppKit
import PDFKit
import ScannerKit
import SwiftUI
import UniformTypeIdentifiers

struct ScannedPage: Identifiable {
    let id = UUID()
    let tiffData: Data
    let thumbnail: NSImage
    let scanArea: ScanArea

    init(tiffData: Data, scanArea: ScanArea) throws {
        self.tiffData = tiffData
        self.scanArea = scanArea
        guard let image = NSImage(data: tiffData) else {
            throw ScanError.imageConversionFailed("Cannot create thumbnail")
        }
        self.thumbnail = image
    }
}

enum AppState: Equatable {
    case idle
    case scanning
    case error(String)

    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.scanning, .scanning): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

@MainActor
final class ScannerViewModel: ObservableObject {
    @Published var state: AppState = .idle
    @Published var pages: [ScannedPage] = []
    @Published var selectedPageID: UUID?
    @Published var settings = ScanSettings()
    @Published var scannerDetected = false
    @Published var saneInstalled = false
    @Published var previewNSImage: NSImage?
    @Published var isPreviewing = false

    private let scanner = ScannerManager()
    private let converter = ImageConverter()

    var selectedPage: ScannedPage? {
        guard let id = selectedPageID else { return pages.last }
        return pages.first { $0.id == id }
    }

    var selectedPageImage: NSImage? {
        selectedPage?.thumbnail
    }

    var lastScanArea: ScanArea? {
        selectedPage?.scanArea
    }

    var canScan: Bool {
        state != .scanning && !isPreviewing && saneInstalled && scannerDetected
    }

    // MARK: - Scanner Detection

    func checkEnvironment() async {
        saneInstalled = SANEPathResolver.isInstalled
        guard saneInstalled else { return }

        do {
            scannerDetected = try await scanner.detectScanner()
        } catch {
            scannerDetected = false
        }
    }

    // MARK: - Scanning

    func scan() async {
        guard canScan else { return }
        state = .scanning
        previewNSImage = nil

        do {
            let scanArea = settings.scanArea
            let tiffData = try await scanner.scan(settings: settings)
            let page = try ScannedPage(tiffData: tiffData, scanArea: scanArea)
            pages.append(page)
            selectedPageID = page.id
            state = .idle
        } catch is CancellationError {
            state = .idle
        } catch let error as ScanError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func cancelScan() async {
        await scanner.cancelScan()
        state = .idle
    }

    // MARK: - Preview

    func scanPreview() async {
        guard canScan else { return }
        isPreviewing = true
        defer { isPreviewing = false }
        do {
            let tiffData = try await scanner.preview()
            previewNSImage = NSImage(data: tiffData)
        } catch is CancellationError {
            // Cancelled — no action needed
        } catch {
            state = .error("Preview failed: \(error.localizedDescription)")
        }
    }

    func autoCropFromPreview() {
        guard let image = previewNSImage else { return }
        if let area = AutoCropper.detectDocumentBounds(in: image) {
            settings.scanArea = area
        }
    }

    // MARK: - Page Management

    func movePage(from source: IndexSet, to destination: Int) {
        pages.move(fromOffsets: source, toOffset: destination)
    }

    func removePage(_ page: ScannedPage) {
        pages.removeAll { $0.id == page.id }
        if selectedPageID == page.id {
            selectedPageID = pages.last?.id
        }
    }

    func removeAllPages() {
        pages.removeAll()
        selectedPageID = nil
    }

    // MARK: - Export

    func exportCurrentPage() async {
        guard let page = selectedPage else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [utType(for: settings.outputFormat)]
        panel.nameFieldStringValue = "Scan.\(settings.outputFormat.fileExtension)"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try converter.convert(page.tiffData, to: settings.outputFormat)
            try data.write(to: url)
        } catch {
            state = .error("Export failed: \(error.localizedDescription)")
        }
    }

    func exportAllAsPDF() async {
        guard !pages.isEmpty else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Scanned Document.pdf"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let tiffPages = pages.map(\.tiffData)
            let pdfData = try converter.mergeToPDF(tiffPages)
            try pdfData.write(to: url)
        } catch {
            state = .error("PDF export failed: \(error.localizedDescription)")
        }
    }

    private func utType(for format: OutputFormat) -> UTType {
        switch format {
        case .png: return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        case .pdf: return .pdf
        }
    }

    // MARK: - Scan Area

    var currentPreset: ScanAreaPreset {
        ScanAreaPreset.matching(settings.scanArea)
    }

    func applyPreset(_ preset: ScanAreaPreset) {
        if let area = preset.scanArea {
            settings.scanArea = area
        }
    }

    func dismissError() {
        state = .idle
    }
}
