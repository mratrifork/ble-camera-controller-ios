import SwiftUI

struct ScanListScreen: View {
    @ObservedObject var viewModel: ScanListViewModel = ScanListViewModel()

    var body: some View {
        VStack(spacing: 20) {
            switch (viewModel.uiState) {
            case .idle:
                Button("Start") {
                    viewModel.startScan()
                }
            case .scanning:
                Text("Scanning")
                Button("Stop scanning") {
                    viewModel.stopScan()
                }
            case .connecting:
                Text("Connecting")
                Button("Cancel") {
                    viewModel.disconnect()
                }
            case .connected(let camera):
                Spacer()
                Text("Connected")

                VStack {
                    Text(camera.manufacturer)
                    Text(camera.model)
                    Text(camera.serialNumber)
                }
                HStack(spacing: 20) {
                    if camera.isConnected {
                        Button("Disconnect camera") {
                            viewModel.disconnectCamera()
                        }
                        Button("Take photo") {
                            viewModel.takePhoto()
                        }
                    } else {
                        Button("Connect camera") {
                            viewModel.connectCamera()
                        }
                    }
                }
                Spacer()
                Button("Disconnect") {
                    viewModel.disconnect()
                }
            case .error(_):
                Text("Failed")
            }

        }.padding()
    }
}
