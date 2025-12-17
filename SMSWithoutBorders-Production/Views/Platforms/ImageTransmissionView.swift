//
//  ImageTransmissionView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 13/12/2025.
//

import SwiftUI
import lib_image_ios
import MessageUI

struct ImageTransmissionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var transmissionMessage: Messages?
    @State private var transmissionPayloads: [ImageTransmissionPayload] = []
    @State private var states: [String: Bool] = [:]
    
    @State private var sendSmsIsShown: Bool = false
    @State private var content: String = ""
    @State private var contentId: String = ""
    
    @State private var transmissionId: String? = nil

    #if DEBUG
        var defaultGatewayClientMsisdn: String =
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"]
                == "1"
            ? ""
            : UserDefaults.standard.object(
                forKey: GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN) as? String
                ?? ""
    #else
        @AppStorage(GatewayClients.DEFAULT_GATEWAY_CLIENT_MSISDN)
        var defaultGatewayClientMsisdn: String = ""
    #endif
    
    init(transmissionMessage: Binding<Messages?>) {
        _transmissionMessage = transmissionMessage
    }

    var body: some View {
        NavigationView {
            VStack {
                List(transmissionPayloads) { payload in
                    let id = "\(payload.version).\(payload.sessionId).\(payload.segNumber)"
                    let sent = states.contains(where: { $0.key == id })
                    HStack(alignment: .top) {
                        VStack(alignment: .leading)  {
                            Image(systemName: (sent) ? "checkmark.circle.fill" : "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 40)
                                .padding(.trailing, 12)
                                .foregroundStyle((sent) ? .green : .primary)
                        }
                        
                        VStack(alignment: .leading)  {
                            VStack(alignment: .leading)  {
                                Text(String("version: \(payload.version)"))
                                Text(String("session_id: \(payload.sessionId)"))
                                Text(String("seg_number: \(payload.segNumber)\n"))
                            }
                            .foregroundStyle(Color(.secondaryLabel))

                            VStack(alignment: .leading)  {
                                Text(String("PAYLOAD:"))
                                    .foregroundStyle(Color(.secondaryLabel))
                                Text(String("\(payload.payload)"))
                                    .lineLimit(4)
                            }
                        }
                        

                        Spacer()
                        VStack(alignment: .center) {
                            Spacer()
                            if(sent) {
                                Text("SENT")
                                    .foregroundStyle(.green)
                                    .font(Font.system(size: 12))
                                Button {
                                    contentId = id
                                    content = payload.payload
                                    
                                    if( ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                                    ) {
                                        let defaults = UserDefaults.standard
                                        states[contentId] = true
                                        defaults.set(states, forKey: "com.relaysms.image_sending_sessions.sending_status.\(transmissionMessage!.id)")
                                    } else {
                                        sendSmsIsShown.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                            .resizable()
                                            .frame(width: 12, height: 16)
                                        Text("Resend")
                                    }
                                    .foregroundStyle(.secondary)
                                }
                                .padding(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.gray, lineWidth: 2)
                                )
                                .buttonStyle(.plain)
                            } else {
                                Button("Send") {
                                    contentId = id
                                    content = payload.payload
                                    
                                    if( ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
                                    ) {
                                        let defaults = UserDefaults.standard
                                        states[contentId] = true
                                        defaults.set(states, forKey: "com.relaysms.image_sending_sessions.sending_status.\(transmissionMessage!.id)")
                                    } else {
                                        sendSmsIsShown.toggle()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.leading, 12)
                    }
                }
            }
            .sheet(isPresented: $sendSmsIsShown) {
                SMSComposeMessageUIView(
                    recipients: [defaultGatewayClientMsisdn],
                    body: $content,
                    completion: handleCompletion(_:)
                )
                .ignoresSafeArea()
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        let defaults = UserDefaults.standard
                        defaults.removeObject(forKey: transmissionId!)
                        dismiss()
                    } label: {
                        Image(systemName: "trash.circle")
                    }
                }
            })
        }
        .task {
            self.transmissionId = "com.relaysms.image_sending_sessions.sending_status.\(self.transmissionMessage!.id)"
            Task {
                let payload = [UInt8](Data(self.transmissionMessage!.image!).base64EncodedData())
                
                let defaults = UserDefaults.standard
                states = defaults.dictionary(forKey: transmissionId ?? "") as? [String: Bool] ?? [:]
                let dividedPayload = divideImagePayload(
                    payload: payload,
                    version: 0x4,
                    sessionId: 0,
                    imageLength: UInt16(payload.count),
                    textLength: 0
                )
                transmissionPayloads = ImageTransmissionPayload.fromString(itp: dividedPayload!)
            }
        }
        .navigationTitle("Manual image sending")
    }
    
    func handleCompletion(_ result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("Yep cancelled")
            break
        case .failed:
            print("Yep failed")
            break
        case .sent:
            print("Sent")
            let defaults = UserDefaults.standard
            states[contentId] = true
            defaults.set(states, forKey: "com.relaysms.image_sending_sessions.sending_status.\(transmissionMessage!.id)")
        @unknown default:
            print("Not even sure what this means")
            break
        }
    }
}

#Preview {
    @State var transmissionPayloads: [ImageTransmissionPayload] = [
        ImageTransmissionPayload(
            version: 0,
            sessionId: 0,
            segNumber: 1,
            imageLength: [100],
            textLength: [100],
            payload: "Hello world"
        ),
        ImageTransmissionPayload(
            version: 0,
            sessionId: 0,
            segNumber: 2,
            payload: "Hello world"
        ),
    ]
    
    @State var message: Messages? = Messages(
        id: UUID(),
        subject: "",
        data: "",
        fromAccount: "",
        toAccount: "",
        platformName: "",
        date: Int(Date().timeIntervalSince1970),
        image: (0..<1000).map { _ in UInt8.random(in: 0...255) }
    )
    
    ImageTransmissionView(transmissionMessage: $message)
}
