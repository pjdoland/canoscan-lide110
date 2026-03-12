import Foundation

public struct SANEPathResolver: Sendable {
    public static func scanimagePath() -> String? {
        // Apple Silicon Homebrew
        let armPath = "/opt/homebrew/bin/scanimage"
        if FileManager.default.isExecutableFile(atPath: armPath) {
            return armPath
        }
        // Intel Homebrew
        let intelPath = "/usr/local/bin/scanimage"
        if FileManager.default.isExecutableFile(atPath: intelPath) {
            return intelPath
        }
        return nil
    }

    public static var isInstalled: Bool {
        scanimagePath() != nil
    }
}
