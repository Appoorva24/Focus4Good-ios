import SwiftUI
import Vision
import UIKit

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var taskStore
    @Environment(UserStore.self) private var userStore
    
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var scannedImage: UIImage?
    @State private var recognizedText = ""
    @State private var isProcessing = false
    @State private var extractedTasks: [ParsedTask] = []
    @State private var showTaskPreview = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        NavigationStack {
            ZStack {
                if scannedImage == nil {
                    scannerPrompt
                } else if !recognizedText.isEmpty {
                    resultsView
                } else {
                    scannerPrompt
                }
                
                if isProcessing {
                    processingOverlay
                }
            }
            .navigationTitle("Scan Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(
                    image: $scannedImage,
                    sourceType: sourceType
                )
                .onDisappear {
                    if scannedImage != nil {
                        recognizeText()
                    }
                }
            }
            .sheet(isPresented: $showTaskPreview) {
                TaskPreviewSheet(tasks: $extractedTasks) {
                    dismiss()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Scanner Prompt
    private var scannerPrompt: some View {
        VStack(spacing: 28) {
            Spacer()
            
            // Icon
            Image(systemName: "doc.text.viewfinder")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(AppTheme.orange.opacity(0.6))
            
            // Title & Description
            VStack(spacing: 12) {
                Text("Scan Your Schedule")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                
                Text("Take a photo of your handwritten notes, planner, or to-do list")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Buttons
            VStack(spacing: 14) {
                // Camera button
                Button {
                    sourceType = .camera
                    showImagePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.headline)
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                // Photo library button
                Button {
                    sourceType = .photoLibrary
                    showImagePicker = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.headline)
                        Text("Choose from Library")
                            .font(.headline)
                    }
                    .foregroundStyle(AppTheme.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
            
            // Tips
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.orange)
                    Text("Tips for better results:")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                tipRow(icon: "checkmark", text: "Good lighting")
                tipRow(icon: "checkmark", text: "Clear handwriting")
                tipRow(icon: "checkmark", text: "Include times if possible")
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.orange)
            Text(text)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Scanned image
                if let image = scannedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
                
                // Recognized text
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundStyle(AppTheme.orange)
                        Text("Recognized Text")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    
                    Text(recognizedText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        parseTasksFromText()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Extract Tasks")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(recognizedText.isEmpty)
                    
                    Button {
                        // Reset and scan again
                        scannedImage = nil
                        recognizedText = ""
                        extractedTasks = []
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Scan Again")
                        }
                        .font(.headline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Processing Overlay
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processing image...")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("Recognizing text with AI")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray))
            )
        }
    }
    
    // MARK: - OCR Processing
    
    /// Recognize text from scanned image using Vision Framework
    private func recognizeText() {
        guard let image = scannedImage,
              let cgImage = image.cgImage else {
            showErrorAlert("Invalid image")
            return
        }
        
        isProcessing = true
        recognizedText = ""
        
        // Create Vision request
        let request = VNRecognizeTextRequest { request, error in
            DispatchQueue.main.async {
                self.isProcessing = false
                
                if let error = error {
                    self.showErrorAlert("OCR Error: \(error.localizedDescription)")
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    self.showErrorAlert("No text found")
                    return
                }
                
                // Extract text from all observations
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                if recognizedStrings.isEmpty {
                    self.showErrorAlert("No text could be recognized")
                    return
                }
                
                self.recognizedText = recognizedStrings.joined(separator: "\n")
                print("✅ Recognized text:\n\(self.recognizedText)")
            }
        }
        
        // Configure request for best accuracy
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Perform request
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.showErrorAlert("Failed to process image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Parse recognized text to extract tasks
    private func parseTasksFromText() {
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let tasks = TextParser.parseTasksFromText(self.recognizedText)
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.extractedTasks = tasks
                
                if tasks.isEmpty {
                    self.showErrorAlert("No tasks could be extracted from the text")
                } else {
                    self.showTaskPreview = true
                }
            }
        }
    }
    
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Image Picker (UIKit Bridge)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    let sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
