import SwiftUI

struct AddCommunityView: View {
    @Binding var addCommunity: Bool
    @Environment(CommunityStore.self) private var communityStore
    @Environment(UserStore.self)      private var userStore

    @State private var nameOfCommunity: String = ""
    @State private var category: String = ""
    @State private var description: String = ""
    @State private var isPrivate: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Image("PersonImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        // Photo picker — future implementation
                    } label: {
                        Text("Add Cover Photo")
                            .foregroundStyle(AppTheme.orange)
                    }
                }

                VStack(spacing: 0) {
                    HStack {
                        Text("Name")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        TextField("Community Name", text: $nameOfCommunity)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.gray)
                    }
                    .padding()

                    Divider()

                    HStack {
                        Text("Category").font(.headline)
                        Spacer()
                        Menu {
                            Button("Hyperactivity")  { category = "Hyperactivity" }
                            Button("Focus")          { category = "Focus" }
                            Button("Mindfulness")    { category = "Mindfulness" }
                            Button("Study Tips")     { category = "Study Tips" }
                            Button("Mental Health")  { category = "Mental Health" }
                            Button("Volunteering")   { category = "Volunteering" }
                            Button("Other")          { category = "Other" }
                        } label: {
                            HStack(spacing: 4) {
                                Text(category.isEmpty ? "Select" : category)
                                    .foregroundStyle(category.isEmpty ? .gray : .primary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                    .padding()

                    Divider()

                    VStack(alignment: .leading) {
                        TextEditor(text: $description)
                            .frame(height: 120)
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(1.0), lineWidth: 1)
                )
                .padding(.horizontal)

                VStack(spacing: 0) {
                    HStack {
                        Toggle(isOn: $isPrivate) {
                            Text("Private Community")
                                .font(.headline)
                                .foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(1.0), lineWidth: 1)
                )
                .padding(.horizontal)

                Button {
                    Task {
                        let userId = userStore.currentUser?.id ?? UUID()
                        await communityStore.createCommunity(
                            name: nameOfCommunity,
                            description: description.isEmpty
                                ? "A community about \(category.isEmpty ? "various topics" : category)."
                                : description,
                            categoryId: nil,
                            isPrivate: isPrivate,
                            userId: userId
                        )
                        addCommunity = false
                    }
                } label: {
                    Text("Create Community")
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(nameOfCommunity.isEmpty ? AppTheme.orange.opacity(0.4) : AppTheme.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
                .disabled(nameOfCommunity.isEmpty)
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()
            }
            .navigationBarTitle("Add Community")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        addCommunity = false
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}

#Preview {
    AddCommunityView(addCommunity: .constant(true))
        .environment(CommunityStore.shared)
        .environment(UserStore.shared)
}
