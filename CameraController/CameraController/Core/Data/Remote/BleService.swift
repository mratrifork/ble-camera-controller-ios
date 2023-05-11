//
//  BleService.swift
//  CameraController
//
//  Created by Jan van Zetten on 11/05/2023.
//

import Foundation
import CoreBluetooth

class BleService : NSObject, CBCentralManagerDelegate {
    let manager: CBCentralManager
    
    init(manager: CBCentralManager) {
        self.manager = manager
        super.init()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            manager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber){
        didReadPeripheral(peripheral, rssi: RSSI)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        didReadPeripheral(peripheral, rssi: RSSI)
    }
    
    func didReadPeripheral(_ peripheral: CBPeripheral, rssi: NSNumber){
        // TODO publish peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        peripheral.readRSSI()
    }
}
