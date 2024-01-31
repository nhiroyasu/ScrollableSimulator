import Foundation
import CoreGraphics
import Combine

class MouseScrollCompletionCaller {
    private let TIMEOUT_TIME: Double = 0.2
    private var eventQueue: [CGEvent] = []
    private var timeoutSubject: PassthroughSubject<Void, Never>?
    private var cancellable: AnyCancellable?
    private var scrollCompletionHandler: () -> Void = {}

    func initialize(scrollCompletionHandler: @escaping () -> Void) {
        eventQueue = []
        self.scrollCompletionHandler = scrollCompletionHandler
        timeoutSubject = .init()
        cancellable = timeoutSubject?.timeout(
            DispatchQueue.SchedulerTimeType.Stride(floatLiteral: TIMEOUT_TIME),
            scheduler: DispatchQueue.main
        )
        .sink(
            receiveCompletion: { [weak self] result in
                self?.scrollCompletionHandler()
                self?.reset()
            },
            receiveValue: { _ in }
        )
    }

    func send(event: CGEvent) {
        guard let copyEvent = event.copy() else { return }
        eventQueue.append(copyEvent)
        timeoutSubject?.send()
    }

    func isInitialized() -> Bool {
        timeoutSubject != nil && cancellable != nil
    }

    private func reset() {
        eventQueue = []
        timeoutSubject = nil
        cancellable = nil
        scrollCompletionHandler = {}
    }
}
