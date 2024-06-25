//
//  Vault.swift
//  SMSWithoutBorders-Production
//
//  Created by sh3rlock on 24/06/2024.
//

import Foundation


class VaultAuth {
    let accountRequest : Vault_V1_CreateEntityRequest = .with {
        $0.clientDeviceIDPubKey = "clientDeviceIDPubKey"
    }
}
