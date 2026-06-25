import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class DailySummaryService {
    static let shared = DailySummaryService()

    private(set) var summary: String?
    private(set) var isGenerating = false

    private let defaults = UserDefaults.standard

    private var cacheKey: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let day = Calendar.current.startOfDay(for: Date())
        return "aiSummary.\(formatter.string(from: day))"
    }

    func load(metrics: DashboardMetrics) async {
        if let cached = defaults.string(forKey: cacheKey) {
            summary = cached
            return
        }
        await generate(metrics: metrics)
    }

    func refresh(metrics: DashboardMetrics) async {
        defaults.removeObject(forKey: cacheKey)
        summary = nil
        await generate(metrics: metrics)
    }

    private func generate(metrics: DashboardMetrics) async {
        isGenerating = true
        defer { isGenerating = false }

        let userPrompt = buildPrompt(metrics: metrics)
        let instructions = """
            You are a clinical health log. \
            Output exactly one sentence, maximum 80 characters. \
            Use specific numbers from the data. \
            No motivational language. No second person. \
            Use semicolons to join two facts. \
            Example: "Adherence 71%; D3 streak 12d"
            """

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: userPrompt)
            var result = response.content
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            result = truncated(result)
            summary = result
            defaults.set(result, forKey: cacheKey)
        } catch {
            let fallback = buildFallback(metrics: metrics)
            summary = fallback
            defaults.set(fallback, forKey: cacheKey)
        }
    }

    private func buildPrompt(metrics: DashboardMetrics) -> String {
        let pct = metrics.typicalCount > 0
            ? Int(metrics.completionProgress * 100)
            : 0
        var parts = ["taken=\(metrics.todayUniqueCount)/\(metrics.typicalCount) (\(pct)%)"]
        if let streak = metrics.topStreak {
            let short = streak.supplementName.components(separatedBy: " ").first ?? streak.supplementName
            parts.append("streak=\(short) \(streak.days)d")
        }
        if let delta = metrics.weekDeltaPercent {
            let sign = delta >= 0 ? "+" : ""
            parts.append("week_vs_prev=\(sign)\(Int(delta * 100))%")
        }
        return parts.joined(separator: "; ")
    }

    private func truncated(_ s: String) -> String {
        guard s.count > 80 else { return s }
        let prefix = String(s.prefix(80))
        if let range = prefix.range(of: ";", options: .backwards) {
            return String(prefix[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
        }
        return prefix
    }

    private func buildFallback(metrics: DashboardMetrics) -> String {
        let pct = metrics.typicalCount > 0
            ? Int(metrics.completionProgress * 100)
            : 0
        if let streak = metrics.topStreak {
            let short = streak.supplementName.components(separatedBy: " ").first ?? streak.supplementName
            return "Adherence \(pct)%; \(short) streak \(streak.days)d"
        }
        return "Adherence \(pct)%; \(metrics.todayUniqueCount) of \(metrics.typicalCount) taken"
    }
}
