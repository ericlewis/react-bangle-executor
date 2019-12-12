import JavaScriptCore

struct Fetch: Module {
    static let moduleName = "Fetch"
    
    static let fetch: @convention(block) (String)-> JSPromise? = { link in
        let promise = JSPromise()
        promise.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
            timer.invalidate()
            if let url = URL(string: link) {
                URLSession.shared.dataTask(with: url){ (data, response, error) in
                    if let error = error {
                        promise.fail(error: error.localizedDescription)
                    } else if
                        let data = data,
                        let string = String(data: data, encoding: String.Encoding.utf8) {
                        promise.success(value: string)
                    } else {
                        promise.fail(error: "\(url) is empty")
                    }
                }
                .resume()
            } else {
                promise.fail(error: "\(link) is not url")
            }
        }
        
        return promise
    }
    
    static func register(_ context: JSContext) {        
        context["fetch"] = unsafeBitCast(fetch, to: JSValue.self)
    }
}
