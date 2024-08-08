//
//  RecentsView.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 26/07/2024.
//

import SwiftUI


struct Card: View {
    @State var logo: Image
    @State var subject: String
    @State var toAccount: String
    @State var messageBody: String
    @State var date: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.white)

            HStack {
                logo
                    .resizable()
                    .frame(width: 50, height: 50)
                
                VStack {
                    HStack {
                        Text(subject)
                            .font(.title2)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(date)")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.caption)
                    }
                    .padding(.bottom, 3)

                    Text(toAccount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 5)

                    Text(messageBody)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .border(.gray)
            }
            .padding(20)
            .multilineTextAlignment(.leading)
        }
        .frame(width: .infinity, height: 100)
        .shadow(radius: 10)
    }
}

struct RecentsView: View {
    @Environment(\.managedObjectContext) var datastore
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    @FetchRequest(sortDescriptors: []) var messages: FetchedResults<MessageEntity>

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
                            signupSheetVisible = true
                        } label: {
                            Text("Create account")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .sheet(isPresented: $signupSheetVisible) {
                            SignupSheetView(
                                completed: $isLoggedIn,
                                failed: $loginFailed,
                                otpRetryTimer: otpRetryTimer ?? 0,
                                errorMessage: errorMessage)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.bottom, 10)

                        Button {
                            loginSheetVisible = true
                        } label: {
                            Text("Log in")
                                .bold()
                                .frame(maxWidth: .infinity)
                        }
                        .sheet(isPresented: $loginSheetVisible) {
                            LoginSheetView(completed: $isLoggedIn,
                                           failed: $loginFailed)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                    }
                    .padding()
                    Spacer()

                } else {
                    ZStack(alignment: .bottomTrailing) {
                        List(messages, id: \.self) { message in
                            Card(logo: Image(uiImage: UIImage(data: getImageForPlatform(name: message.platformName!)!)!),
                                 subject: message.subject!,
                                 toAccount: message.toAccount!,
                                 messageBody: String(data: Data(base64Encoded: message.body!)!, encoding: .utf8)!,
                                 date: Int(message.date))
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
    
    func getImageForPlatform(name: String) -> Data? {
        for platform in platforms {
            if platform.name == name {
                return platform.image
            }
        }
        return nil
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
