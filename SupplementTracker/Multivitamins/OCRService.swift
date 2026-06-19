import Foundation
import Vision
import UIKit

enum OCRError: LocalizedError {
    case invalidImage
    case noText

    var errorDescription: String? {
        switch self {
        case .invalidImage: "That image couldn't be read."
        case .noText: "No text was found on the label."
        }
    }
}

enum OCRService {
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = [Locale.Language(identifier: "en-US")]

        let observations = try await request.perform(on: cgImage)
        let text = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")

        guard !text.isEmpty else { throw OCRError.noText }
        return text
    }
}
