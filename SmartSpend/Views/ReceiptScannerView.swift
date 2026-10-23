
import SwiftUI
import UIKit
import Vision
import ImageIO

// Stores the information extracted from a receipt.
struct ScannedReceipt {

    var merchant: String
    var amount: String
    var date: Date
    var notes: String
}

// Displays the camera and extracts receipt information.
struct ReceiptScannerView: View {

    @Environment(\.dismiss) private var dismiss

    // Send the scanned details to AddExpenseView.
    var onReceiptScanned: (ScannedReceipt) -> Void

    // Store the receipt photo.
    @State private var receiptImage: UIImage?

    // Control the camera.
    @State private var showCamera = false

    // Store recognized text.
    @State private var scannedText = ""

    // Editable receipt information.
    @State private var merchant = ""
    @State private var amount = ""
    @State private var receiptDate = Date()

    // Screen states.
    @State private var isScanning = false
    @State private var showCameraError = false

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 20) {

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 65))
                        .foregroundStyle(.purple)

                    Text("Scan Your Receipt")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Take a photo and review the extracted expense details.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Display captured receipt.
                    if let receiptImage {

                        Image(uiImage: receiptImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 260)
                            .cornerRadius(12)
                    }

                    // Open camera.
                    Button {

                        if UIImagePickerController
                            .isSourceTypeAvailable(.camera) {

                            showCamera = true

                        } else {

                            showCameraError = true
                        }

                    } label: {

                        Label(
                            "Take Receipt Photo",
                            systemImage: "camera.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

                    if isScanning {

                        ProgressView("Scanning receipt...")
                    }

                    // Display editable receipt information.
                    if !scannedText.isEmpty && !isScanning {

                        VStack(alignment: .leading, spacing: 15) {

                            Text("Review Receipt Details")
                                .font(.headline)

                            TextField(
                                "Merchant Name",
                                text: $merchant
                            )
                            .textFieldStyle(.roundedBorder)

                            TextField(
                                "Total Amount (Rs.)",
                                text: $amount
                            )
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)

                            DatePicker(
                                "Receipt Date",
                                selection: $receiptDate,
                                displayedComponents: .date
                            )

                            Text("Please verify the details before saving.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Transfer the details to Add Expense.
                            Button {

                                let receipt = ScannedReceipt(
                                    merchant: merchant,
                                    amount: amount,
                                    date: receiptDate,
                                    notes: scannedText
                                )

                                onReceiptScanned(receipt)

                                dismiss()

                            } label: {

                                Text("Use Receipt Details")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .disabled(
                                merchant.trimmingCharacters(
                                    in: .whitespacesAndNewlines
                                ).isEmpty ||
                                Double(amount) == nil ||
                                (Double(amount) ?? 0) <= 0
                            )
                        }
                        .padding()
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(12)

                        // Display recognized text.
                        DisclosureGroup("View Extracted Text") {

                            Text(scannedText)
                                .font(.subheadline)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                                .padding(.top, 10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Receipt Scanner")
            .navigationBarTitleDisplayMode(.inline)

            // Open iPhone camera.
            .sheet(isPresented: $showCamera) {

                ReceiptCameraPicker { image in

                    receiptImage = image

                    scanReceipt(image)
                }
            }

            .alert(
                "Camera Unavailable",
                isPresented: $showCameraError
            ) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(
                    "Please use a physical iPhone to scan receipts."
                )
            }

            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Scan Receipt Using Vision

    private func scanReceipt(_ image: UIImage) {

        isScanning = true
        scannedText = ""
        merchant = ""
        amount = ""
        receiptDate = Date()

        Task.detached(priority: .userInitiated) {

            let request = VNRecognizeTextRequest()

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {

                guard let cgImage = image.cgImage else {
                    throw NSError(
                        domain: "ReceiptScanner",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Unable to read the receipt image."
                        ]
                    )
                }

                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: CGImagePropertyOrientation(
                        image.imageOrientation
                    ),
                    options: [:]
                )

                try handler.perform([request])

                let observations = request.results ?? []

                // Sort text from top to bottom.
                let sorted = observations.sorted {
                    $0.boundingBox.midY > $1.boundingBox.midY
                }

                let lines = sorted.compactMap {
                    $0.topCandidates(1).first?.string
                }

                let result = lines.joined(separator: "\n")

                // Extract possible receipt details.
                let extractedMerchant =
                    ReceiptScannerView.findMerchant(lines)

                let extractedAmount =
                    ReceiptScannerView.findTotal(lines)

                let extractedDate =
                    ReceiptScannerView.findDate(lines)

                await MainActor.run {

                    scannedText = result.isEmpty
                        ? "No text detected. Please try another photo."
                        : result

                    merchant = extractedMerchant
                    amount = extractedAmount
                    receiptDate = extractedDate ?? Date()

                    isScanning = false
                }

            } catch {

                await MainActor.run {

                    scannedText = "Scanning failed: \(error.localizedDescription)"
                    isScanning = false
                }
            }
        }
    }

    // Extract Merchant Name

    private static func findMerchant(
        _ lines: [String]
    ) -> String {

        // Merchant name is often near the top.
        for line in lines.prefix(5) {

            let cleaned = line.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            let containsLetters = cleaned.rangeOfCharacter(
                from: .letters
            ) != nil

            if containsLetters && cleaned.count >= 3 {
                return cleaned
            }
        }

        return ""
    }

    // Extract Total Amount

    private static func findTotal(
        _ lines: [String]
    ) -> String {

        // Prefer amounts beside TOTAL or AMOUNT DUE.
        let keywords = [
            "GRAND TOTAL",
            "NET TOTAL",
            "TOTAL DUE",
            "AMOUNT DUE",
            "TOTAL",
            "BALANCE DUE"
        ]

        let amountPattern =
            #"(?:Rs\.?|LKR)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?|\d+(?:\.\d{2})?)"#

        // Search from the bottom of the receipt.
        for line in lines.reversed() {

            let upper = line.uppercased()

            guard keywords.contains(where: {
                upper.contains($0)
            }) else {
                continue
            }

            // Ignore subtotal lines.
            if upper.contains("SUBTOTAL") ||
               upper.contains("SUB TOTAL") {
                continue
            }

            if let amount = extractLastAmount(
                from: line,
                pattern: amountPattern
            ) {
                return amount
            }
        }

        return ""
    }

    // Find the last amount in a line.
    private static func extractLastAmount(
        from line: String,
        pattern: String
    ) -> String? {

        guard let regex = try? NSRegularExpression(
            pattern: pattern
        ) else {
            return nil
        }

        let range = NSRange(
            line.startIndex..<line.endIndex,
            in: line
        )

        let matches = regex.matches(
            in: line,
            range: range
        )

        guard let match = matches.last,
              let valueRange = Range(
                match.range(at: 1),
                in: line
              ) else {
            return nil
        }

        return String(line[valueRange])
            .replacingOccurrences(of: ",", with: "")
    }

    // Extract Receipt Date

    private static func findDate(
        _ lines: [String]
    ) -> Date? {

        let formats = [
            "dd/MM/yyyy",
            "dd-MM-yyyy",
            "yyyy-MM-dd",
            "dd.MM.yyyy",
            "dd/MM/yy",
            "dd-MM-yy"
        ]

        let datePattern =
            #"\b(?:\d{1,4}[/.-]\d{1,2}[/.-]\d{2,4})\b"#

        guard let regex = try? NSRegularExpression(
            pattern: datePattern
        ) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.isLenient = false

        for line in lines {

            let range = NSRange(
                line.startIndex..<line.endIndex,
                in: line
            )

            for match in regex.matches(
                in: line,
                range: range
            ) {

                guard let matchRange = Range(
                    match.range,
                    in: line
                ) else {
                    continue
                }

                let dateText = String(line[matchRange])

                for format in formats {

                    formatter.dateFormat = format

                    if let date = formatter.date(
                        from: dateText
                    ) {
                        return date
                    }
                }
            }
        }

        return nil
    }
}

//  Camera Picker

struct ReceiptCameraPicker: UIViewControllerRepresentable {

    let onImageCaptured: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(
        context: Context
    ) -> UIImagePickerController {

        let picker = UIImagePickerController()

        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIImagePickerController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject,
                       UINavigationControllerDelegate,
                       UIImagePickerControllerDelegate {

        let parent: ReceiptCameraPicker

        init(_ parent: ReceiptCameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info:
                [UIImagePickerController.InfoKey: Any]
        ) {

            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(
            _ picker: UIImagePickerController
        ) {
            parent.dismiss()
        }
    }
}

//  Image Orientation Helper

extension CGImagePropertyOrientation {

    init(_ orientation: UIImage.Orientation) {

        switch orientation {

        case .up:
            self = .up

        case .down:
            self = .down

        case .left:
            self = .left

        case .right:
            self = .right

        case .upMirrored:
            self = .upMirrored

        case .downMirrored:
            self = .downMirrored

        case .leftMirrored:
            self = .leftMirrored

        case .rightMirrored:
            self = .rightMirrored

        @unknown default:
            self = .up
        }
    }
}

// Xcode Preview

#Preview {

    ReceiptScannerView { receipt in
        print(receipt.merchant)
    }
}

