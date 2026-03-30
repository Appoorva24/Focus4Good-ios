import SwiftUI

// MARK: - NGO List View

struct NGOListView: View {
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.orange.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "building.columns.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(ngo.name)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)

                        if ngo.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(AppTheme.orange)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(ngo.location)
                            .font(.caption)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(ngo.mission)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            // Stats row
            HStack(spacing: 20) {
                statBadge(icon: "person.3.fill", value: "\(ngo.studentCount)", label: "Students")
                statBadge(icon: "calendar", value: "\(ngo.yearsActive)yr", label: "Active")
                statBadge(icon: "folder.fill", value: "\(ngo.projectCount)", label: "Projects")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(AppTheme.orange)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.textPrimary)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

// MARK: - NGO Detail View

struct NGODetailView: View {
    let ngo: NGO
    @Environment(VolunteerStore.self) private var volunteerStore
    @Environment(UserStore.self) private var userStore

    private var events: [VolunteerEvent] {
        volunteerStore.events(for: ngo)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(ngo.name)
                            .font(.title2.bold())
                        if ngo.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.orange)
                        }
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                        Text(ngo.location)
                            .font(.subheadline)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                }

                // Mission
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mission")
                        .font(.headline)
                    Text(ngo.mission)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                // Founder
                VStack(alignment: .leading, spacing: 8) {
                    Text("Founder")
                        .font(.headline)
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.orange.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "person.fill")
                                .foregroundStyle(AppTheme.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ngo.founderName)
                                .font(.subheadline.weight(.medium))
                            Text(ngo.founderPhone)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                // Events
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming Events")
                        .font(.headline)

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
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(ngo.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Event Card

struct EventCardView: View {
    let event: VolunteerEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(event.eventType)
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppTheme.orange.opacity(0.15)))

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(event.participantCount)")
                        .font(.caption)
                }
                .foregroundStyle(AppTheme.textSecondary)
            }

            Text(event.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(event.description)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(event.eventDate.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                }

                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("\(event.startTime.formatted(.dateTime.hour().minute())) – \(event.endTime.formatted(.dateTime.hour().minute()))")
                        .font(.caption)
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption2)
                    Text(event.location)
                        .font(.caption)
                }
            }
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
