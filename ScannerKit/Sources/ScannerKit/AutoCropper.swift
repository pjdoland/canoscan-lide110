import AppKit

public struct AutoCropper {
    /// Analyzes a preview image (75 DPI, full bed) to detect document boundaries.
    /// Returns a ScanArea in mm coordinates, or nil if no clear document edges found.
    public static func detectDocumentBounds(
        in image: NSImage,
        brightnessThreshold: UInt32 = 230,
        edgeFraction: Double = 0.20
    ) -> ScanArea? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let ptr = bitmap.bitmapData else {
            return nil
        }

        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        let bpp = bitmap.bitsPerPixel / 8
        let rowBytes = bitmap.bytesPerRow
        guard width > 0, height > 0, bpp >= 3 else { return nil }

        // Scan from top
        var topPx = 0
        for y in 0..<height {
            if lineHasContent(ptr: ptr, count: width, stride: bpp, offset: y * rowBytes,
                              threshold: brightnessThreshold, fraction: edgeFraction) {
                topPx = y
                break
            }
        }

        // Scan from bottom
        var bottomPx = height - 1
        for y in stride(from: height - 1, through: 0, by: -1) {
            if lineHasContent(ptr: ptr, count: width, stride: bpp, offset: y * rowBytes,
                              threshold: brightnessThreshold, fraction: edgeFraction) {
                bottomPx = y
                break
            }
        }

        // Scan from left
        var leftPx = 0
        for x in 0..<width {
            if lineHasContent(ptr: ptr, count: height, stride: rowBytes, offset: x * bpp,
                              threshold: brightnessThreshold, fraction: edgeFraction) {
                leftPx = x
                break
            }
        }

        // Scan from right
        var rightPx = width - 1
        for x in stride(from: width - 1, through: 0, by: -1) {
            if lineHasContent(ptr: ptr, count: height, stride: rowBytes, offset: x * bpp,
                              threshold: brightnessThreshold, fraction: edgeFraction) {
                rightPx = x
                break
            }
        }

        // If detected area is basically the whole image, return nil
        if topPx <= 2 && leftPx <= 2 && bottomPx >= height - 3 && rightPx >= width - 3 {
            return nil
        }

        // Convert pixels to mm (preview is 75 DPI)
        let pixelsPerMM = 75.0 / 25.4
        let marginMM = 2.0

        let left = max(0, Double(leftPx) / pixelsPerMM - marginMM)
        let top = max(0, Double(topPx) / pixelsPerMM - marginMM)
        let right = min(ScanArea.bedWidth, Double(rightPx) / pixelsPerMM + marginMM)
        let bottom = min(ScanArea.bedHeight, Double(bottomPx) / pixelsPerMM + marginMM)

        return ScanArea(
            left: left,
            top: top,
            width: right - left,
            height: bottom - top
        )
    }

    /// Checks whether a line (row or column) has enough dark pixels to indicate content.
    /// Works for both rows and columns by varying stride and offset:
    ///   Row: offset = y * rowBytes, stride = bytesPerPixel, count = width
    ///   Col: offset = x * bytesPerPixel, stride = rowBytes, count = height
    private static func lineHasContent(
        ptr: UnsafeMutablePointer<UInt8>,
        count: Int,
        stride strideBytes: Int,
        offset: Int,
        threshold: UInt32,
        fraction: Double
    ) -> Bool {
        let step = max(1, count / 100)
        var darkCount = 0
        var samples = 0
        var i = 0
        while i < count {
            let base = offset + i * strideBytes
            let brightness = (UInt32(ptr[base]) + UInt32(ptr[base + 1]) + UInt32(ptr[base + 2])) / 3
            if brightness < threshold {
                darkCount += 1
            }
            samples += 1
            i += step
        }
        guard samples > 0 else { return false }
        return Double(darkCount) / Double(samples) >= fraction
    }
}
