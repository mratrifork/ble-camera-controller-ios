import Foundation
import Combine
import CoreBluetooth
import BLECombineKit

struct Camera: Codable {
    let manufacturer: String
    let model: String
    let serialNumber: String

    var isConnected: Bool {
        !["UKNOWN", "1234"].contains(serialNumber)
    }

    enum CodingKeys: String, CodingKey {
        case manufacturer
        case model
        case serialNumber = "serial_numer"
    }
}

enum ScanListUiState {
    case idle, scanning, connecting, connected(Camera), error(String)
}

class ScanListViewModel: ObservableObject {
    @Published var uiState: ScanListUiState = .idle
    @Published var connectedPeripheral: BLEPeripheral? = nil
    @Published var characteristics = [BLECharacteristic]()

    let centralManager: BLECentralManager = BLECombineKit.buildCentralManager(with: CBCentralManager())

    var scanTask: AnyCancellable?
    var cancellables: Set<AnyCancellable> = []

    func startScan() {
        uiState = .scanning
        print("Start scanning")
        centralManager
//            .scanForPeripherals(withServices: nil, options: nil)
            .scanForPeripherals(withServices: [CameraPeripheral.Services.controller.uuid], options: nil)
            .first()
            .sink(
                receiveCompletion: {_ in
                    print("Scan completed")
                },
                receiveValue: { scanResult in
                    print("Scan result \(scanResult)")
                    self.startConnect(scanResult: scanResult)
                }
            ).store(in: &cancellables)
    }

    func stopScan() {
        centralManager.stopScan()
        print("Stop scan")
        reset()
    }

    private func startConnect(scanResult: BLEScanResult) {
        uiState = .connecting
        print("Start connecting \(scanResult)")
        scanResult
            .peripheral
            .connect(with: [:])
            .sink(
                receiveCompletion: { _ in
                    print("Connect completed")
                },
                receiveValue: { peripheral in
                    print("Connected peripheral \(peripheral)")
                    self.connectedPeripheral = peripheral
                    self.startDiscoveringServices(peripheral: peripheral)
                    self.startObserveringConnectionState(peripheral: peripheral)
                }
            ).store(in: &cancellables)
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager
            .cancelPeripheralConnection(peripheral.peripheral)
            .sink { _ in
                print("Disconnected")
                self.reset()
            } receiveValue: { _ in }
            .store(in: &cancellables)

        peripheral.disconnect()
    }

    private func reset() {
        uiState = .idle
        connectedPeripheral = nil
        characteristics = []
        cancellables = []
    }

    func connectCamera() {
        write(value: Data([1]), for: CameraPeripheral.Characteristics.command.uuid)
    }

    func disconnectCamera() {
        write(value: Data([2]), for: CameraPeripheral.Characteristics.command.uuid)
    }

    func takePhoto() {
        write(value: Data([3]), for: CameraPeripheral.Characteristics.command.uuid)
    }

    private func startObservingCamera() {
        guard
            let characteristic = characteristics.first(where: { $0.value.uuid == CameraPeripheral.Characteristics.camera.uuid })
        else { return }

        characteristic.observeValueUpdateAndSetNotification()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                print("Finished receiving values")
            } receiveValue: { data in
                print("received notification")
            }
            .store(in: &cancellables)

        characteristic.observeValue()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                print("Finished receiving values")
            } receiveValue: { data in
                print("Received camera data:\n\(data.value)")

                if let camera = try? JSONDecoder().decode(Camera.self, from: data.value) {
                    print("Parsed camera data \(camera)")
                    self.uiState = .connected(camera)
                } else {
                    print("Failed to parse camera data")
                }
            }
            .store(in: &cancellables)
    }

    private func write(value: Data, for uuid: CBUUID) {
        guard
            let characteristic = characteristics.first(where: { $0.value.uuid == uuid })
        else { return }

        characteristic
            .writeValue(value, type: .withResponse)
            .sink { _ in
                print("did write value \(value) for characteristic \(characteristic.value)")
            } receiveValue: { _ in }
            .store(in: &cancellables)

    }

    private func startObserveringConnectionState(peripheral: BLEPeripheral) {
        peripheral
            .observeConnectionState()
            .sink { connected in
                print("Observing connection - Connected = \(connected)")

                if (!connected) {
                    self.reset()
                }
            }
            .store(in: &cancellables)
    }

    private func startDiscoveringServices(peripheral: BLEPeripheral) {
        peripheral
//            .discoverServices(serviceUUIDs: nil)
            .discoverServices(serviceUUIDs: [CameraPeripheral.Services.controller.uuid])
            .sink(
                receiveCompletion: {_ in
                    print("Discover services completed")
                },
                receiveValue: { service in
                    print("Discovered service \(service)")
                    self.startDiscoveringCharacteristics(peripheral: peripheral, service: service)
                })
            .store(in: &cancellables)
    }

    private func startDiscoveringCharacteristics(peripheral: BLEPeripheral, service: BLEService) {
        service
//            .discoverCharacteristics(characteristicUUIDs: nil)
            .discoverCharacteristics(characteristicUUIDs: CameraPeripheral.Characteristics.allCases.map { $0.uuid })
            .sink(
                receiveCompletion: {_ in
                    print("Discover characteristics completed for service \(service)")
                    self.startObservingCamera()
                },
                receiveValue: { characteristic in
                    print("Dicovered characteristic \(characteristic) for service \(service)")
                    self.characteristics.append(characteristic)
                })
            .store(in: &cancellables)
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
