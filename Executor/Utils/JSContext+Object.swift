import JavaScriptCore

extension JSContext {
    subscript(key: String) -> Any? {
        get {
            objectForKeyedSubscript(key)
        }
        set{
            setObject(newValue, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
        }
    }
}
