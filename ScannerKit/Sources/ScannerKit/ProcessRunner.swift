import Foundation

public struct ProcessResult: Sendable {
    public let exitCode: Int32
    public let stdout: Data
    public let stderr: String
}

public actor ProcessRunner {
    private var runningProcess: Process?

    public init() {}

    public func run(
        executablePath: String,
        arguments: [String],
        environment: [String: String]? = nil
    ) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        if let environment {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        self.runningProcess = process

        try process.run()

        // Read pipes on background threads BEFORE waiting for termination.
        // If we wait until after termination, large stdout (like a TIFF image)
        // fills the pipe buffer (~64KB), the process blocks on write, and
        // the termination handler never fires — a classic deadlock.
        let stdoutData: Data = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                continuation.resume(returning: data)
            }
        }

        let stderrData: Data = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let data = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                continuation.resume(returning: data)
            }
        }

        // Now wait for the process to finish.
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            if !process.isRunning {
                continuation.resume()
            } else {
                process.terminationHandler = { _ in
                    continuation.resume()
                }
            }
        }

        self.runningProcess = nil

        let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: stdoutData,
            stderr: stderrString
        )
    }

    public func cancel() {
        runningProcess?.terminate()
        runningProcess = nil
    }
}
