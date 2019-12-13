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
                .foregroundColor(.secondary)
            if manager.isReady {
                TextField("Code", text: $code)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send Command", action: sendCommand)
                Button("Install App Launcher", action: {})
                    .padding()
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
