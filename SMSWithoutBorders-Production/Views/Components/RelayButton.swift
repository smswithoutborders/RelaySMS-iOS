//
//  RelayButton.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 06/03/2025.
//

import SwiftUI

struct RelayButton {
}

extension RelayButton {
  enum ButtonVariant {
    case primary
    case outline
    case secondary
    case text
  }

  struct ButtonStyle: SwiftUI.ButtonStyle {
    let variant: ButtonVariant

    func makeBody(configuration: Configuration) -> some View {

      switch variant {
      case .primary:
        configuration.label
            .font(.body)
            .frame(maxWidth: .infinity)
            .padding()
            .background(RelayColors.colorScheme.primary)
            .foregroundColor(Color.white)
            .clipShape(.capsule)

      case .secondary:
        configuration.label.font(.body)
            .frame(maxWidth: .infinity)
            .padding()
            .clipShape(.capsule).background(
                RelayColors.colorScheme.primaryContainer)
            .foregroundStyle(RelayColors.colorScheme.primary)
            .clipShape(.capsule)

      case .outline:
        configuration.label.font(.body)
            .frame(maxWidth: .infinity)
            .padding()
            .clipShape(.capsule)
            .background(Color.clear)
      case .text:
          configuration.label.foregroundStyle(RelayColors.colorScheme.primary)
      }

    }
  }
}


extension ButtonStyle where Self == RelayButton.ButtonStyle {
  static func relayButton(variant: RelayButton.ButtonVariant) -> Self {
    .init(variant: variant)
  }
}
