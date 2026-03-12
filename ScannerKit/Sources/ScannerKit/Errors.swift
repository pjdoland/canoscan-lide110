import Foundation

public enum ScanError: LocalizedError {
    case saneNotInstalled
    case scannerNotFound
    case scanInProgress
    case processFailure(exitCode: Int32, stderr: String)
    case noImageData
    case imageConversionFailed(String)
    case exportFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .saneNotInstalled:
            return "SANE backends not found. Install with: brew install sane-backends"
        case .scannerNotFound:
            return "CanoScan LiDE 110 not detected. Check USB connection."
        case .scanInProgress:
            return "A scan is already in progress."
        case .processFailure(let code, let stderr):
            return "scanimage failed (exit \(code)): \(stderr)"
        case .noImageData:
            return "Scanner returned no image data."
        case .imageConversionFailed(let detail):
            return "Image conversion failed: \(detail)"
        case .exportFailed(let detail):
            return "Export failed: \(detail)"
        case .cancelled:
            return "Scan was cancelled."
        }
    }
}
