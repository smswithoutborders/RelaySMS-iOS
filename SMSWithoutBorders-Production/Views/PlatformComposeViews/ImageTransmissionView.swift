//
//  ImageTransmissionView.swift
//  SMSWithoutBorders-Production
//
//  Created by Sherlock on 13/12/2025.
//

import SwiftUI
import lib_image_ios

struct ImageTransmissionView: View {
    @State var transmissionPayloads: [ImageTransmissionPayload]
    @State private var states: [String: Bool] = [:]
    
    var body: some View {
        VStack {
            List(transmissionPayloads) { payload in
                let id = "\(payload.version).\(payload.sessionId).\(payload.segNumber)"
                HStack {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding()

                    VStack {
                        VStack(alignment: .leading)  {
                            Text(String("version: \(payload.version)"))
                            Text(String("session_id: \(payload.sessionId)"))
                            Text(String("seg_numner: \(payload.segNumber)"))
                            Text(String("payload: \(payload.payload)"))
                        }
                    }
                    Spacer()
                    Button((states.contains(where: { $0.key == id })) ? "Resend" :"Send") {
                        let defaults = UserDefaults.standard
                        states[id] = true
                        defaults.set(states, forKey: "com.relaysms.image_sending_sessions")
                    }
                    .buttonStyle(.bordered)
                }
            }
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
    ImageTransmissionView(transmissionPayloads: transmissionPayloads)
}
