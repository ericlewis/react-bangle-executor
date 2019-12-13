import JavaScriptCore
import Combine

class JavaScriptManager {
    
    static let rootEndpoint = "https://raw.githubusercontent.com/ericlewis/braclet/master/"
    
    var context: JSContext?
    let bangleManager: BangleManager
    let uiManager: UIManager
    var window: JSValue?
    
    var loadAppCancellable: AnyCancellable?
    var apps: [String: JavaScriptManager] = [:]

    init(bangleManager: BangleManager = .shared) {
        self.bangleManager = bangleManager
        self.uiManager = UIManager()
        
        setupBangleManager()
    }
    
    func setupJS() {
        setupErrorPrototype()
        setupWindow()
        setupExceptionHandler()
        setupUIManager()
        setupModules()
    }
    
    func setupErrorPrototype() {
        context?.evaluateScript("""
            Error.prototype.isError = () => {return true}
        """)
    }
    
    func setupBangleManager() {
        bangleManager.delegate = self
    }
    
    func setupUIManager() {
        uiManager.delegate = self
    }
    
    func setupExceptionHandler() {
        context?.exceptionHandler = {
            guard let error = $1?.toString() else { return }
            print("[JS ERROR] \(error)")
        }
    }
    
    func setupModules() {
        guard let context = context else { return }
        let loadApp: @convention(block) (String) -> Void = { app in
            self.loadApp(name: app)
        }
        
        JSTimer.register(context)
        JSPromise.register(context)
        Fetch.register(context)
        EventEmitter.register(context)
        context["UIManager"] = uiManager
        context["loadApp"] = loadApp
    }
    
    func setupWindow() {
        window = JSValue(newObjectIn: context)
        context?.setObject(window, forKeyedSubscript: "window" as NSString)
    }
    
    func loadApp(name: String) {
        func makeStringPublisher(for url: URL) -> AnyPublisher<String, URLError> {
            URLSession.shared
                .dataTaskPublisher(for: url)
                .map { String(data: $0.data, encoding: .utf8) }
                .compactMap { $0 }
                .eraseToAnyPublisher()
        }
        
        guard let runnerRuntime = URL(string: "\(Self.rootEndpoint + name)/runtime.js") else { return }
        guard let runnerVendor = URL(string: "\(Self.rootEndpoint + name)/vendor.js") else { return }
        guard let runnerMain = URL(string: "\(Self.rootEndpoint + name)/main.js") else { return }
        
        loadAppCancellable?.cancel()
        loadAppCancellable = Publishers.Zip3(makeStringPublisher(for: runnerRuntime), makeStringPublisher(for: runnerVendor), makeStringPublisher(for: runnerMain))
            .map { $0.0 + $0.1 + $0.2 }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in }) {
                self.context = JSContext()
                self.setupJS()
                self.context?.evaluateScript($0)
            }
    }
}

extension JavaScriptManager: BangleManagerDelegate {
    func received(response: String) {
        if response.contains("{b:9") { // do more than this.. lol
            self.loadApp(name: "launcher")
        } else if response.count == 6 && response.starts(with: "{b:") {
            guard let buttonNumber = response.suffix(3).first else { return }
            let buttonInt = Int(String(buttonNumber)) ?? 0
            self.window?.forProperty("buttonPressed")?.call(withArguments: [buttonInt])
        }
    }
}

extension JavaScriptManager: UIManagerDelegate {
    func flush(_ command: String) {
        do {
            try bangleManager.send(command: command)
        } catch {
            print(error)
        }
    }
}
