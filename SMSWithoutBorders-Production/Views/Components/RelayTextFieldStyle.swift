//
//  RelayTextFieldStyle.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 27/03/2025.
//

import CountryPicker
import SwiftUI

//MARK: - RelayTextField
struct RelayTextField: View {
    var label: String
    @Binding var text: String

    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(RelayTypography.bodyMedium)
            TextField(label, text: $text)
                .focused($isFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    isFocused
                        ? RelayColors.colorScheme.primaryContainer.opacity(0.5)
                        : RelayColors.colorScheme.surfaceContainer
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused
                                ? RelayColors.colorScheme.primary.opacity(0.5)
                                : RelayColors.colorScheme.surface, lineWidth: 1)
                )
        }

    }
}

struct RelayTextFieldPreview: PreviewProvider {
    static var previews: some View {
        @State var text: String = ""
        RelayTextField(label: "Text", text: $text)
    }
}

//MARK: - RelayTextEditor
struct RelayTextEditor: View {
    var label: String
    @Binding var text: String
    var height: CGFloat = 200
    var showLabel: Bool = true
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showLabel {
                Text(label)
                    .font(RelayTypography.bodyMedium)
            }
            
            TextEditor(text:  !isFocused && text.isEmpty ? .constant(label) : $text)
                .focused($isFocused)
                .transparentScrolling()
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(
                    isFocused
                        ? RelayColors.colorScheme.primaryContainer.opacity(0.5)
                        : RelayColors.colorScheme.surfaceContainer
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isFocused
                                ? RelayColors.colorScheme.primary.opacity(0.5)
                                : RelayColors.colorScheme.surface, lineWidth: 1)
                )
                .foregroundStyle(
                    !isFocused && text.isEmpty ? RelayColors.colorScheme.onSurface.opacity(0.3) : RelayColors.colorScheme.onSurface

                )
        }

    }
}
struct RelayTextEditorPreview: PreviewProvider {
    static var previews: some View {
        @State var text: String = ""
        RelayTextEditor(label: "Text", text: $text)
    }
}

extension View {
    public func transparentScrolling() -> some View {
        if #available(iOS 16.0, *) {
            return scrollContentBackground(.hidden)
        } else {
            return onAppear {
                UITextView.appearance().backgroundColor = .clear
            }
        }
    }
}

//MARK: - RelayPassword Field
struct RelayPasswordField: View {
    var label: String?
    @Binding var text: String
    @State private var showPassword: Bool = false
    @FocusState private var focus1: Bool
    @FocusState private var focus2: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label ?? "Password")
                .font(RelayTypography.bodyMedium)

            ZStack(alignment: .trailing) {
                TextField(label ?? "Password", text: $text)
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                    .autocorrectionDisabled(true)
                    .focused($focus1)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        focus1
                            ? RelayColors.colorScheme.primaryContainer.opacity(
                                0.5)
                            : RelayColors.colorScheme.surfaceContainer
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                focus1
                                    ? RelayColors.colorScheme.primary.opacity(
                                        0.5)
                                    : RelayColors.colorScheme.surface,
                                lineWidth: 1)
                    )
                    .opacity(showPassword ? 1 : 0)
                SecureField(label ?? "Password", text: $text)
                    .textInputAutocapitalization(.never)
                    .textContentType(.password)
                    .focused($focus2)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        focus2
                            ? RelayColors.colorScheme.primaryContainer.opacity(
                                0.5)
                            : RelayColors.colorScheme.surfaceContainer
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                focus2
                                    ? RelayColors.colorScheme.primary.opacity(
                                        0.5)
                                    : RelayColors.colorScheme.surface,
                                lineWidth: 1)
                    )
                    .autocorrectionDisabled(true)
                    .opacity(showPassword ? 0 : 1)
            }.overlay(alignment: .trailing) {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .onTapGesture {
                        showPassword.toggle()
                        if showPassword { focus1 = true } else { focus2 = true }
                    }.padding(.trailing, 16)
            }
        }

    }
}

struct PasswordFieldPreview: PreviewProvider {
    static var previews: some View {
        @State var text = ""
        RelayPasswordField(label: "Password", text: $text)
    }
}

//MARK: - RelayContactPickerField

struct RelayContactField: View {
    var label: String
    var showContactPicker: Bool = false
    @State var country: Country? = Country.init(isoCode: "CM")
    @State private var text: String = ""
    @State var initialValue: String = ""

    @FocusState private var isFocused: Bool
    @State private var fullPhoneNumber = ""
    @State private var pickedContactName: String = ""

    @State private var selectedCountryCodeText: String? =
        "CM".getFlag() + " " + Country.init(isoCode: "CM").localizedName

    @State private var showCountryPicker: Bool = false

    let onPhoneNumberInputted: (_ contact: RelayContact) -> Void
    @State private var contactPickerService = ContactPickerService()

    init (
        label: String,
        showContactPicker: Bool = false,
        initialValue: String = "",
        country: Country? = Country.init(isoCode: "CM"),
        onPhoneNumberInputted: @escaping (_ contact: RelayContact) -> Void
    ) {
        self.label = label
        self.showContactPicker = showContactPicker
        self.onPhoneNumberInputted = onPhoneNumberInputted
        
         self._initialValue = State(initialValue: initialValue)
         self._country = State(initialValue: country)
         self._text = State(initialValue: initialValue)
    }

    var body: some View {
        return VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(RelayTypography.bodyMedium)

            HStack {
                //MARK: - Country Picker Button
                Button {
                    showCountryPicker = true
                } label: {
                    let flag = country?.isoCode ?? "CM"
                    Text(flag.getFlag() + "+" + (country?.phoneCode ?? "237"))
                        .foregroundColor(RelayColors.colorScheme.onSurface)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                }.sheet(isPresented: $showCountryPicker) {
                    CountryPicker(
                        country: $country,
                        selectedCountryCodeText: $selectedCountryCodeText)
                }.background(RelayColors.colorScheme.surfaceContainer)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 12, style: .continuous))

                TextField(label, text: $text)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        isFocused
                            ? RelayColors.colorScheme.primaryContainer.opacity(
                                0.5)
                            : RelayColors.colorScheme.surfaceContainer
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isFocused
                                    ? RelayColors.colorScheme.primary.opacity(
                                        0.5)
                                    : RelayColors.colorScheme.surface,
                                lineWidth: 1)
                    )
                    .onSubmit(processPhoneNumber)
                    .onAppear {
                        processPhoneNumber()
                    }
                    .onChange(of: text) { text in
                        processPhoneNumber()
                    }

                if showContactPicker {
                    //MARK: Contact Picker Button
                    Button {
                        contactPickerService.openContactPicker()
                    } label: {
                        Image(systemName: "person.crop.circle.badge.plus")
                    }.onReceive(contactPickerService.delegate.$contact) {
                        relayContact in

                        // Sets the picked contact
                        if let contact = relayContact {

                            fullPhoneNumber = contact.internationalPhoneNumber
                            text = contact.localPhoneNumber
                            let countryName =
                                CountryUtils.getCountryNameFromPhoneCode(
                                    phoneCode: contact.phoneCode)
                            country = CountryUtils.getCountryFromName(
                                fromFullName: countryName ?? "")
                            pickedContactName = contact.name
                            
                            print("country from phone picker: \(String(describing: country))")
                            processPhoneNumber()
                        }
                    }
                }

            }
        }

    }

    private func processPhoneNumber() {
        print("processPhoneNumber called - text: '\(text)', country: \(String(describing: country))")
        
        guard !text.isEmpty else {
            print("Text is empty, returning early")
            return
        }

        print("Processing phone number...")
        
        if country == nil {
            country = Country(isoCode: "CM")
        }
        
        let fullNumber = "+" + country!.phoneCode + text
        
        let contact: RelayContact = RelayContact(
            phoneCode: country!.phoneCode,
            localPhoneNumber: text,
            internationalPhoneNumber: fullNumber,
            rawValue: fullNumber,
            name: pickedContactName
        )
        onPhoneNumberInputted(contact)

    }

}

//MARK: - RelayTextFieldStyle (DEPRECATED)
@available(*, deprecated,
    message:"RelayTextFieldStyle is deprecated and should not be used, please either use RelayPasswordField or RelayTextField or RelayTextEditor or RelayContactPicker"
)
struct RelayTextFieldStyle: TextFieldStyle {
    private let focusedBorderWith: CGFloat = 1
    private let unfocusedBorderWidth: CGFloat = 0

    private var isFocused: Bool = false

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isFocused
                            ? RelayColors.colorScheme.primaryContainer.opacity(
                                0.5) : RelayColors.colorScheme.surfaceContainer)

            ).overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isFocused
                            ? RelayColors.colorScheme.primary
                            : RelayColors.colorScheme.surfaceContainer,
                        lineWidth: isFocused
                            ? focusedBorderWith : unfocusedBorderWidth
                    )
            )
            .animation(.default, value: isFocused)
    }
}

struct RelayTextFieldStyleField: PreviewProvider {
    static var previews: some View {
        TextField("Sample Text", text: .constant("")).textFieldStyle(
            RelayTextFieldStyle()
        ).previewLayout(.sizeThatFits).padding()
    }
}
