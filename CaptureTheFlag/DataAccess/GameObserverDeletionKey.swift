import Foundation


struct GameObserverDeletionKey: Hashable, Equatable {
    let key = UUID()
    let observerType: ObserverType
    init(observerType: ObserverType) {
        self.observerType = observerType
    }
}
typealias ObserverType = String



