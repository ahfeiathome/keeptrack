import Foundation
import Vision
import UIKit

// MARK: - Structured OCR output
struct OCRResult {
    var storeName: String?
    var purchaseDate: Date?
    var items: [OCRLineItem]
    var total: Decimal?
    var rawText: String
    var confidence: Float  // 0.0–1.0 overall confidence

    var isLowConfidence: Bool { confidence < 0.5 }
}

struct OCRLineItem {
    var name: String
    var price: Decimal?
}

// MARK: - OCR service using Vision framework
final class OCRService {

    // MARK: - Public API
    static func recognize(imageData: Data) async -> OCRResult {
        guard let image = UIImage(data: imageData),
              let cgImage = image.cgImage else {
            return OCRResult(items: [], rawText: "", confidence: 0)
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                guard error == nil,
                      let observations = req.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: OCRResult(items: [], rawText: "", confidence: 0))
                    return
                }
                let result = Self.parse(observations: observations)
                continuation.resume(returning: result)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Parse observations into structured result
    private static func parse(observations: [VNRecognizedTextObservation]) -> OCRResult {
        var lines: [String] = []
        var totalConfidence: Float = 0

        for obs in observations {
            guard let top = obs.topCandidates(1).first else { continue }
            lines.append(top.string)
            totalConfidence += top.confidence
        }

        let avgConfidence = observations.isEmpty ? 0 : totalConfidence / Float(observations.count)
        let rawText = lines.joined(separator: "\n")

        let storeName = extractStoreName(from: lines)
        let purchaseDate = extractDate(from: lines)
        let (items, total) = extractItemsAndTotal(from: lines)

        return OCRResult(
            storeName: storeName,
            purchaseDate: purchaseDate,
            items: items,
            total: total,
            rawText: rawText,
            confidence: avgConfidence
        )
    }

    // MARK: - Store name heuristic: largest text near top of receipt
    private static func extractStoreName(from lines: [String]) -> String? {
        // First non-empty line that doesn't look like an address or date
        let candidates = lines.prefix(5).filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.count > 2 else { return false }
            // Skip lines that look like addresses or phone numbers
            let addressPattern = #"^\d+\s+\w+"#
            let phonePattern = #"^\(?\d{3}\)?[\s\-]\d{3}"#
            if trimmed.range(of: addressPattern, options: .regularExpression) != nil { return false }
            if trimmed.range(of: phonePattern, options: .regularExpression) != nil { return false }
            return true
        }
        return candidates.first.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Date extraction
    private static func extractDate(from lines: [String]) -> Date? {
        let formatters: [DateFormatter] = [
            makeFormatter("MM/dd/yyyy"),
            makeFormatter("MM/dd/yy"),
            makeFormatter("MM-dd-yyyy"),
            makeFormatter("yyyy-MM-dd"),
            makeFormatter("MMM dd, yyyy"),
            makeFormatter("MMMM dd, yyyy")
        ]

        let datePattern = #"(\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}|\w+ \d{1,2},? \d{4})"#
        for line in lines {
            if let range = line.range(of: datePattern, options: .regularExpression) {
                let candidate = String(line[range])
                for formatter in formatters {
                    if let date = formatter.date(from: candidate) { return date }
                }
            }
        }
        return nil
    }

    private static func makeFormatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        return f
    }

    // MARK: - Item and total extraction
    private static func extractItemsAndTotal(from lines: [String]) -> ([OCRLineItem], Decimal?) {
        var items: [OCRLineItem] = []
        var total: Decimal?

        // Price pattern: optional $ followed by digits.digits
        let pricePattern = #"\$?\s*(\d+\.\d{2})"#
        let totalKeywords = ["total", "subtotal", "amount due", "balance"]

        for line in lines {
            let lower = line.lowercased()
            let isTotalLine = totalKeywords.contains { lower.contains($0) }

            if let match = line.range(of: pricePattern, options: .regularExpression) {
                let priceStr = String(line[match])
                    .replacingOccurrences(of: "$", with: "")
                    .replacingOccurrences(of: " ", with: "")
                if let price = Decimal(string: priceStr) {
                    if isTotalLine {
                        // Keep the highest total-line value
                        if total == nil || price > total! { total = price }
                    } else {
                        // Extract item name: text before the price
                        let namePart = line[line.startIndex..<match.lowerBound]
                            .trimmingCharacters(in: .whitespaces)
                        if !namePart.isEmpty {
                            items.append(OCRLineItem(name: namePart, price: price))
                        }
                    }
                }
            }
        }

        return (items, total)
    }
}
