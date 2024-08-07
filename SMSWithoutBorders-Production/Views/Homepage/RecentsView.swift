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
    
    @State var errorMessage: String = ""
    @State var otpRetryTimer: Int?
    @State var isLoggedIn: Bool = false

    @State var showAvailablePlatforms: Bool = false
    @State var showComposePlatforms: Bool = false
    
    @State var loginSheetVisible: Bool = false
    @State var signupSheetVisible: Bool = false
    @State var loginFailed: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                if !isLoggedIn {
                    Spacer()
                    VStack {
                        Image("NoRecents")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .padding(.bottom, 20)
                        Text("No recent messages")
                            .font(.title)
                    }
                    .padding()
                    Spacer()
                    
                    VStack {
                        Button {
                            loginSheetVisible = true
                        } label: {
                            Text("Log in")
                                .bold()
                                .frame(maxWidth: .infinity, maxHeight: 20)
                        }
                        .sheet(isPresented: $loginSheetVisible) {
                            LoginSheetView(completed: $isLoggedIn,
                                           failed: $loginFailed)
                        }
                        .buttonStyle(.borderedProminent)

                        Button {
                            signupSheetVisible = true
                        } label: {
                            Text("Create account")
                                .bold()
                                .frame(maxWidth: .infinity, maxHeight: 20)
                        }
                        .sheet(isPresented: $signupSheetVisible) {
                            SignupSheetView(
                                completed: $isLoggedIn,
                                failed: $loginFailed,
                                otpRetryTimer: otpRetryTimer ?? 0,
                                errorMessage: errorMessage)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()

                } else {
                    ZStack(alignment: .bottomTrailing) {
                        List {
                        }
                        
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
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 0,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                }
            }
            .navigationTitle("Recents")
        }
    }
}

struct RecentsView_Preview: PreviewProvider {
    static var previews: some View {
        @State var codeVerifier: String = ""
        @State var isLoggedIn: Bool = true
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)

        return RecentsView(codeVerifier: $codeVerifier, isLoggedIn: isLoggedIn)
            .environment(\.managedObjectContext, container.viewContext)
    }
}
