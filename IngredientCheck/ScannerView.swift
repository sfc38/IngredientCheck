//
//  ScannerView.swift
//  IngredientCheck
//
//  Created by Fatih Catpinar on 3/28/26.
//

import SwiftUI
import VisionKit
import UIKit

/// Container that owns a DataScannerViewController as a child and
/// ties start/stop scanning to its own lifecycle. Without this, the
/// scanner inside a TabView tab opens the camera preview but never
/// starts barcode recognition — startScanning() called before the
/// view is in a window quietly no-ops. DataScannerViewController is
/// not subclassable outside VisionKit, so we use composition.
final class ScannerContainerVC: UIViewController {
    let scanner: DataScannerViewController

    init(scanner: DataScannerViewController) {
        self.scanner = scanner
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(scanner)
        scanner.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanner.view)
        NSLayoutConstraint.activate([
            scanner.view.topAnchor.constraint(equalTo: view.topAnchor),
            scanner.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scanner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scanner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        scanner.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !scanner.isScanning { try? scanner.startScanning() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if scanner.isScanning { scanner.stopScanning() }
    }
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String

    func makeUIViewController(context: Context) -> ScannerContainerVC {
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
        return ScannerContainerVC(scanner: scanner)
    }

    func updateUIViewController(_ uiViewController: ScannerContainerVC, context: Context) {
        if !uiViewController.scanner.isScanning {
            try? uiViewController.scanner.startScanning()
        }
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
