import Testing
import Foundation
@testable import shoechoo

@Suite("DebounceTask")
@MainActor
struct DebounceTaskTests {

    @Test("schedule triggers action after interval")
    func scheduleTriggers() async {
        var callCount = 0
        let debounce = DebounceTask(interval: 0.05) {
            callCount += 1
        }
        debounce.schedule()
        try? await Task.sleep(for: .milliseconds(150))
        #expect(callCount == 1)
    }

    @Test("cancel prevents action from firing")
    func cancelPrevents() async {
        var callCount = 0
        let debounce = DebounceTask(interval: 0.05) {
            callCount += 1
        }
        debounce.schedule()
        debounce.cancel()
        try? await Task.sleep(for: .milliseconds(150))
        #expect(callCount == 0)
    }

    @Test("Rapid schedule calls execute only the last one")
    func rapidScheduleDebounces() async {
        var callCount = 0
        let debounce = DebounceTask(interval: 0.05) {
            callCount += 1
        }
        debounce.schedule()
        debounce.schedule()
        debounce.schedule()
        try? await Task.sleep(for: .milliseconds(200))
        #expect(callCount == 1)
    }

    @Test("Schedule after cancel restarts the cycle")
    func scheduleAfterCancel() async {
        var callCount = 0
        let debounce = DebounceTask(interval: 0.05) {
            callCount += 1
        }
        debounce.schedule()
        debounce.cancel()
        debounce.schedule()
        try? await Task.sleep(for: .milliseconds(150))
        #expect(callCount == 1)
    }

    @Test("Multiple independent cycles each fire once")
    func multipleCycles() async {
        var callCount = 0
        let debounce = DebounceTask(interval: 0.05) {
            callCount += 1
        }
        // First cycle
        debounce.schedule()
        try? await Task.sleep(for: .milliseconds(150))
        #expect(callCount == 1)

        // Second cycle
        debounce.schedule()
        try? await Task.sleep(for: .milliseconds(150))
        #expect(callCount == 2)
    }
}
