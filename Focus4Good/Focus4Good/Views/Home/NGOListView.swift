import SwiftUI

// MARK: - NGO List View

struct NGOListView: View {
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if volunteerStore.ngos.isEmpty {
                    emptyState
                } else {
                    ForEach(volunteerStore.ngos) { ngo in
                        NavigationLink(value: ngo) {
                            NGOCardView(ngo: ngo)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("NGO Connect")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: NGO.self) { ngo in
            NGODetailView(ngo: ngo)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            Image(systemName: "building.2.crop.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(AppTheme.orange.opacity(0.5))

            Text("No NGOs available")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.textPrimary)

            Text("Check back later for volunteering opportunities")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - NGO Card

struct NGOCardView: View {
    let ngo: NGO

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image with Verified Badge
            ZStack(alignment: .topLeading) {
                if let image = UIImage(named: ngo.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 180)
                }

                if ngo.isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                        Text("Verified")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .clipShape(Capsule())
                    .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text(ngo.name)
                    .font(.title3.bold())
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "location.north.fill") // Paperplane-ish icon matching screenshot
                        .font(.caption2)
                        .rotationEffect(.degrees(45))
                        .foregroundStyle(AppTheme.orange)
                    Text(ngo.location)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Text(ngo.mission)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
                    .padding(.top, 2)

                // Stats row
                HStack(spacing: 24) {
                    statBadgeStyle(value: "\(String(format: "%.0f", Double(ngo.studentCount)/1000.0))K+", label: "Students")
                    statBadgeStyle(value: "\(ngo.yearsActive)", label: "Years")
                    statBadgeStyle(value: "\(ngo.projectCount)", label: "Projects")
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
    }

    private func statBadgeStyle(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.orange)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }
}

// MARK: - NGO Detail View

struct NGODetailView: View {
    let ngo: NGO
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    @State private var showingRegistration = false

    private var events: [VolunteerEvent] {
        volunteerStore.events(for: ngo)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image
                if let image = UIImage(named: ngo.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 250)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(ngo.name)
                                .font(.title.bold())
                                .foregroundStyle(AppTheme.textPrimary)
                            Spacer()
                            if ngo.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.green)
                            }
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "location.north.fill")
                                .font(.caption)
                                .rotationEffect(.degrees(45))
                                .foregroundStyle(AppTheme.orange)
                            Text(ngo.location)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }

                    // Stats Bar
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("\(String(format: "%.0f", Double(ngo.studentCount)/1000.0))K+")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.orange)
                            Text("Students")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Divider()
                        Spacer()
                        VStack(spacing: 4) {
                            Text("\(ngo.yearsActive)")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.orange)
                            Text("Years Active")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Divider()
                        Spacer()
                        VStack(spacing: 4) {
                            Text("\(ngo.projectCount)")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.orange)
                            Text("Projects")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Mission
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Our Mission")
                            .font(.title3.bold())
                        Text(ngo.mission)
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Founder
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Founder")
                            .font(.title3.bold())
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.orange.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                Image(systemName: "person.fill")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.orange)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ngo.founderName)
                                    .font(.headline)
                                Text(ngo.founderPhone)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }

                    // Events
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Upcoming Events")
                            .font(.title3.bold())

                        if events.isEmpty {
                            Text("No upcoming events")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(events) { event in
                                EventCardView(event: event)
                            }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 80) // Space for floating button
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(ngo.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            Button {
                showingRegistration = true
            } label: {
                Text("Register as Volunteer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.orange)
                    .clipShape(Capsule())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
        }
        .navigationDestination(isPresented: $showingRegistration) {
            VolunteerRegistrationView(ngo: ngo)
        }
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let event: VolunteerEvent

    var body: some View {
        HStack(spacing: 16) {
            // Date Badge
            VStack(spacing: 4) {
                Text(event.eventDate.formatted(.dateTime.day()))
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.orange)
                Text(event.eventDate.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(width: 56, height: 64)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "location.north.fill")
                        .font(.caption2)
                        .rotationEffect(.degrees(45))
                        .foregroundStyle(AppTheme.orange)
                    Text(event.location)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("\(event.participantCount) participants")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(.systemGray3))
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Volunteer Registration View
struct VolunteerRegistrationView: View {
    let ngo: NGO
    @Environment(\.dismiss) private var dismiss
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    
    // Form fields
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var pastExperience: String = ""
    
    @State private var showSuccessAlert = false
    
    // Check if user is already registered
    private var isRegistered: Bool {
        guard let user = userStore.currentUser else { return false }
        return volunteerStore.isRegistered(ngoId: ngo.id, userId: user.id)
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Personal Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Details")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        VStack(spacing: 0) {
                            RegistrationTextField(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                            Divider().padding(.leading, 40)
                            RegistrationTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                                .keyboardType(.emailAddress)
                            Divider().padding(.leading, 40)
                            RegistrationTextField(icon: "phone.fill", placeholder: "Phone", text: $phone)
                                .keyboardType(.phonePad)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Experience Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Experience")
                            .font(.headline)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "briefcase.fill")
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .padding(.top, 8)
                                
                                ZStack(alignment: .topLeading) {
                                    if pastExperience.isEmpty {
                                        Text("Past Experience")
                                            .foregroundStyle(Color(.systemGray3))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    TextEditor(text: $pastExperience)
                                        .frame(minHeight: 120)
                                        .scrollContentBackground(.hidden)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Volunteer Registration")
            .navigationBarTitleDisplayMode(.inline)
            
            // Fixed Submit Button
            VStack {
                Spacer()
                Button {
                    Task {
                        if let user = userStore.currentUser {
                            await volunteerStore.registerForNGO(
                                userId: user.id,
                                ngoId: ngo.id,
                                fullName: fullName,
                                email: email,
                                phone: phone,
                                pastExperience: pastExperience
                            )
                            showSuccessAlert = true
                        }
                    }
                } label: {
                    Text(isRegistered ? "Already Registered" : "Submit Registration")
                        .font(.headline)
                        .foregroundColor(isRegistered ? AppTheme.textSecondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isRegistered ? Color(.systemGray4) : AppTheme.orange)
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                }
                .disabled(isRegistered || fullName.isEmpty || email.isEmpty || phone.isEmpty)
            }
            
            // Custom Success Overlay
            if showSuccessAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                
                VStack(spacing: 16) {
                    Text("Registration Submitted!")
                        .font(.headline)
                    Text("Thank you for registering with \(ngo.name). They will contact you soon.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    
                    Button {
                        showSuccessAlert = false
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundStyle(AppTheme.orange)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 40)
                .shadow(radius: 20)
                .zIndex(2)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSuccessAlert)
        // Form fields start empty — user fills in their own details
    }
}

struct RegistrationTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.orange)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}
