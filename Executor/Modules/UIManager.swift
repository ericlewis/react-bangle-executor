import JavaScriptCore

typealias UIManagerType = NSObject & JSModule & UIManagerExports
@objc protocol UIManagerExports: JSExport {
    func flush(_ command: String)
}

protocol UIManagerDelegate: AnyObject {
    func flush(_ command: String)
}

class UIManager: UIManagerType {
    static let moduleName = "UIManager"
    weak var delegate: UIManagerDelegate?
    
    func flush(_ command: String) {
        delegate?.flush(command)
    }
}
