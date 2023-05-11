//
//  ContentView.swift
//  CameraController
//
//  Created by Martin Rasmussen on 11/05/2023.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var bleScanMananger: BleScanManager = BleScanManager()

    var body: some View {
        VStack {
            Button("Start scan") {
                bleScanMananger.startScan()
            }
            List(bleScanMananger.scanResults, id: \.identifier) {
                Text($0.identifier.uuidString)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
