import SwiftUI

// MARK: - AuthView

struct AuthView: View {
    @Environment(UserStore.self) private var userStore

    /// Called by Focus4GoodApp when authentication succeeds
    let onSuccess: () -> Void

    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showForgotPassword = false

    private var isFormValid: Bool {
        if isSignUp {
            return !fullName.isEmpty && !email.isEmpty && password.count >= 6 && password == confirmPassword
        } else {
            return !email.isEmpty && password.count >= 6
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if userStore.isMfaRequired {
                TwoFactorVerifyView(email: email)
            } else {
                ScrollView {
                    VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    // ── Logo / Header ─────────────────────────────
                    VStack(spacing: 16) {
                        // SwiftUI-drawn logo on an orange background circle
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .shadow(color: AppTheme.orange.opacity(0.35), radius: 12, y: 4)

                        Text("Focus4Good")
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    // ── Form Fields ───────────────────────────────
                    VStack(spacing: 16) {
                        if isSignUp {
                            AuthTextField(
                                icon: "person",
                                placeholder: "Full Name",
                                text: $fullName
                            )
                        }

                        AuthTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            autocapitalization: .never
                        )

                        AuthPasswordField(
                            placeholder: "Password",
                            text: $password,
                            showPassword: $showPassword
                        )

                        if isSignUp {
                            AuthPasswordField(
                                placeholder: "Confirm Password",
                                text: $confirmPassword,
                                showPassword: $showPassword
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    // ── Forgot Password Button ─────────────────────────────
                    if !isSignUp {
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.orange)
                        }
                        .padding(.horizontal, 24)
                    }

                    // ── Error Message ─────────────────────────────
                    if let error = userStore.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // ── Submit Button ─────────────────────────────
                    Button {
                        Task {
                            if isSignUp {
                                await userStore.signUp(fullName: fullName, email: email, password: password)
                            } else {
                                await userStore.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        Group {
                            if userStore.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.headline)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule().fill(
                                isFormValid ? AppTheme.orange : AppTheme.orange.opacity(0.4)
                            )
                        )
                    }
                    .disabled(!isFormValid || userStore.isLoading)
                    .padding(.horizontal, 24)

                    // ── Toggle Sign In / Sign Up ──────────────────
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSignUp.toggle()
                            fullName = ""
                            email = ""
                            password = ""
                            confirmPassword = ""
                            userStore.errorMessage = nil
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(isSignUp ? "Sign In" : "Sign Up")
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.orange)
                        }
                        .font(.subheadline)
                    }

                    Spacer()
                }
            }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        // Watch for successful authentication → notify parent
        .onChange(of: userStore.isAuthenticated) { _, isAuth in
            if isAuth { onSuccess() }
        }
    }
}

// MARK: - Text Field Component

private struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.orange)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .font(.subheadline)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

// MARK: - Password Field Component

private struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(AppTheme.orange)
                .frame(width: 20)

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.subheadline)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(AppTheme.textSecondary)
                    .font(.caption)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}
