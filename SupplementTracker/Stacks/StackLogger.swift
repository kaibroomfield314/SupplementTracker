import Foundation
import SwiftData

enum StackLogger {
    @discardableResult
    static func log(
        stack: SupplementStack,
        at date: Date = .now,
        in context: ModelContext
    ) throws -> Int {
        let items = (stack.items ?? []).sorted { $0.sortOrder < $1.sortOrder }
        guard !items.isEmpty else { return 0 }

        let stackLabel = stack.name.isEmpty ? "stack" : stack.name
        let note = "From \(stackLabel) stack"

        var created = 0
        for item in items {
            guard let supplement = item.supplement else { continue }
            let intake = SupplementIntake(
                date: date,
                amount: item.amount,
                unit: item.unit,
                notes: note,
                supplement: supplement
            )
            context.insert(intake)
            created += 1
        }
        return created
    }
}
