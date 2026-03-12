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

public struct ScanSettings: Sendable {
    public var resolution: Int
    public var colorMode: ColorMode
    public var outputFormat: OutputFormat

    public static let availableResolutions = [75, 150, 300, 600, 1200, 2400]

    public init(
        resolution: Int = 300,
        colorMode: ColorMode = .color,
        outputFormat: OutputFormat = .png
    ) {
        self.resolution = resolution
        self.colorMode = colorMode
        self.outputFormat = outputFormat
    }
}
