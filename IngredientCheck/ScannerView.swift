//
//  ScannerView.swift
//  IngredientCheck
//
//  Created by Fatih Catpinar on 3/28/26.
//

import SwiftUI
import VisionKit
import UIKit

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: ScannerView

        init(parent: ScannerView) {
            self.parent = parent
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didTapOn item: RecognizedItem
        ) {
            switch item {
            case .barcode(let barcode):
                if let code = barcode.payloadStringValue {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    parent.scannedCode = code
                }
            default:
                break
            }
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard let firstItem = addedItems.first else { return }

            switch firstItem {
            case .barcode(let barcode):
                if let code = barcode.payloadStringValue {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    parent.scannedCode = code
                }
            default:
                break
            }
        }
    }
}
