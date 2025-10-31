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
        // Configure recognized data types with or without language bias
        let recognizedTypes: Set<DataScannerViewController.RecognizedDataType> = {
            if let l = languages, !l.isEmpty {
                return [.text(languages: l)]
            } else {
                return [.text()]
            }
        }()
        let controller = DataScannerViewController(
            recognizedDataTypes: recognizedTypes,
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true
        )
        controller.delegate = context.coordinator
        // Attempt to start scanning immediately; update will ensure if needed
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Ensure scanning is running after presentation transitions
        if !(uiViewController.isScanning) {
            try? uiViewController.startScanning()
        }
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
            // no-op: selection is determined by user tap so the highlight is clear
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate item: RecognizedItem, allItems: [RecognizedItem]) {
            // no-op: avoid changing selection while scanning
        }

        func dataScannerDidDismiss(_ dataScanner: DataScannerViewController) {
            onCancel()
        }

        private func handle(_ item: RecognizedItem) {
            guard case .text(let textItem) = item else { return }
            let value = textItem.transcript // keep formatting as-is
            guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
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
        ZStack(alignment: .topLeading) {
            TextScannerView(onText: { latest in
                // capture latest text as-is
                self.latestText = latest
            }, onCancel: onCancel, languages: languages)
                .ignoresSafeArea()
            // Minimal in-scanner top bar with back button
            HStack {
                Button(action: onCancel) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.backward")
                        Text("Back")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                .foregroundColor(.white)
                Spacer()
                // Insert button: sends the aggregated latest captured text
                Button(action: {
                    let text = latestText
                    onText(text)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.insert")
                        Text("Insert")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)

            // Removed center hint to ensure native highlight is clearly visible

            // Bottom preview of the tapped (selected) text
            VStack {
                Spacer()
                if !latestText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected text")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        Text(latestText)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(3)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 18)
                }
            }
        }
    }

    // MARK: - Private
    @State private var latestText: String = ""
}
