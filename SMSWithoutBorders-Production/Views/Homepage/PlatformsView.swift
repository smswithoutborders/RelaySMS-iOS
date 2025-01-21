//
//  RecentsView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import SwiftUI

struct PlatformCard: View {
    @Binding var sheetIsPresented: Bool
    @State var name: String
    @State var isEnabled: Bool

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Button(action: {
                        sheetIsPresented.toggle()
                    }) {
                        VStack {
                            Image("Logo")
                                .resizable()
                                .renderingMode(isEnabled ? .none : .template)
                                .foregroundColor(isEnabled ? .clear : .gray)
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                                .padding()
                            Text(name)
                                .font(.caption2)
                                .foregroundColor(isEnabled ? .primary : .gray)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(isEnabled ? .accentColor : .gray)
                    
                }
                if(isEnabled) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: 50, y: -50)
                }
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
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Use your RelaySMS account")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)
                    
                    PlatformCard(
                        sheetIsPresented: $sheetIsPresented,
                        name: "RelaySMS account",
                        isEnabled: true)
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
                                sheetIsPresented: $sheetIsPresented,
                                name: "Signal",
                                isEnabled: false)
                        }
                    }
                    
                }
            }
            .navigationTitle("Available Platforms")
            .padding(16)
        }
    }
}

#Preview {
    PlatformsView()
}

struct PlatformCardDisabled: PreviewProvider {
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        PlatformCard(
            sheetIsPresented: $sheetIsPresented,
            name: "Template",
            isEnabled: true
        )
    }
}

struct PlatformCardEnabled: PreviewProvider {
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        PlatformCard(
            sheetIsPresented: $sheetIsPresented,
            name: "Template",
            isEnabled: false
        )
    }
}
