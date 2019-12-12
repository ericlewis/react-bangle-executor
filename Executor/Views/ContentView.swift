import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: BangleManager
    @State var code = ""

    func sendCommand() {
        do {
            try manager.send(command: code)
        } catch {
            print(error)
        }
    }
    
    var body: some View {
        VStack {
            Text(manager.isReady ? "Ready!" : "Waiting for Bangle...")
            TextField("Code", text: $code)
            Button("Send Command", action: sendCommand)
            .disabled(!manager.isReady)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
