import SwiftUI

struct NGOListView: View {
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    @State private var selectedNGO: NGO?
    private let ngos = DummyData.ngos

    var body: some View {
        // No NavigationStack — lives inside HomeView's NavigationStack
        List {
            ForEach(ngos) { ngo in
                Button { selectedNGO = ngo } label: { NGORowView(ngo: ngo) }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .navigationTitle("NGO Connect")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedNGO) { ngo in
            NGODetailView(ngo: ngo)
        }
    }
}

struct NGORowView: View {
    let ngo: NGO

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14).fill(Color(.systemGray6)).frame(height: 160)
                    .overlay {
                        Image("ngo").resizable().scaledToFill().frame(height: 160).clipped()
                            .overlay(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.1)))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                if ngo.isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.white).font(.caption)
                        Text("Verified").font(.caption.bold()).foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Capsule().fill(Color.green))
                    .padding(12)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(ngo.name).font(.headline).foregroundStyle(AppTheme.textPrimary)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill").font(.caption).foregroundStyle(AppTheme.orange)
                    Text(ngo.location).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Text(ngo.mission).font(.caption).foregroundStyle(AppTheme.textSecondary).lineLimit(2)
                HStack(spacing: 24) {
                    ngoStat(value: "\(ngo.studentCount / 1000)K+", label: "Students")
                    ngoStat(value: "\(ngo.yearsActive)", label: "Years")
                    ngoStat(value: "\(ngo.projectCount)", label: "Projects")
                }
                .padding(.top, 4)
            }
            .padding(.top, 12)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemBackground)))
    }

    private func ngoStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundStyle(AppTheme.orange)
            Text(label).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
    }
}

struct NGODetailView: View {
    let ngo: NGO
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    @State private var selectedEvent: VolunteerEvent?
    @State private var showRegistration = false
    private let events: [VolunteerEvent]

    init(ngo: NGO) {
        self.ngo = ngo
        self.events = DummyData.volunteerEvents(for: ngo.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)).frame(height: 220)
                    .overlay {
                        Image("ngo").resizable().scaledToFill().frame(height: 220).clipped()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ngo.name).font(.title2.bold())
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill").font(.caption).foregroundStyle(AppTheme.orange)
                                Text(ngo.location).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        Spacer()
                        if ngo.isVerified {
                            Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(.green)
                        }
                    }

                    HStack(spacing: 0) {
                        statPill(value: "\(ngo.studentCount / 1000)K+", label: "Students")
                        Divider().frame(height: 36)
                        statPill(value: "\(ngo.yearsActive)", label: "Years Active")
                        Divider().frame(height: 36)
                        statPill(value: "\(ngo.projectCount)", label: "Projects")
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Our Mission").font(.headline)
                        Text(ngo.mission).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Founder").font(.headline)
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill").font(.title).foregroundStyle(AppTheme.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ngo.founderName).font(.subheadline.bold())
                                Text(ngo.founderPhone).font(.caption).foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }

                    if !events.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Events").font(.headline)
                            ForEach(events) { event in
                                Button { selectedEvent = event } label: { EventRowView(event: event) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }

                    Button { showRegistration = true } label: {
                        Text("Register as Volunteer").font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Capsule().fill(AppTheme.orange))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .navigationTitle(ngo.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedEvent) { event in
            EventDetailView(event: event, ngo: ngo)
        }
        .navigationDestination(isPresented: $showRegistration) {
            VolunteerRegistrationView(ngo: ngo)
        }
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline.bold()).foregroundStyle(AppTheme.orange)
            Text(label).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
    }
}

struct EventRowView: View {
    let event: VolunteerEvent

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(event.eventDate.formatted(.dateTime.day())).font(.title3.bold()).foregroundStyle(AppTheme.orange)
                Text(event.eventDate.formatted(.dateTime.month(.abbreviated))).font(.caption.bold()).foregroundStyle(AppTheme.textSecondary)
            }
            .frame(width: 44).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.orange.opacity(0.1)))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.subheadline.bold()).foregroundStyle(AppTheme.textPrimary).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill").font(.caption2).foregroundStyle(AppTheme.orange)
                    Text(event.location).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill").font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    Text("\(event.participantCount) participants").font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }
}

struct EventDetailView: View {
    let event: VolunteerEvent
    let ngo: NGO
    @State private var showConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)).frame(height: 200)
                    .overlay {
                        Image("ngo").resizable().scaledToFill().frame(height: 200).clipped()
                            .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.15)))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(event.title).font(.title2.bold())
                        HStack(spacing: 4) {
                            Image(systemName: "building.2.fill").font(.caption).foregroundStyle(AppTheme.orange)
                            Text(ngo.name).font(.subheadline).foregroundStyle(AppTheme.orange)
                        }
                    }

                    VStack(spacing: 12) {
                        infoRow(icon: "calendar", label: "Date", value: event.eventDate.formatted(.dateTime.day().month(.wide).year()))
                        infoRow(icon: "clock.fill", label: "Time", value: "\(event.startTime.formatted(.dateTime.hour().minute())) – \(event.endTime.formatted(.dateTime.hour().minute()))")
                        infoRow(icon: "location.fill", label: "Location", value: event.location)
                        infoRow(icon: "tag.fill", label: "Type", value: event.eventType)
                        infoRow(icon: "person.2.fill", label: "Participants", value: "\(event.participantCount) registered")
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this Event").font(.headline)
                        Text(event.description).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button { showConfirmation = true } label: {
                        Text("Confirm Attendance").font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Capsule().fill(AppTheme.orange))
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Attendance Confirmed!", isPresented: $showConfirmation) {
            Button("Great!", role: .cancel) {}
        } message: { Text("You're registered for \(event.title). See you there!") }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(AppTheme.orange).frame(width: 20)
            Text(label).font(.subheadline).foregroundStyle(AppTheme.textSecondary).frame(width: 80, alignment: .leading)
            Text(value).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
    }
}

struct VolunteerRegistrationView: View {
    let ngo: NGO
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var emergencyContact = ""
    @State private var availableDays = ""
    @State private var pastExperience = ""
    @State private var showSuccess = false

    private var isFormValid: Bool { !fullName.isEmpty && !email.isEmpty && !phone.isEmpty }

    var body: some View {
        List {
            Section {
                formField("Full Name", text: $fullName, icon: "person.fill")
                formField("Email", text: $email, icon: "envelope.fill").keyboardType(.emailAddress).autocapitalization(.none)
                formField("Phone", text: $phone, icon: "phone.fill").keyboardType(.phonePad)
            } header: { Text("Personal Details").textCase(nil) }

            Section {
                formField("Emergency Contact", text: $emergencyContact, icon: "phone.badge.plus.fill")
                formField("Available Days (e.g. Mon, Wed)", text: $availableDays, icon: "calendar")
            } header: { Text("Availability").textCase(nil) }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Past Experience", systemImage: "briefcase.fill").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    TextEditor(text: $pastExperience).frame(minHeight: 80).font(.subheadline)
                }
            } header: { Text("Experience").textCase(nil) }

            Section {
                Button { submitRegistration() } label: {
                    Text("Submit Registration").font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Capsule().fill(isFormValid ? AppTheme.orange : Color(.systemGray3)))
                }
                .disabled(!isFormValid)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Volunteer Registration")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Registration Submitted!", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: { Text("Thank you for registering with \(ngo.name). They will contact you soon.") }
    }

    private func formField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(AppTheme.orange).frame(width: 20)
            TextField(placeholder, text: text).font(.subheadline)
        }
    }

    private func submitRegistration() {
        Task {
            await volunteerStore.registerForNGO(
                userId: userStore.currentUser?.id ?? DummyData.currentUser.id,
                ngoId: ngo.id, fullName: fullName, email: email, phone: phone,
                emergencyContact: emergencyContact, availableDays: availableDays, pastExperience: pastExperience
            )
        }
        showSuccess = true
    }
}
