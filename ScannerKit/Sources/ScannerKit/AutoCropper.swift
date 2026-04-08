import AppKit

public struct AutoCropper {
    /// Analyzes a preview image (75 DPI, full bed) to detect document boundaries.
    /// Returns a ScanArea in mm coordinates, or nil if no edges could be detected.
    ///
    /// Computes per-line average brightness, then scans inward from each edge
    /// to find the first line that differs from the scanner lid color.
    public static func detectDocumentBounds(in image: NSImage) -> ScanArea? {
        guard let bitmap = image.representations.first as? NSBitmapImageRep
                ?? image.tiffRepresentation.flatMap(NSBitmapImageRep.init),
              let ptr = bitmap.bitmapData else {
            return nil
        }

        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        let bpp = bitmap.bitsPerPixel / 8
        let rowBytes = bitmap.bytesPerRow
        guard width > 10, height > 10, bpp >= 3 else { return nil }

        // Compute average brightness for each row and column
        let rowAvgs = (0..<height).map { y in
            lineAvgBrightness(ptr: ptr, count: width, stride: bpp, offset: y * rowBytes)
        }
        let colAvgs = (0..<width).map { x in
            lineAvgBrightness(ptr: ptr, count: height, stride: rowBytes, offset: x * bpp)
        }

        // Determine lid brightness from the bottom-right corner region,
        // which is least likely to be covered by a document (documents are
        // placed at the top-left corner guides).
        let cornerW = max(5, width / 8)
        let cornerH = max(5, height / 8)
        let lidBrightness = medianOf(rowAvgs.suffix(cornerH), colAvgs.suffix(cornerW))

        let transitionThreshold = 15.0

        // Scan inward from each edge to find document boundaries.
        // Skip a small border margin (scanner produces dark edges).
        let topPx = findDocumentEdge(values: rowAvgs, lidValue: lidBrightness,
                                     threshold: transitionThreshold, fromEnd: false)
        let bottomPx = findDocumentEdge(values: rowAvgs, lidValue: lidBrightness,
                                        threshold: transitionThreshold, fromEnd: true)
        let leftPx = findDocumentEdge(values: colAvgs, lidValue: lidBrightness,
                                      threshold: transitionThreshold, fromEnd: false)
        let rightPx = findDocumentEdge(values: colAvgs, lidValue: lidBrightness,
                                       threshold: transitionThreshold, fromEnd: true)

        guard topPx < bottomPx, leftPx < rightPx else { return nil }

        // Convert pixels to mm (preview is 75 DPI)
        let pixelsPerMM = 75.0 / 25.4
        let marginMM = 2.0

        let left = max(0, Double(leftPx) / pixelsPerMM - marginMM)
        let top = max(0, Double(topPx) / pixelsPerMM - marginMM)
        let right = min(ScanArea.bedWidth, Double(rightPx) / pixelsPerMM + marginMM)
        let bottom = min(ScanArea.bedHeight, Double(bottomPx) / pixelsPerMM + marginMM)

        let area = ScanArea(left: left, top: top, width: right - left, height: bottom - top)

        // Only return if we cropped more than 1mm on any side
        if left > 1 || top > 1 ||
            (ScanArea.bedWidth - right) > 1 ||
            (ScanArea.bedHeight - bottom) > 1 {
            return area
        }

        return nil
    }

    /// Average brightness (0-255) for a line of pixels.
    private static func lineAvgBrightness(
        ptr: UnsafeMutablePointer<UInt8>,
        count: Int, stride strideBytes: Int, offset: Int
    ) -> Double {
        let step = max(1, count / 80)
        var sum: UInt64 = 0
        var n: UInt64 = 0
        var i = 0
        while i < count {
            let base = offset + i * strideBytes
            sum += UInt64(ptr[base]) + UInt64(ptr[base + 1]) + UInt64(ptr[base + 2])
            n += 1
            i += step
        }
        guard n > 0 else { return 0 }
        return Double(sum) / Double(n * 3)
    }

    /// Scan inward from one edge, skipping border artifacts, and return the first
    /// line whose brightness differs from the lid. If the document extends all the
    /// way to the edge, returns the margin index (document flush with edge).
    private static func findDocumentEdge(
        values: [Double], lidValue: Double,
        threshold: Double, fromEnd: Bool
    ) -> Int {
        let margin = max(3, values.count / 50)

        let range: StrideTo<Int> = fromEnd
            ? stride(from: values.count - 1 - margin, to: margin - 1, by: -1)
            : stride(from: margin, to: values.count - margin, by: 1)

        for i in range {
            if abs(values[i] - lidValue) > threshold {
                return i
            }
        }

        return fromEnd ? (values.count - 1 - margin) : margin
    }

    /// Median of combined values from two array slices.
    private static func medianOf(_ a: ArraySlice<Double>, _ b: ArraySlice<Double>) -> Double {
        var combined = Array(a)
        combined.append(contentsOf: b)
        combined.sort()
        guard !combined.isEmpty else { return 128 }
        return combined[combined.count / 2]
    }
}
