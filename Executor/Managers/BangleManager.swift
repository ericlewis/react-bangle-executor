import CoreBluetooth

enum BangleManagerError: Error {
    case cantWrite
}

protocol BangleManagerDelegate where Self: AnyObject {
    func received(response: String)
}

class BangleManager: NSObject, CBCentralManagerDelegate, CBPeripheralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    static let shared = BangleManager()
    
    var cb: CBCentralManager!
    var bangle: CBPeripheral?
    var commandQueue: Queue<String> = Queue()
    weak var delegate: BangleManagerDelegate?
    
    @Published var isReady = false
    
    var writeChar: CBCharacteristic? {
        didSet {
            DispatchQueue.main.async {
                self.isReady = true
            }
        }
    }
    
    init(queue: DispatchQueue = .global(qos: .utility), options: [String: Any]? = nil) {
        super.init()
        cb = CBCentralManager(delegate: self, queue: queue, options: options)
        cb.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach {
            peripheral.discoverCharacteristics(nil, for: $0)
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // bangle state changed
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach { characteristic in
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.write) {
                writeChar = characteristic
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        guard let response = String(data: data, encoding: .utf8) else { return }
        delegate?.received(response: response)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard peripheral.name?.contains("Bangle") ?? false && peripheral.state == .disconnected else { return }
        bangle = peripheral
        cb.stopScan()
        cb.connect(peripheral, options: nil)
    }
    
    var isBusy = false
}

extension BangleManager {
    func send(command: String) throws {
        commandQueue.enqueue("\(command)\r")
        
        guard !isBusy else { return }
        guard let char = writeChar else {
            throw BangleManagerError.cantWrite
        }
        
        func run() {
            isBusy = true
            guard let chunks = commandQueue.dequeue()?.components(withMaxLength: 16) else { return }
            chunks.forEach {
                bangle?.writeValue(Data($0.utf8), for: char, type: .withResponse)
            }
            isBusy = false
            
            if !commandQueue.isEmpty {
                run()
            }
        }
        
        run()
    }
}
