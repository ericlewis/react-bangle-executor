import JavaScriptCore
import Combine

class JavaScriptManager {
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
        setupRuntime()
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
    
    func setupRuntime() {
        context?.evaluateScript("!function(i){function e(e){for(var r,t,n=e[0],o=e[1],u=e[2],l=0,a=[];l<n.length;l++)t=n[l],Object.prototype.hasOwnProperty.call(f,t)&&f[t]&&a.push(f[t][0]),f[t]=0;for(r in o)Object.prototype.hasOwnProperty.call(o,r)&&(i[r]=o[r]);for(s&&s(e);a.length;)a.shift()();return p.push.apply(p,u||[]),c()}function c(){for(var e,r=0;r<p.length;r++){for(var t=p[r],n=!0,o=1;o<t.length;o++){var u=t[o];0!==f[u]&&(n=!1)}n&&(p.splice(r--,1),e=l(l.s=t[0]))}return e}var t={},f={1:0},p=[];function l(e){if(t[e])return t[e].exports;var r=t[e]={i:e,l:!1,exports:{}};return i[e].call(r.exports,r,r.exports,l),r.l=!0,r.exports}l.m=i,l.c=t,l.d=function(e,r,t){l.o(e,r)||Object.defineProperty(e,r,{enumerable:!0,get:t})},l.r=function(e){\"undefined\"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(e,Symbol.toStringTag,{value:\"Module\"}),Object.defineProperty(e,\"__esModule\",{value:!0})},l.t=function(r,e){if(1&e&&(r=l(r)),8&e)return r;if(4&e&&\"object\"==typeof r&&r&&r.__esModule)return r;var t=Object.create(null);if(l.r(t),Object.defineProperty(t,\"default\",{enumerable:!0,value:r}),2&e&&\"string\"!=typeof r)for(var n in r)l.d(t,n,function(e){return r[e]}.bind(null,n));return t},l.n=function(e){var r=e&&e.__esModule?function(){return e.default}:function(){return e};return l.d(r,\"a\",r),r},l.o=function(e,r){return Object.prototype.hasOwnProperty.call(e,r)},l.p=\"/\";var r=this[\"webpackJsonphello-react-native-custom-renderer\"]=this[\"webpackJsonphello-react-native-custom-renderer\"]||[],n=r.push.bind(r);r.push=e,r=r.slice();for(var o=0;o<r.length;o++)e(r[o]);var s=n;c()}([])")
    }
    
    func loadApp(name: String) {
        let runnerVendor = URL(string: "https://raw.githubusercontent.com/ericlewis/braclet/master/\(name)/vendor.js")!
        let runnerMain = URL(string: "https://raw.githubusercontent.com/ericlewis/braclet/master/\(name)/main.js")!
        let vendorPublisher = URLSession.shared.dataTaskPublisher(for: runnerVendor).map { String(data: $0.data, encoding: .utf8) }.compactMap { $0 }
        let mainPublisher = URLSession.shared.dataTaskPublisher(for: runnerMain).map { String(data: $0.data, encoding: .utf8) }.compactMap { $0 }
        
        loadAppCancellable?.cancel()
        loadAppCancellable = Publishers.Zip(vendorPublisher, mainPublisher)
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in }) {
                self.context = JSContext()
                self.setupJS()
                self.context?.evaluateScript($0.0)
                self.context?.evaluateScript($0.1)
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
