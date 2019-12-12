import JavaScriptCore

protocol Module {
    static var moduleName: String { get }
    static func register(_ context: JSContext)
}

extension Module {
    static func register(_ context: JSContext) {
        context[moduleName] = self
    }
}

typealias JSModule = Module
