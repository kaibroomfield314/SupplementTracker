import Foundation
import FoundationModels

struct ExtractedIngredient: Codable, Hashable {
    var name: String
    var amount: Double
    var unit: String
}

enum IngredientExtractor {
    /// Asks the on-device Apple Intelligence model to parse a Supplement Facts blob
    /// into a structured ingredient list.
    static func extract(from ocrText: String) async throws -> [ExtractedIngredient] {
        let instructions = """
        You parse Supplement Facts panels from OCR text.
        Output: ONLY a JSON array of objects. No markdown fences. No commentary.

        Each object has exactly three keys:
        - name (String): the ingredient name, e.g. "Vitamin D3 (as cholecalciferol)", "Magnesium Citrate", "Zinc (as zinc picolinate)"
        - amount (Number): the per-serving DOSE in absolute units. Never use the % Daily Value column.
        - unit (String): one of µg, mg, g, IU, mL, billion CFU

        Critical disambiguation:
        - Each row typically reads: "Ingredient Name   <amount> <unit>   <DV%>". The DV column (often ending in %) is NOT the dose.
        - "mcg" means "µg" — always convert.
        - If a row lists both µg/mcg AND IU on the same line (common for Vitamin D, A, E), use µg.
        - Skip headers: "Supplement Facts", "Amount Per Serving", "% Daily Value", "Serving Size", "Servings Per Container".
        - Skip footnote rows: "Daily Value not established", "† Daily Value", "** Percent Daily Values".
        - Skip "Other Ingredients" / "Inactive Ingredients" sections — those are excipients.
        - Skip allergen, manufacturer, marketing, and storage text.

        Examples:
        Input row: "Vitamin D3 (as cholecalciferol)   25 mcg   125%"
        Output:    {"name":"Vitamin D3 (as cholecalciferol)","amount":25,"unit":"µg"}

        Input row: "Magnesium (as magnesium citrate)   200 mg   48%"
        Output:    {"name":"Magnesium (as magnesium citrate)","amount":200,"unit":"mg"}

        Input row: "Vitamin A (as beta-carotene)   900 mcg   100% 3000 IU"
        Output:    {"name":"Vitamin A (as beta-carotene)","amount":900,"unit":"µg"}

        Input row: "Lactobacillus blend   10 Billion CFU   †"
        Output:    {"name":"Lactobacillus blend","amount":10,"unit":"billion CFU"}
        """

        let session = LanguageModelSession(instructions: instructions)
        let response = try await session.respond(to: ocrText)
        return try decodeJSON(response.content)
    }

    static func decodeJSON(_ raw: String) throws -> [ExtractedIngredient] {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = cleaned.firstIndex(of: "["),
           let end = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[start...end])
        }

        guard let data = cleaned.data(using: .utf8) else {
            throw ExtractorError.decodingFailed("empty data")
        }
        do {
            return try JSONDecoder().decode([ExtractedIngredient].self, from: data)
        } catch {
            throw ExtractorError.decodingFailed(error.localizedDescription)
        }
    }
}

enum ExtractorError: LocalizedError {
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .decodingFailed(let why): "Couldn't parse the model output (\(why))."
        }
    }
}
