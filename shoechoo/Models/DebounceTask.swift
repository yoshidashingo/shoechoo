import Foundation

/// Task-based debounce utility replacing Timer for @MainActor-safe scheduling.
/// Eliminates nonisolated(unsafe) Timer properties (FR-09, NFR-02).
@MainActor
final class DebounceTask {
    private var task: Task<Void, Never>?
    private let interval: TimeInterval
    private let action: @MainActor @Sendable () -> Void

    init(interval: TimeInterval, action: @MainActor @Sendable @escaping () -> Void) {
        self.interval = interval
        self.action = action
    }

    func schedule() {
        task?.cancel()
        let interval = self.interval
        let action = self.action
        task = Task { @MainActor in
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }
            action()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
