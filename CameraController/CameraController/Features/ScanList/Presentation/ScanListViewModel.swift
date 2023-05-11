import Foundation
import Combine
import CombineCoreBluetooth

class ScanListViewModel: ObservableObject {
    let centralManager: CentralManager = .live()
      @Published var peripherals: [PeripheralDiscovery] = []
      var scanTask: AnyCancellable?
      @Published var peripheralConnectResult: Result<Peripheral, Error>?
      @Published var scanning: Bool = false
      var cancellables: Set<AnyCancellable> = []

    func startScan() {
        scanTask = centralManager.scanForPeripherals(withServices: [CBUUID(string: "96ee66cc-d2e4-11ed-afa1-0242ac120002")])
          .scan([], { list, discovery -> [PeripheralDiscovery] in
            guard !list.contains(where: { $0.id == discovery.id }) else { return list }
            return list + [discovery]
          })
          .receive(on: DispatchQueue.main)
          .sink(receiveValue: { [weak self] in
            self?.peripherals = $0
          })
        self.scanning = centralManager.isScanning
    }

    func stopScan() {
      scanTask = nil
      peripherals = []
      self.scanning = centralManager.isScanning
    }
}
