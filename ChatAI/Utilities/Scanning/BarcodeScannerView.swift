//
//  BarcodeScannerView.swift
//  ChatAI
//
//  Created by Ravi Tiwari on 11/09/25.
//

import SwiftUI
import VisionKit

/// SwiftUI wrapper around DataScannerViewController for barcode scanning
@available(iOS 16.0, *)
struct BarcodeScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = DataScannerViewController

    /// Called when a barcode payload (string) is recognized
    var onPayload: (String) -> Void
    /// Called when the user closes the scanner
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true
        )
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // no-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload, onCancel: onCancel)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onPayload: (String) -> Void
        let onCancel: () -> Void
        private var handledIdentifiers = Set<String>()

        init(onPayload: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onPayload = onPayload
            self.onCancel = onCancel
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handle(item: item, in: dataScanner)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd item: RecognizedItem, allItems: [RecognizedItem]) {
            handle(item: item, in: dataScanner)
        }

        func dataScannerDidDismiss(_ dataScanner: DataScannerViewController) {
            onCancel()
        }

        private func handle(item: RecognizedItem, in scanner: DataScannerViewController) {
            guard case .barcode(let barcode) = item else { return }
            // Combine symbology and payload if available
            if let payload = barcode.payloadStringValue, !payload.isEmpty {
                // Avoid firing multiple times for the same value quickly
                if handledIdentifiers.contains(payload) { return }
                handledIdentifiers.insert(payload)
                onPayload(payload)
            }
        }
    }
}

@available(iOS 16.0, *)
struct BarcodeScannerContainer: View {
    var onPayload: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        BarcodeScannerView(onPayload: onPayload, onCancel: onCancel)
            .ignoresSafeArea()
            .onAppear {
                // DataScanner must be started after appearing
            }
    }
}
