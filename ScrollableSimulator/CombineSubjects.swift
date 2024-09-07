import Foundation
import Combine

enum ScrollableSimulatorStatus {
    case active
    case simulatorIsNotRunning
    case error
}

let scrollableSimulatorStatusSubject = CurrentValueSubject<ScrollableSimulatorStatus, Never>(.simulatorIsNotRunning)
let restartScrollableSimulatorSubject = PassthroughSubject<Void, Never>()
