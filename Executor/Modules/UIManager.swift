import JavaScriptCore

typealias UIManagerType = NSObject & JSModule & UIManagerExports
@objc protocol UIManagerExports: JSExport {
    func log(_ command: String)
}

protocol UIManagerDelegate: AnyObject {
    func flush(_ command: String)
}

class UIManager: UIManagerType {
    static let moduleName = "UIManager"
    weak var delegate: UIManagerDelegate?
    
    func log(_ command: String) {
        delegate?.flush(command)
    }
}
