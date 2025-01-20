//
//  RecentsView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import SwiftUI

struct PlatformCard: View {
    @State var name: String
    
    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Button(action: {
                    }) {
                        VStack {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 40)
                                .padding()
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    
                }
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .offset(x: 40, y: -30)
            }
        }
    }
}

struct PlatformsView: View {
    @State private var sheetIsPresented: Bool = false
    
    let data = (1...5).map { "Item \($0)" }
    
    let columns = [
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10),
        GridItem(.flexible(minimum: 40), spacing: 10)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Use your RelaySMS account")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
                
                PlatformCard(name: "RelaySMS account")
                    .padding(.bottom, 32)
                    .sheet(isPresented: $sheetIsPresented) {
                        Text("Hello world")
                    }
                

                Text("Use your online accounts")
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)

                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(data, id: \.self) { item in
                        PlatformCard(
                            name: "Signal"
                        )
                    }
                }
                
            }
        }
        .padding(16)
    }
}

#Preview {
    PlatformsView()
}
