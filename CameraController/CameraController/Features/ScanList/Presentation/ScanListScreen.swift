import SwiftUI

struct ScanListScreen: View {
    @ObservedObject var viewModel: ScanListViewModel = ScanListViewModel()

    var body: some View {
        VStack {
            Button("Start scan") {
                viewModel.startScan()
            }
            List(viewModel.peripherals, id: \.id) {
                Text($0.id.uuidString)
            }
        }
    }
}
