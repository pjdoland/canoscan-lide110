import Foundation

public enum ColorMode: String, CaseIterable, Identifiable, Sendable {
    case color = "Color"
    case gray = "Gray"
    case lineart = "Lineart"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .color: return "Color"
        case .gray: return "Grayscale"
        case .lineart: return "Black & White"
        }
    }
}

public enum OutputFormat: String, CaseIterable, Identifiable, Sendable {
    case png = "png"
    case jpeg = "jpeg"
    case tiff = "tiff"
    case pdf = "pdf"

    public var id: String { rawValue }

    public var displayName: String { rawValue.uppercased() }

    public var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        case .tiff: return "tiff"
        case .pdf: return "pdf"
        }
    }
}

public struct ScanArea: Equatable, Sendable {
    public var left: Double
    public var top: Double
    public var width: Double
    public var height: Double

    public init(left: Double = 0, top: Double = 0, width: Double = ScanArea.bedWidth, height: Double = ScanArea.bedHeight) {
        self.left = left
        self.top = top
        self.width = width
        self.height = height
    }

    public static let bedWidth: Double = 215.9
    public static let bedHeight: Double = 297.5
    public static let bedAspectRatio: Double = bedWidth / bedHeight

    public var isFullPage: Bool {
        left == 0 && top == 0 && width == ScanArea.bedWidth && height == ScanArea.bedHeight
    }
}

public enum ScanAreaPreset: String, CaseIterable, Identifiable, Sendable {
    case fullPage = "Full Page"
    case letter = "Letter"
    case a4 = "A4"
    case photo4x6 = "4×6 Photo"
    case photo5x7 = "5×7 Photo"
    case custom = "Custom"

    public var id: String { rawValue }

    public var scanArea: ScanArea? {
        switch self {
        case .fullPage:
            return ScanArea()
        case .letter:
            return ScanArea(left: 0, top: 0, width: 215.9, height: 279.4)
        case .a4:
            return ScanArea(left: 0, top: 0, width: 210, height: 297)
        case .photo4x6:
            return ScanArea(left: 0, top: 0, width: 101.6, height: 152.4)
        case .photo5x7:
            return ScanArea(left: 0, top: 0, width: 127, height: 177.8)
        case .custom:
            return nil
        }
    }

    public static func matching(_ area: ScanArea) -> ScanAreaPreset {
        for preset in allCases where preset != .custom {
            if let presetArea = preset.scanArea,
               abs(presetArea.left - area.left) < 0.1,
               abs(presetArea.top - area.top) < 0.1,
               abs(presetArea.width - area.width) < 0.1,
               abs(presetArea.height - area.height) < 0.1 {
                return preset
            }
        }
        return .custom
    }
}

public struct ScanSettings: Sendable {
    public var resolution: Int
    public var colorMode: ColorMode
    public var outputFormat: OutputFormat
    public var scanArea: ScanArea

    public static let availableResolutions = [75, 150, 300, 600, 1200, 2400]

    public init(
        resolution: Int = 300,
        colorMode: ColorMode = .color,
        outputFormat: OutputFormat = .png,
        scanArea: ScanArea = ScanArea()
    ) {
        self.resolution = resolution
        self.colorMode = colorMode
        self.outputFormat = outputFormat
        self.scanArea = scanArea
    }
}
