import AppKit
import PDFKit
import UniformTypeIdentifiers

public struct ImageConverter {
    public init() {}

    /// Converts raw TIFF data to an NSImage.
    public func tiffToImage(_ tiffData: Data) throws -> NSImage {
        guard let image = NSImage(data: tiffData), image.isValid else {
            throw ScanError.imageConversionFailed("Invalid TIFF data")
        }
        return image
    }

    /// Converts raw TIFF data to PNG.
    public func tiffToPNG(_ tiffData: Data) throws -> Data {
        let image = try tiffToImage(tiffData)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw ScanError.imageConversionFailed("PNG encoding failed")
        }
        return png
    }

    /// Converts raw TIFF data to JPEG with the given quality (0.0–1.0).
    public func tiffToJPEG(_ tiffData: Data, quality: Double = 0.85) throws -> Data {
        let image = try tiffToImage(tiffData)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            throw ScanError.imageConversionFailed("JPEG encoding failed")
        }
        return jpeg
    }

    /// Creates a single-page PDF from TIFF data.
    public func tiffToPDF(_ tiffData: Data) throws -> PDFDocument {
        let image = try tiffToImage(tiffData)
        let pdfPage = PDFPage(image: image)
        guard let page = pdfPage else {
            throw ScanError.imageConversionFailed("PDF page creation failed")
        }
        let doc = PDFDocument()
        doc.insert(page, at: 0)
        return doc
    }

    /// Merges multiple TIFF pages into a single PDF document.
    public func mergeToPDF(_ pages: [Data]) throws -> Data {
        let doc = PDFDocument()
        for (index, tiffData) in pages.enumerated() {
            let image = try tiffToImage(tiffData)
            guard let page = PDFPage(image: image) else {
                throw ScanError.imageConversionFailed("PDF page \(index + 1) creation failed")
            }
            doc.insert(page, at: index)
        }
        guard let pdfData = doc.dataRepresentation() else {
            throw ScanError.exportFailed("PDF data generation failed")
        }
        return pdfData
    }

    /// Converts TIFF data to the specified output format.
    public func convert(_ tiffData: Data, to format: OutputFormat) throws -> Data {
        switch format {
        case .tiff:
            return tiffData
        case .png:
            return try tiffToPNG(tiffData)
        case .jpeg:
            return try tiffToJPEG(tiffData)
        case .pdf:
            let doc = try tiffToPDF(tiffData)
            guard let data = doc.dataRepresentation() else {
                throw ScanError.exportFailed("PDF data generation failed")
            }
            return data
        }
    }
}
