import SwiftUI

struct ScanListScreen: View {
    @ObservedObject var viewModel: ScanListViewModel = ScanListViewModel()

    var body: some View {
        VStack {
            if let peripheral = viewModel.connectedPeripheral {
                Spacer()
                HStack(spacing: 20) {
                    Button("On") {
                        viewModel.setCamera(on: true)
                    }
                    Button("Off") {
                        viewModel.setCamera(on: false)
                    }
                    Button("Take photo") {
                        viewModel.takePhoto()
                    }
                }
                Spacer()
                Text("\(peripheral.id)")
                Spacer()
                Button("Disconnect") {
                    viewModel.disconnect(peripheral: peripheral)
                }
                Spacer()
            } else {
                if viewModel.scanning {
                    Button("Stop scan") {
                        viewModel.stopScan()
                    }
                    List(viewModel.peripherals, id: \.id) { peripheral in
                        Text(peripheral.id.uuidString).onTapGesture {
                            viewModel.connect(peripheral)
                        }
                    }
                } else {
                    Button("Start scan") {
                        viewModel.startScan()
                    }
                }
            }
        }
    }
}
