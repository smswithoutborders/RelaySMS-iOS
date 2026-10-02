//
//  HomepageView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 02/10/2026.
//

import SwiftUI

struct PlatformView: View {
    var body: some View {
        
    }
}

struct PlatformsPresentedView: View {
    var body: some View {
        VStack {
            
        }
    }
}

struct HomepageView: View {
    @State private var isPlatformsPresented = false
    var body: some View {

        ZStack {
            EmptyView()
                .ignoresSafeArea()
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: {
                isPlatformsPresented.toggle()
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.title)
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding() // Adds space from screen edges
        }
        .sheet(isPresented: $isPlatformsPresented) {
            PlatformsPresentedView()
        }
        
    }
}

#Preview {
    HomepageView()
}

#Preview {
    PlatformsPresentedView()
}

#Preview {
    PlatformView()
}
