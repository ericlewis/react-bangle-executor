import JavaScriptCore

let timerJSSharedInstance = JSTimer()

@objc protocol TimerJSExport: JSExport {
    func setTimeout(_ callback: JSValue, _ ms: Double) -> String
    func clearTimeout(_ identifier: String)
    func setInterval(_ callback: JSValue, _ ms: Double) -> String
}

@objc class JSTimer: NSObject, TimerJSExport, JSModule {
    var timers = [String: Timer]()
    
    static let moduleName = "timerJS"
    
    static func register(_ jsContext: JSContext) {
        jsContext[moduleName] = timerJSSharedInstance
        jsContext.evaluateScript(
            "function setTimeout(callback, ms) {" +
                "    return timerJS.setTimeout(callback, ms)" +
                "}" +
                "function clearTimeout(indentifier) {" +
                "    timerJS.clearTimeout(indentifier)" +
                "}" +
                "function setInterval(callback, ms) {" +
                "    return timerJS.setInterval(callback, ms)" +
            "}"
        )
    }
    
    func clearTimeout(_ identifier: String) {
        let timer = timers.removeValue(forKey: identifier)
        
        timer?.invalidate()
    }
    
    
    func setInterval(_ callback: JSValue,_ ms: Double) -> String {
        createTimer(callback: callback, ms: ms, repeats: true)
    }
    
    func setTimeout(_ callback: JSValue, _ ms: Double) -> String {
        createTimer(callback: callback, ms: ms , repeats: false)
    }
    
    func createTimer(callback: JSValue, ms: Double, repeats : Bool) -> String {
        var timeInterval  = ms/1000.0
        
        let uuid = NSUUID().uuidString
        
        if timeInterval == 0 {
            timeInterval += 0.1
        }
        
        DispatchQueue.main.async(execute: {
            let timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                             target: self,
                                             selector: #selector(self.callJsCallback),
                                             userInfo: callback,
                                             repeats: repeats)
            self.timers[uuid] = timer
        })
        
        
        return uuid
    }
    
    @objc func callJsCallback(_ timer: Timer) {
        let callback = (timer.userInfo as! JSValue)
        callback.call(withArguments: nil)
    }
}
