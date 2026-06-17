import Foundation
import SwiftData

struct ExportPayload: Codable {
    let exportedAt: Date
    let version: Int
    let supplements: [SupplementDTO]
    let intakes: [IntakeDTO]
    let bloodTests: [BloodTestDTO]

    struct SupplementDTO: Codable {
        let name: String
        let brand: String
        let category: String
        let defaultDose: Double
        let unit: String
        let notes: String
        let createdAt: Date
    }

    struct IntakeDTO: Codable {
        let date: Date
        let amount: Double
        let unit: String
        let notes: String
        let supplementName: String?
        let supplementBrand: String?
    }

    struct BloodTestDTO: Codable {
        let date: Date
        let lab: String
        let notes: String
        let readings: [ReadingDTO]

        struct ReadingDTO: Codable {
            let name: String
            let value: Double
            let unit: String
            let referenceLow: Double
            let referenceHigh: Double
        }
    }
}

enum ExportService {
    static func makeJSON(context: ModelContext) throws -> URL {
        let supplements = try context.fetch(FetchDescriptor<Supplement>())
        let intakes = try context.fetch(FetchDescriptor<SupplementIntake>())
        let tests = try context.fetch(FetchDescriptor<BloodTest>(
            sortBy: [SortDescriptor(\.date)]
        ))

        let payload = ExportPayload(
            exportedAt: .now,
            version: 1,
            supplements: supplements.map {
                .init(
                    name: $0.name,
                    brand: $0.brand,
                    category: $0.categoryRaw,
                    defaultDose: $0.defaultDose,
                    unit: $0.unit,
                    notes: $0.notes,
                    createdAt: $0.createdAt
                )
            },
            intakes: intakes.map {
                .init(
                    date: $0.date,
                    amount: $0.amount,
                    unit: $0.unit,
                    notes: $0.notes,
                    supplementName: $0.supplement?.name,
                    supplementBrand: $0.supplement?.brand
                )
            },
            bloodTests: tests.map { test in
                .init(
                    date: test.date,
                    lab: test.lab,
                    notes: test.notes,
                    readings: (test.readings ?? []).map {
                        .init(
                            name: $0.name,
                            value: $0.value,
                            unit: $0.unit,
                            referenceLow: $0.referenceLow,
                            referenceHigh: $0.referenceHigh
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(payload)
        let url = tempURL(prefix: "supplement-tracker", ext: "json")
        try data.write(to: url, options: .atomic)
        return url
    }

    static func makeBloodMarkersCSV(context: ModelContext) throws -> URL {
        let readings = try context.fetch(FetchDescriptor<BloodMarkerReading>(
            sortBy: [SortDescriptor(\.date), SortDescriptor(\.name)]
        ))

        var csv = "Date,Marker,Value,Unit,Reference Low,Reference High,Status,Lab\n"
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]

        for r in readings {
            let date = iso.string(from: r.date)
            let lab = r.test?.lab ?? ""
            let status: String = switch r.status {
                case .low: "low"
                case .normal: "normal"
                case .high: "high"
                case .unknown: ""
            }
            csv += "\(date),\(csvEscape(r.name)),\(r.value),\(csvEscape(r.unit)),\(r.referenceLow),\(r.referenceHigh),\(status),\(csvEscape(lab))\n"
        }

        let url = tempURL(prefix: "blood-markers", ext: "csv")
        try csv.data(using: .utf8)!.write(to: url, options: .atomic)
        return url
    }

    static func makeIntakesCSV(context: ModelContext) throws -> URL {
        let intakes = try context.fetch(FetchDescriptor<SupplementIntake>(
            sortBy: [SortDescriptor(\.date)]
        ))

        var csv = "Date,Supplement,Brand,Amount,Unit,Notes\n"
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        for i in intakes {
            let date = iso.string(from: i.date)
            let name = i.supplement?.name ?? ""
            let brand = i.supplement?.brand ?? ""
            csv += "\(date),\(csvEscape(name)),\(csvEscape(brand)),\(i.amount),\(csvEscape(i.unit)),\(csvEscape(i.notes))\n"
        }

        let url = tempURL(prefix: "intakes", ext: "csv")
        try csv.data(using: .utf8)!.write(to: url, options: .atomic)
        return url
    }

    private static func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    private static func tempURL(prefix: String, ext: String) -> URL {
        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        let name = "\(prefix)-\(stamp).\(ext)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }
}
