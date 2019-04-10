
import Foundation
public struct ARRError {
    var code: Int
    var description: String
}

public protocol AsyncRequestResponse: class {
    var onReconnect: (() -> ())? {set get}
    func sendMessage(command: String, payLoad: Any?, callback: ((Any?, ARRError?) -> ())?)
    func addListener(for: String, callback: @escaping (Any?) -> ()) -> ListenerKey
    func removeListener(listenerKey: ListenerKey)
    func open(address: String, additionalHTTPHeaders: Dictionary<String, String>)
    func open(address: String)
    func close(closed: @escaping () -> ())
    
}
