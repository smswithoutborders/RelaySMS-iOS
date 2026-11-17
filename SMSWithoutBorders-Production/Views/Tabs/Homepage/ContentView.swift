//
//  ContentView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 17/11/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let payloadId: UUID
    
    let platformName: String
    let platformDisplayName: String
    let subject: String
    let from: String
    let to: String
    let text: String
    
    @State private var editIsPresented: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Text(subject)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 30)
            
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.blue)
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading) {
                    Text(from)
                    Text(String(localized: "to: \(to)"))
                }
            }
            .padding(.bottom, 30)

            Text(text)
        }
        .navigationDestination(isPresented: $editIsPresented) {
            ComposerManagerView(
                platformName: platformName,
                platformDisplayName: platformDisplayName,
                to: to,
                subject: subject,
                content: text
            )
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(String(localized: "Supported platforms"))
        .toolbar {
            ToolbarItem {
                Button(role: .destructive, action: {
                    deleteItem(with: payloadId)
                    dismiss()
                }) {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
                .tint(.red)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    editIsPresented = true
                }) {
                    Label(String(localized: "Edit"), systemImage: "pencil.circle")
                }
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    func deleteItem(with targetID: UUID) {
        do {
            try modelContext.delete(
                model: Payloads.self,
                where: #Predicate { $0.id == targetID }
            )
            
//            try modelContext.save()
        } catch {
            print("Failed to delete item: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ContentView(
        payloadId: UUID(),
        platformName: "bluesky",
        platformDisplayName: "Bluesky",
        subject: "Meeting Reminder",
        from: "okotsu@gmail.com",
        to: "developers@afkanerd.com",
        text: "The design has to communicate identity vs anonymity as the core distinction, not just online vs offline."
    )
}
