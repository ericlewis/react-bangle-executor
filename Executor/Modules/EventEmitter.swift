import JavaScriptCore

typealias EventEmitterType = NSObject & JSModule & EventEmitterExports
@objc protocol EventEmitterExports: JSExport {
    func addListener(_ name: String, _ callback: () -> Void)
    func removeListener(_ name: String, callback: () -> Void)
}

class EventEmitter: EventEmitterType {
    static let moduleName = "EventEmitter"
    
    var callbacks: [String: () -> Void] = [:]
    
    // Native (bridge bluetooth this way?)
    func fire(_ name: String) {}
    
    // JS
    func addListener(_ name: String, _ callback: () -> Void) {}
    func removeListener(_ name: String, callback: () -> Void) {}
}
