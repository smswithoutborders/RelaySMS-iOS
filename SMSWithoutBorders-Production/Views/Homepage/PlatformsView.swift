//
//  RecentsView1.swift
//  SMSWithoutBorders-Production
//
//  Created by MAC on 20/01/2025.
//

import SwiftUI

struct PlatformSheetView: View {
    var image: Data?
    var description: String
    
    init(image: Data?, description: String) {
        self.image = image
        self.description = description
    }
    
    var body: some View {
        VStack(alignment:.center) {
            (image != nil ?
             Image(uiImage: UIImage(data: image!)!) : Image("Logo")
            )
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
                .padding()
            
            Text(description)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            Button {
                
            } label: {
                Text("Add Account")
                    .frame(maxWidth: .infinity, maxHeight: 35)
            }
            .buttonStyle(.bordered)
            .padding()

        }
    }
}

struct PlatformCard: View {
    @State var sheetIsPresented: Bool = false
    
    let name: String
    let protocolType: Publisher.ProtocolTypes
    let isEnabled: Bool
    let image: Data?

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Button(action: {
                        sheetIsPresented.toggle()
                    }) {
                        VStack {
                            (image != nil ?
                             Image(uiImage: UIImage(data: image!)!) : Image("Logo")
                            )
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
                    .sheet(isPresented: $sheetIsPresented) {
                        PlatformSheetView(
                            image: image,
                            description: getProtocolDescription(protocolType: protocolType)
                        )
                            .applyPresentationDetentsIfAvailable()
                    }

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
    
    func getProtocolDescription(protocolType: Publisher.ProtocolTypes) -> String {
        switch(protocolType) {
        case .BRIDGE:
            return Publisher.ProtocolDescriptions.BRIDGE.rawValue
        case .OAUTH2:
            return Publisher.ProtocolDescriptions.OAUTH2.rawValue
        case .PNBA:
            return Publisher.ProtocolDescriptions.PNBA.rawValue
        }
    }
}

struct PlatformsView: View {
    @FetchRequest(sortDescriptors: []) var platforms: FetchedResults<PlatformsEntity>
    
    @State private var sheetIsRequested: Bool = false
    @State private var platformsSheetIsRequested: Bool = false

    private var defaultDescription = ""

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
                        name: "RelaySMS account",
                        protocolType: Publisher.ProtocolTypes.BRIDGE,
                        isEnabled: true,
                        image: nil
                    ).padding(.bottom, 32)


                    Text("Use your online accounts")
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 10)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(platforms, id: \.name) { item in
                            PlatformCard(
                                name: item.name!,
                                protocolType: getProtocolType(type: item.protocol_type!),
                                isEnabled: false,
                                image: item.image
                            )
                        }
                    }
                    
                }
            }
            .navigationTitle("Available Platforms")
            .padding(16)
        }
    }
    
    func getProtocolType(type: String) -> Publisher.ProtocolTypes {
        switch(type) {
        case Publisher.ProtocolTypes.OAUTH2.rawValue:
            return Publisher.ProtocolTypes.OAUTH2
            
        case Publisher.ProtocolTypes.PNBA.rawValue:
            return Publisher.ProtocolTypes.PNBA
            
        default:
            return Publisher.ProtocolTypes.BRIDGE
        }
    }
}

#Preview {
    var description = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book"
    PlatformSheetView(
        image: nil,
        description: description)
}

struct Platforms_Preview: PreviewProvider {
    static var previews: some View {
        
        let container = createInMemoryPersistentContainer()
        populateMockData(container: container)
        
        return PlatformsView()
            .environment(\.managedObjectContext, container.viewContext)
    }
}

struct PlatformCardDisabled_Preview: PreviewProvider {
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        PlatformCard(
            name: "Template",
            protocolType: Publisher.ProtocolTypes.BRIDGE,
            isEnabled: true,
            image: nil
        )
    }
}

struct PlatformCardEnabled_Preview: PreviewProvider {
    static var previews: some View {
        @State var sheetIsPresented: Bool = false
        PlatformCard(
            name: "Template",
            protocolType: Publisher.ProtocolTypes.BRIDGE, isEnabled: false,
            image: nil
        )
    }
}
