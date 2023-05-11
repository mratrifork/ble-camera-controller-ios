import Foundation
import CoreBluetooth
import Combine

class BleScanManager: NSObject, CBCentralManagerDelegate, ObservableObject {
    private let manager: CBCentralManager

    @Published private(set) var scanResults = [CBPeripheral]()

    override init() {
        self.manager = CBCentralManager(delegate: nil, queue: DispatchQueue.global(qos: .userInitiated))
        super.init()
        self.manager.delegate = self
    }

    func startScan() {
        manager.scanForPeripherals(withServices: nil)
    }

    func stopScan() {
        manager.stopScan()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        var results = scanResults.filter { $0.identifier != peripheral.identifier }
        results.append(peripheral)

        scanResults = results
    }
}
