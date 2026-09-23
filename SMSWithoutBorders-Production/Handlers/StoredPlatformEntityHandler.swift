//
//  StoredPlatformEntityHandler.swift
//  SMSWithoutBorders-Production
//
//  Created by Nui Lewis on 13/06/2025.
//


// MARK: - Stored Platform Account
struct StoredPlatform: Identifiable {
    let id: String
    let name: String
    let account: String
    let isStoredOnDevice: Bool
    let accessToken: String?
    let refreshToken: String?
    //let idToken: String?

    init(
        id: String, name: String,
        account: String,
        isStoredOnDevice: Bool,
        accessToken: String?,
        refreshToken: String?
    ) {
        self.id = id
        self.name = name
        self.account = account
        self.isStoredOnDevice = isStoredOnDevice
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func copyWith(
        name: String?,
        account: String?,
        isStoredOnDevice: Bool?,
        accessToken: String?,
        refreshToken: String?, idToken: String?
    ) -> StoredPlatform {
        return StoredPlatform(
            id: self.id,
            name: name ?? self.name,
            account: account ?? self.account,
            isStoredOnDevice: isStoredOnDevice ?? self.isStoredOnDevice,
            accessToken: accessToken ?? self.accessToken,
            refreshToken: refreshToken ?? self.refreshToken
        )
    }

    static func fromEntity(_ entity: StoredPlatformsEntity) throws
        -> StoredPlatform
    {
        guard let entityId = entity.id, !entityId.isEmpty else {
            throw CustomError(message: "Invalid Entity: Entity ID is nil")
        }

        // TODO: Probably do the decryption here

        return StoredPlatform(
            id: entityId,
            name: entity.name ?? "",
            account: entity.account ?? "",
            isStoredOnDevice: entity.is_stored_on_device,
            accessToken: entity.access_token,
            refreshToken: entity.refresh_token
        )
    }

}

extension StoredPlatform {
    var tokensExists: Bool {
        if let aToken = accessToken, let rToken = refreshToken {
            return !aToken.isEmpty && !rToken.isEmpty
        } else {
            return false
        }
    }
    
    var isMissing: Bool {
      return  self.isStoredOnDevice && !self.tokensExists
    }
}


extension StoredPlatformsEntity {
   func toStruct() throws -> StoredPlatform {
       guard let id = self.id, !id.isEmpty else {
           throw CustomError(message: "Invalid Entity: Stored Platform id is nil or empty")
       }
       
       return StoredPlatform(
        id: self.id ?? "",
        name: self.name ?? "",
        account: self.account ?? "",
        isStoredOnDevice: self.is_stored_on_device,
        accessToken: self.access_token ?? "",
        refreshToken: self.refresh_token ?? ""
       )
    }
}
