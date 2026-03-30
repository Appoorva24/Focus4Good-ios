//
//  BraindumpSavedView.swift
//  Focus4Good
//
//  Created by Shreya on 20/03/26.
//

import SwiftUI

struct BraindumpSavedView: View {

    let savedText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Saved text preview
                Text(savedText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemGray6))
                    )

                // Badge
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color("CalmOrange"))

                // Title
                Text("Well done!")
                    .font(.title2)
                    .fontWeight(.bold)

                // Subtitle
                Text("Letting your thoughts out takes efforts")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                // Points
                Text("+ 10 Focus Points")
                    .font(.headline)
                    .foregroundStyle(Color("CalmOrange"))
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("CalmOrange"))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BraindumpSavedView(savedText: "I have a lot of things to do today. I am very confused.")
    }
}
