//
//  Recents1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 21/01/2025.
//

import SwiftUI

struct Recents1: View {
    @State private var sheetCreateAccountIsPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                VStack {
                    Text("Internet required")
                        .font(.headline)
                    Text("This features requires you to have an internet connection")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 50) {
                    Button(action: {
                        sheetCreateAccountIsPresented.toggle()
                    }) {
                        VStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                            Text("Create Account")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    .sheet(isPresented: $sheetCreateAccountIsPresented) {
                        Text("Hello world")
                    }

                    Button(action: {}) {
                        VStack {
                            Image(systemName: "person.crop.circle.badge")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                            Text("Log in")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
                .padding()
                
                Divider()
                    .padding(.bottom, 16)
                
                VStack {
                    Text("Offline features")
                        .font(.headline)
                    Text("This features work without an internet connection!")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                HStack(spacing: 50) {
                    Button(action: {}) {
                        VStack {
                            Image("Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                            Text("Try RelaySMS")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    
                    Button(action: {}) {
                        VStack {
                            Image(systemName: "wifi.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 75)
                            Text("SMS Login")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
                .padding()
            }
            .navigationTitle("RelaySMS")
            .padding()
        }
        
    }
}

#Preview {
    Recents1()
}
