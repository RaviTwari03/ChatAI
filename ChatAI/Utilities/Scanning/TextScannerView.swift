//
//  TextScannerView.swift
//  ChatAI
//
//  Created by Cascade on 16/09/25.
//

import SwiftUI
import VisionKit

/// SwiftUI wrapper around DataScannerViewController for OCR text scanning
@available(iOS 16.0, *)
struct TextScannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = DataScannerViewController

    /// Called when recognized text is produced (single best item)
    var onText: (String) -> Void
    /// Called when user cancels/dismisses the scanner
    var onCancel: () -> Void
    /// Optional BCP-47 language codes to bias recognition, e.g. ["en"]. Pass nil for automatic.
    var languages: [String]? = nil

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.text(languages: languages ?? [])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // no-op
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onText: onText, onCancel: onCancel)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onText: (String) -> Void
        let onCancel: () -> Void
        private var lastOutput: String = ""

        init(onText: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
            self.onText = onText
            self.onCancel = onCancel
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handle(item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd item: RecognizedItem, allItems: [RecognizedItem]) {
            // Trigger once when a new text item is detected
            handle(item)
        }

        func dataScannerDidDismiss(_ dataScanner: DataScannerViewController) {
            onCancel()
        }

        private func handle(_ item: RecognizedItem) {
            guard case .text(let textItem) = item else { return }
            let value = textItem.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            // Avoid duplicate rapid callbacks for same content
            if value == lastOutput { return }
            lastOutput = value
            onText(value)
        }
    }
}

@available(iOS 16.0, *)
struct TextScannerContainer: View {
    var onText: (String) -> Void
    var onCancel: () -> Void
    var languages: [String]? = nil

    var body: some View {
        TextScannerView(onText: onText, onCancel: onCancel, languages: languages)
            .ignoresSafeArea()
    }
}
