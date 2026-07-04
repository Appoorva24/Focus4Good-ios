import SwiftUI
import AuthenticationServices

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
            // ── Rich gradient background ─────────────────────
            AppTheme.pageGradient
                .ignoresSafeArea()

            if userStore.isMfaRequired {
                TwoFactorVerifyView(email: email)
            } else {
                ScrollView {
                    VStack(spacing: 28) {
                    Spacer().frame(height: 32)

                    // ── Logo / Header ─────────────────────────────
                    VStack(spacing: 16) {
                        // Logo with subtle glow
                        ZStack {
                            Circle()
                                .fill(AppTheme.orange.opacity(0.12))
                                .frame(width: 120, height: 120)
                                .blur(radius: 10)

                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        }

                        Text("Focus4Good")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.orange, AppTheme.orangeDeep],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.warmTextSecondary)
                    }

                    // ── Form Fields (glass card) ─────────────────
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
                    .padding(20)
                    .glassCard()
                    .padding(.horizontal, 20)

                    // ── Forgot Password Button ─────────────────────────────
                    if !isSignUp {
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.orange)
                        }
                        .padding(.horizontal, 24)
                    }

                    // ── Error Message ─────────────────────────────
                    if let error = userStore.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(AppTheme.destructive)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // ── Submit Button (gradient) ─────────────────
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
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule().fill(
                                isFormValid
                                    ? AnyShapeStyle(AppTheme.buttonGradient)
                                    : AnyShapeStyle(AppTheme.orange.opacity(0.3))
                            )
                        )
                        .shadow(color: isFormValid ? AppTheme.orange.opacity(0.3) : .clear, radius: 12, y: 6)
                    }
                    .disabled(!isFormValid || userStore.isLoading)
                    .padding(.horizontal, 24)
                    .animation(.easeInOut(duration: 0.2), value: isFormValid)

                    // ── Or Divider ───────────────────────────────
                    HStack(spacing: 12) {
                        Capsule()
                            .fill(AppTheme.warmTextSecondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or continue with")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warmTextSecondary)
                            .fixedSize()
                        Capsule()
                            .fill(AppTheme.warmTextSecondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 24)

                    // ── Social Sign-In ────────────────────────────
                    VStack(spacing: 12) {
                        // Sign in with Apple
                        SignInWithAppleButton(.signIn) { request in
                            let hashedNonce = userStore.prepareAppleSignIn()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = hashedNonce
                        } onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                    Task {
                                        await userStore.handleAppleSignIn(credential: credential)
                                    }
                                }
                            case .failure(let error):
                                if (error as NSError).code != 1001 {
                                    userStore.errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 56)
                        .clipShape(Capsule())

                        // Sign in with Google
                        Button {
                            Task {
                                await userStore.signInWithGoogle()
                            }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "4285F4"))
                                        .frame(width: 24, height: 24)
                                    Text("G")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                                Text("Sign in with Google")
                                    .font(.headline)
                            }
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                        }
                        .disabled(userStore.isLoading)
                    }
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
                                .foregroundStyle(AppTheme.warmTextSecondary)
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

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? AppTheme.orange : AppTheme.warmTextSecondary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField(placeholder, text: $text)
                .font(.subheadline)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused ? AppTheme.orange.opacity(0.6) : Color.white.opacity(0.1),
                    lineWidth: isFocused ? 1.5 : 0.5
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        )
    }
}

// MARK: - Password Field Component

private struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(isFocused ? AppTheme.orange : AppTheme.warmTextSecondary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

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
            .focused($isFocused)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .font(.caption)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground).opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    isFocused ? AppTheme.orange.opacity(0.6) : Color.white.opacity(0.1),
                    lineWidth: isFocused ? 1.5 : 0.5
                )
                .animation(.easeInOut(duration: 0.2), value: isFocused)
        )
    }
}
