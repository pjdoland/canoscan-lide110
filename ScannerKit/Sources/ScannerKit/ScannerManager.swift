import Foundation

public actor ScannerManager {
    private let runner = ProcessRunner()

    public init() {}

    /// Checks if the CanoScan LiDE 110 is detected by SANE.
    public func detectScanner() async throws -> Bool {
        guard let path = SANEPathResolver.scanimagePath() else {
            throw ScanError.saneNotInstalled
        }

        let result = try await runner.run(
            executablePath: path,
            arguments: ["-L"]
        )

        // scanimage -L outputs lines like:
        // device `genesys:libusb:001:004' is a Canon LiDE 110 flatbed scanner
        let output = String(data: result.stdout, encoding: .utf8) ?? ""
        return output.contains("LiDE 110") || output.contains("04A9:1909")
    }

    /// Performs a scan and returns raw TIFF data.
    public func scan(settings: ScanSettings) async throws -> Data {
        guard let path = SANEPathResolver.scanimagePath() else {
            throw ScanError.saneNotInstalled
        }

        var arguments = [
            "--format=tiff",
            "--resolution=\(settings.resolution)",
            "--mode=\(settings.colorMode.rawValue)",
        ]

        let area = settings.scanArea
        if !area.isFullPage {
            arguments.append(contentsOf: [
                "-l", String(format: "%.1f", area.left),
                "-t", String(format: "%.1f", area.top),
                "-x", String(format: "%.1f", area.width),
                "-y", String(format: "%.1f", area.height),
            ])
        }

        let result = try await runner.run(
            executablePath: path,
            arguments: arguments
        )

        guard result.exitCode == 0 else {
            if result.stderr.contains("no SANE devices found") ||
               result.stderr.contains("device not found") {
                throw ScanError.scannerNotFound
            }
            throw ScanError.processFailure(exitCode: result.exitCode, stderr: result.stderr)
        }

        guard !result.stdout.isEmpty else {
            throw ScanError.noImageData
        }

        return result.stdout
    }

    /// Cancels any running scan process.
    public func cancelScan() async {
        await runner.cancel()
    }
}
