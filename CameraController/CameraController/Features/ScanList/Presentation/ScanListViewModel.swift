import Foundation
import Combine
import CombineCoreBluetooth

class ScanListViewModel: ObservableObject {
    @Published var peripherals: [PeripheralDiscovery] = []
    @Published var connectedPeripheral: Peripheral? = nil
    @Published var scanning: Bool = false
    @Published var services = [CBService]()
    @Published var characteristics = [CBCharacteristic]()

    let centralManager: CentralManager = .live()
    let peripheralManager: PeripheralManager = PeripheralManager.live
    var scanTask: AnyCancellable?
    var cancellables: Set<AnyCancellable> = []
    
    init() {
        centralManager.didDisconnectPeripheral
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] peripheral, error in
                if let error = error {
                    self?.reset()
                } else {
                    self?.reset()
                }
            })
            .store(in: &cancellables)
    }

    func startScan() {
        scanTask = centralManager.scanForPeripherals(withServices: [CameraPeripheral.Services.controller.uuid])
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

    func reset() {
        stopScan()
        connectedPeripheral = nil
    }

    func disconnect(peripheral: Peripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }

    func connect(_ discovery: PeripheralDiscovery) {
        centralManager.connect(discovery.peripheral)
            .map(Result.success)
            .catch({ Just(Result.failure($0)) })
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { result in
                    switch (result) {
                    case .success(let peripheral):
                        self.connectedPeripheral = peripheral
                        self.readServices(peripheral: peripheral)
                    case .failure(let error):
                        print("Failed to connect with error \(error.localizedDescription)")
                        self.reset()
                    }
                })
                    .store(in: &cancellables)
    }

    private func readServices(peripheral: Peripheral) {
        peripheral.discoverServices([CameraPeripheral.Services.controller.uuid])
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { services in
                guard let service = services.first else { return }
                self.readCharacteristics(peripheral: peripheral, service: service)
            }).store(in: &cancellables)
    }

    private func readCharacteristics(peripheral: Peripheral, service: CBService) {
        peripheral.discoverCharacteristics(CameraPeripheral.Characteristics.allCases.map { $0.uuid }, for: service).receive(on: DispatchQueue.main).sink(receiveCompletion: {_ in }, receiveValue: { characteristics in
            print("characteristics \(characteristics)")

            self.characteristics = characteristics
            self.readCameraState()

            characteristics.forEach { characteristic in
                if characteristic.uuid == CameraPeripheral.Characteristics.camera.uuid {
                    peripheral.listenForUpdates(on: characteristic).receive(on: DispatchQueue.main).sink(receiveCompletion: {_ in }, receiveValue: { data in
                        guard let data = data else { return }
                        print(String(data: data, encoding: .utf8))
                    }).store(in: &self.cancellables)

                    peripheral.setNotifyValue(true, for: characteristic).receive(on: DispatchQueue.main).sink(receiveCompletion: { completion in
                        print(completion)
                    }, receiveValue: {
                        print("did enable notify")
                    }).store(in: &self.cancellables)
                }
            }
        }).store(in: &self.cancellables)
    }

    func readCameraState() {
        guard let characteristic = characteristics.first(where: { $0.uuid == CameraPeripheral.Characteristics.camera.uuid }), let peripheral = connectedPeripheral else { return }

        peripheral.readValue(for: characteristic).receive(on: DispatchQueue.main).sink(receiveCompletion: { _ in }, receiveValue: { data in
            print("received data \(data) for characteristic \(characteristic.uuid)")

            guard let data = data, let value = String(data: data, encoding: .utf8) else { return }
            print("did read value \(value) for characteristic \(characteristic.uuid)")
        }).store(in: &cancellables)
    }

    func setCamera(on: Bool) {
        guard let characteristic = characteristics.first(where: { $0.uuid == CameraPeripheral.Characteristics.command.uuid }), let peripheral = connectedPeripheral else { return }

        if on {
            peripheral.writeValue(Data([1]), for: characteristic, type: .withResponse).sink(receiveCompletion: { _ in
                print("did write value 1 finished")
            }, receiveValue: {
                print("did write value 1")
            }).store(in: &cancellables)
        } else {
            peripheral.writeValue(Data([2]), for: characteristic, type: .withResponse).sink(receiveCompletion: { _ in
                print("did write value 2 finished")
            }, receiveValue: {
                print("did write value 2")
            }).store(in: &cancellables)
        }
    }

    func takePhoto() {
        guard let characteristic = characteristics.first(where: { $0.uuid == CameraPeripheral.Characteristics.command.uuid }), let peripheral = connectedPeripheral else { return }

        peripheral.writeValue(Data([3]), for: characteristic, type: .withResponse).sink(receiveCompletion: { _ in
            print("did write value 3 finished")
        }, receiveValue: {
            print("did write value 3")
        }).store(in: &cancellables)
    }
}

struct CameraPeripheral {
    enum Services {
        case controller

        var uuid: CBUUID {
            switch self {
            case .controller:
                return CBUUID(string: "96ee66cc-d2e4-11ed-afa1-0242ac120002")
            }
        }
    }

    enum Characteristics: CaseIterable {
        case camera, command, delay, iso, updateSettings, shotCount

        var uuid: CBUUID {
            switch self {
            case .camera:
                return CBUUID(string: "96ee6db6-d2e4-11ed-afa1-0242ac120002")
            case .command:
                return CBUUID(string: "96ee69d8-d2e4-11ed-afa1-0242ac120002")
            case .delay:
                return CBUUID(string: "b574bac4-d32f-11ed-afa1-0242ac120002")
            case .iso:
                return CBUUID(string: "b574bb34-d32f-11ed-afa1-0242ac120002")
            case .updateSettings:
                return CBUUID(string: "b574bc34-d32f-11ed-afa1-0242ac120002")
            case .shotCount:
                return CBUUID(string: "b574be34-d32f-11ed-afa1-0242ac120002")
            }
        }


//        CAMERA_CHAR_UUID = '96ee6db6-d2e4-11ed-afa1-0242ac120002'
//        COMMAND_CHAR_UUID = '96ee69d8-d2e4-11ed-afa1-0242ac120002'
//        DELAY_CHAR_UUID = 'b574bac4-d32f-11ed-afa1-0242ac120002'
//        ISO_VALUE_UUID = 'b574bb34-d32f-11ed-afa1-0242ac120002'
//        UPDATE_SETTINGS_UUID = 'b574bc34-d32f-11ed-afa1-0242ac120002'
//        SHOT_COUNT_UUID = 'b574be34-d32f-11ed-afa1-0242ac120002'
    }
}
