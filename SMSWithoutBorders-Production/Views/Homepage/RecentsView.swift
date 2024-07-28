//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI

struct RecentsView: View {
    @Environment(\.managedObjectContext) var datastore
//    @FetchRequest(sortDescriptors: []) var encryptedContents: FetchedResults<EncryptedContentsEntity>
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @Binding var codeVerifier: String
    @State var isLoggedIn: Bool = false
    
    @State var showAvailablePlatforms: Bool = false
    @State var showComposePlatforms: Bool = false
    
    @State var loginSheetVisible: Bool = false
    @State var loginFailed: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                if isLoggedIn {
                    VStack {
                        Spacer()
                        Text("No Recent Messages")
                            .font(.largeTitle)
                    }
                }
                else {
                    VStack {
                        VStack {
                            Button("Log in") {
                                loginSheetVisible = true
                            }
                            .sheet(isPresented: $loginSheetVisible) {
                                LoginSheetView(completed: $isLoggedIn,
                                               failed: $loginFailed)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        
                        VStack {
                            Button("Create account") {
                                
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                    .padding()

                }
                ZStack(alignment: .bottomTrailing) {
                    List {
                    }
                    
                    if isLoggedIn {
                        VStack {
                            VStack {
                                Button(action: {
                                    showComposePlatforms = true
                                }, label: {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(.title))
                                        .frame(width: 57, height: 50)
                                        .foregroundColor(Color.white)
                                        .padding(.bottom, 7)
                                })
                                .background(Color.blue)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.3),
                                        radius: 3,
                                        x: 3,
                                        y: 3)
                                .padding()
                                .sheet(isPresented: $showComposePlatforms) {
                                    OfflineAvailablePlatformsSheetsView()
                                }
                            }
                            
                            VStack {
                                Button(action: {
                                    showAvailablePlatforms = true
                                }, label: {
                                    Image(systemName: "rectangle.stack.badge.plus")
                                    .font(.system(.title))
                                        .frame(width: 57, height: 50)
                                        .foregroundColor(Color.white)
                                        .padding(.bottom, 7)
                                })
                                .background(Color.blue)
                                .cornerRadius(18)
                                .shadow(color: Color.black.opacity(0.3),
                                        radius: 3,
                                        x: 3,
                                        y: 3)
                                .padding()
                                .sheet(isPresented: $showAvailablePlatforms) {
                                    OnlineAvailablePlatformsSheetsView(codeVerifier: $codeVerifier)
                                }
                            }
                        }
                    } 
                }
                
            }
            .navigationTitle("Recents")
        }
    }
}

struct RecentsView_Preview: PreviewProvider {
    static var previews: some View {
        @State var codeVerifier: String = ""
        @State var isLoggedIn: Bool = false
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        return RecentsView(codeVerifier: $codeVerifier, isLoggedIn: isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
