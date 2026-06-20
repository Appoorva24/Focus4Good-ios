import SwiftUI
import Auth
import Supabase

struct TwoFactorSetupView: View {
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var qrCodeImage: UIImage?
    @State private var factorId: String?
    @State private var secret: String = ""
    @State private var code: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Setup Two-Factor Authentication")
                        .font(.title2.bold())
                        .padding(.top)
                    
                    Text("Scan this QR code with an authenticator app like Google Authenticator or Authy.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal)
                    
                    if isLoading && qrCodeImage == nil {
                        ProgressView()
                            .padding(.vertical, 40)
                    } else if let qrCodeImage = qrCodeImage {
                        Image(uiImage: qrCodeImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                        
                        Text("Or enter this secret manually:")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        Text(secret)
                            .font(.system(.subheadline, design: .monospaced))
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .contextMenu {
                                Button("Copy") {
                                    UIPasteboard.general.string = secret
                                }
                            }
                    } else if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter 6-digit code")
                            .font(.subheadline.bold())
                        
                        TextField("000000", text: $code)
                            .keyboardType(.numberPad)
                            .font(.system(.title, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    
                    Button {
                        verifySetup()
                    } label: {
                        Group {
                            if isLoading && qrCodeImage != nil {
                                ProgressView().tint(.white)
                            } else {
                                Text("Verify & Enable")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule().fill(code.count == 6 ? AppTheme.orange : AppTheme.orange.opacity(0.4))
                        )
                    }
                    .disabled(code.count != 6 || isLoading)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .task {
                await startEnrollment()
            }
        }
    }
    
    private func startEnrollment() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await userStore.enrollMFA()
            self.factorId = response.id
            if let totp = response.totp {
                self.secret = totp.secret
                self.qrCodeImage = QRCodeGenerator.generate(from: totp.uri)
            } else {
                self.errorMessage = "Failed to generate QR Code. Please try again."
            }
        } catch {
            self.errorMessage = "Failed to start setup: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func verifySetup() {
        guard let factorId = factorId, code.count == 6 else { return }
        
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await userStore.verifyMFAEnrollment(factorId: factorId, code: code)
                dismiss()
            } catch {
                self.errorMessage = "Verification failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
