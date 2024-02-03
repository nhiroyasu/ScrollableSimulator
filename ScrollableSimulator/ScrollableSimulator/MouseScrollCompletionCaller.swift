import Foundation
import CoreGraphics
import Combine

class MouseScrollCompletionCaller {
    private let TIMEOUT_TIME: Double = 0.1
    private var eventQueue: [CGEvent] = []
    private var timeoutSubject: PassthroughSubject<Void, Never>?
    private var cancellable: AnyCancellable?
    private var scrollCompletionHandler: (CGEvent?) -> Void = { _ in }

    func initialize(scrollCompletionHandler: @escaping (CGEvent?) -> Void) {
        eventQueue = []
        self.scrollCompletionHandler = scrollCompletionHandler
        timeoutSubject = .init()
        cancellable = timeoutSubject?.timeout(
            DispatchQueue.SchedulerTimeType.Stride(floatLiteral: TIMEOUT_TIME),
            scheduler: DispatchQueue.main
        )
        .sink(
            receiveCompletion: { [weak self] result in
                guard let self else { return }
                self.scrollCompletionHandler(eventQueue.last)
                self.reset()
            },
            receiveValue: { _ in }
        )
    }

    func push(scrollEvent: CGEvent) {
        guard let copyEvent = scrollEvent.copy() else { return }
        eventQueue.append(copyEvent)
        timeoutSubject?.send()
    }

    private func reset() {
        eventQueue = []
        timeoutSubject = nil
        cancellable = nil
        scrollCompletionHandler = { _ in }
    }
}
