//Copyright © 2018 Ethan Abrams. All rights reserved.
import Foundation
import SwiftWebSocket
public class WebSocketRequestResponse: AsyncRequestResponse {
    
    private var responseListeners = Dictionary<UUID, (Message) -> ()>()
    private var listeners = [String : Dictionary<UUID, (Message) -> ()>]()
    private var socket: WebSocket?
    private var pingTimer: Timer? = nil
    private var pongTimer: Timer? = nil
    private var reconnectKey: String? = nil
    public var onReconnect: (() -> ())?
    private var serverUrl: String?
    private var httpHeaders = [String : String]()
    private var extraOnClose = [(Int, String, Bool) -> ()]()
    
    
    init() {
        
        self.socket = WebSocket()
        
        socket?.event.error = {error in
            print("printing error \(type(of: error))")
            print("printing error \(error)")
        }
        
        socket?.event.close = { (int, string, bool) in
            print("websocket closed \(int, string, bool)")
            //self.extraOnClose.forEach({(item) in
                //item(int, string, bool)
            //})
            /*if int == 4000 || int == 1006 {
                var httpHeadersToSend = self.httpHeaders
                httpHeadersToSend["reconnect"] = self.reconnectKey!
                var request = URLRequest(url: URL(string: self.serverUrl!)!)
                for key in self.httpHeaders.keys {
                    request.addValue(self.httpHeaders[key]!, forHTTPHeaderField: key)
                }
                print("about to open")
                self.socket?.open(request: request)
                self.startReconnectTimers()
            }*/
            
        }
 
        
        socket?.event.pong = {data in
            self.stopPongTimer()
            print("has been ponged: \(data)")
        }
        
        socket?.event.message = {msg in
            if (type(of: msg) == type(of: [UInt8]())) {
                let incomingData = Data(msg as! [UInt8])
                let rawJSON = try! JSONSerialization.jsonObject(with: incomingData, options: []) as! [String: Any]
                let message = Message(dict: rawJSON)
                if message == nil {
                    print("invalid incoming message")
                } else {
                    self.proccessIncomingMessage(message: message!)
                }
                return
            }
            let msgAsString = msg as! String
            let msgData = try! JSONSerialization.jsonObject(with: msgAsString.data(using: .utf8)!, options: []) as? [String:String]
            if let newConnectionid = msgData?["newConnectionId"] {
                print("New Conncetion ID: \(newConnectionid)")
                self.onReconnect?()
                return
            }
            if let reconnectId = msgData?["RECONNECTID"] {
                self.reconnectKey = reconnectId
            } else {
                let msgDataString = msg as! String
                let msgData = try! JSONSerialization.jsonObject(with: msgDataString.data(using: .utf8)!, options: []) as! [String : Any]
                let message = Message(dict: msgData)
                if message == nil {
                    
                } else {
                    self.proccessIncomingMessage(message: message!)
                }
            }
        }
        //startReconnectTimers()
    }
    
    private func startReconnectTimers() {
        print("start rec being caalled")
        if Thread.isMainThread {
            print("on main thread")
            self.pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: {(timer) in
                //self.socket = nil
                print("about to ping")
                self.socket?.ping()
                self.startPongTimer(seconds: 3)
            })
        } else {
            DispatchQueue.main.sync {
                print("off main thread")
                self.pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: {(timer) in
                    //self.socket = nil
                    print("about to ping")
                    self.socket?.ping()
                    self.startPongTimer(seconds: 3)
                })
            }
        }
    }
    
    func open(address: String, additionalHTTPHeaders: Dictionary<String, String>) {
        print("URL: \(address)")
        self.serverUrl = address
        self.httpHeaders = additionalHTTPHeaders
        print()
        var request = URLRequest(url: URL(string: address)!)
        for key in additionalHTTPHeaders.keys {
            request.addValue(additionalHTTPHeaders[key]!, forHTTPHeaderField: key)
        }
        if let socket = self.socket {
            print("ABOUT TO OPEN")
            socket.open(request: request)
        } else {
            print("about toesgfewgegw OEPEPEPENENENEE")
            self.socket = WebSocket()
            self.socket?.open(request: request)
            
        }
        self.startReconnectTimers()
    }
    
    func open(address: String) {
        self.serverUrl = address
        var request = URLRequest(url: URL(string: address)!)
        self.socket?.open(request: request)
        //self.startReconnectTimers()
    }
    
    
    private func proccessIncomingMessage(message: Message) {
        //print(message)
        if message.command == nil {
            print(message)
            let listener = self.responseListeners[UUID(uuidString: message.key!)!]!
            listener(message)
            self.responseListeners.removeValue(forKey: UUID(uuidString: message.key!)!)
        } else {
            print(message)
            if self.listeners[message.command!] != nil {
                for listener in (self.listeners[(message.command)!]?.values)! {
                    listener(message)
                }
            }
        }
    }
    
    func startPongTimer(seconds: Double) {
        print("starting the pong timer")
        self.pongTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: {(timer) in
            self.initiateReconnect()
        })
    }
    
    
    
    private func stopPongTimer() {
        print("stopping the pong timer")
        self.pongTimer?.invalidate()
        self.pongTimer = nil
    }
    
    private func initiateReconnect() {
        print("initiating reconnect")
        self.pingTimer?.invalidate()
        self.pingTimer = nil
        print("closing the socket")
        self.socket?.close(4000, reason: "HI")
        var httpHeadersToSend = self.httpHeaders
        httpHeadersToSend["reconnect"] = self.reconnectKey!
        
        reconnect(address: self.serverUrl!, additionHTTPHeaders: httpHeadersToSend)
        
            //self.open(address: self.serverUrl!, additionalHTTPHeaders: httpHeadersToSend
    }
    
    private func reconnect(address: String, additionHTTPHeaders: [String : String]) {
        print("RECONNECT READY STATE: \(self.socket?.readyState)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            if self.socket?.readyState == WebSocketReadyState.open {
                print("calling iteself again")
                self.reconnect(address: address, additionHTTPHeaders: additionHTTPHeaders)
            } else {
                self.open(address: address, additionalHTTPHeaders: additionHTTPHeaders)
            }
        })
    }
    
    func close() {
        self.socket?.close()
    }
    
    func sendMessage(command: String, payLoad: Any?, callback: ((Any?, ARRError?) -> ())?) {
        let key = UUID()
        let message = Message(command: command, key: key.uuidString, data: payLoad, error: nil)
        if callback != nil {
            func callackWrapper(msg: Message) {
                callback!(msg.data, msg.error)
            }
            self.responseListeners[key] = callackWrapper(msg:)
        }
        let messageAsDictionary = message.asDictionary()
        let messageToSend = try! JSONSerialization.data(withJSONObject: messageAsDictionary, options: [])
        //self.socket?.send(messageToSend)
        self.socket!.send(messageToSend)
    }
    
    func addListener(for command: String, callback: @escaping(Any?) -> ()) -> ListenerKey {
        var key = UUID()
        func callbackWrapper(msg: Message) {
            callback(msg.data)
        }
        if self.listeners[command] == nil {
            self.listeners[command] = Dictionary<UUID, (Message) -> ()>()
        }
        self.listeners[command]![key] = callbackWrapper(msg:)
        return ListenerKey(command: command, key: key)
    }
    
    func removeListener(listenerKey: ListenerKey) {
        listeners[listenerKey.command]!.removeValue(forKey: listenerKey.key)
    }
}

extension Message {
    init?(dict: Dictionary<String, Any>) {
        let keys = dict.keys
        
        if !keys.contains("command") || !keys.contains("key") ||
            !keys.contains("data") || !keys.contains("error") {
            return nil
        }
        self.command = dict["command"] as? String
        self.key = dict["key"] as? String
        if dict["data"] is NSNull {
            self.data = nil
        } else {
            self.data = dict["data"]
        }
        let pointErrorDict = dict["error"] as? [String:Any]
        if pointErrorDict == nil {
            self.error = nil
        } else {
            self.error = ARRError(dict: pointErrorDict!)
        }

    }
    
    func asDictionary() -> Dictionary<String, Any> {
        return [
            "command" : self.command,
            "key" : self.key,
            "data" : self.data,
            "error" : self.error
        ]
    }
}

extension ARRError {
    init?(dict: [String:Any]) {
        self.code = dict["code"] as! Int
        self.description = dict["description"] as! String
    }
}




