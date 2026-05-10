import Foundation
import Security

protocol SecretStoring {
    func readAPIKey() throws -> String?
    func saveAPIKey(_ apiKey: String) throws
    func clearAPIKey() throws
}

enum SecretStoreError: LocalizedError, Equatable {
    case keychainStatus(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .keychainStatus(let status):
            return "Keychain operation failed with status \(status)."
        case .invalidData:
            return "Stored API key data is invalid."
        }
    }
}

final class KeychainSecretStore: SecretStoring {
    private let service: String
    private let account: String
    private let accessGroup: String?

    init(
        service: String = "com.local.DeepSeekUsageMonitor",
        account: String = "deepseek-api-key",
        accessGroup: String? = KeychainSecretStore.sharedAccessGroup()
    ) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }

    func readAPIKey() throws -> String? {
        var lastError: OSStatus?
        for queryAccessGroup in queryAccessGroups {
            var query = baseQuery(accessGroup: queryAccessGroup)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            if status == errSecItemNotFound || status == errSecMissingEntitlement {
                lastError = status
                continue
            }
            guard status == errSecSuccess else {
                throw SecretStoreError.keychainStatus(status)
            }
            guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
                throw SecretStoreError.invalidData
            }
            if queryAccessGroup == nil, let accessGroup {
                _ = saveAPIKeyData(data, accessGroup: accessGroup)
            }
            return value
        }
        if let lastError, lastError != errSecItemNotFound && lastError != errSecMissingEntitlement {
            throw SecretStoreError.keychainStatus(lastError)
        }
        return nil
    }

    func saveAPIKey(_ apiKey: String) throws {
        let data = Data(apiKey.utf8)
        var firstError: OSStatus?

        for accessGroup in queryAccessGroups {
            let status = saveAPIKeyData(data, accessGroup: accessGroup)
            if status == errSecSuccess {
                return
            }
            if status != errSecMissingEntitlement {
                firstError = firstError ?? status
            }
        }

        if let firstError {
            throw SecretStoreError.keychainStatus(firstError)
        }
        throw SecretStoreError.keychainStatus(errSecMissingEntitlement)
    }

    private func saveAPIKeyData(_ data: Data, accessGroup: String?) -> OSStatus {
        let query = baseQuery(accessGroup: accessGroup)
        let attributes: [String: Any] = [kSecValueData as String: data]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess || updateStatus == errSecMissingEntitlement {
            return updateStatus
        }
        guard updateStatus == errSecItemNotFound else {
            return updateStatus
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus
    }

    func clearAPIKey() throws {
        for accessGroup in queryAccessGroups {
            let status = SecItemDelete(baseQuery(accessGroup: accessGroup) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound || status == errSecMissingEntitlement else {
                throw SecretStoreError.keychainStatus(status)
            }
        }
    }

    private var queryAccessGroups: [String?] {
        if let accessGroup {
            return [accessGroup, nil]
        }
        return [nil]
    }

    private func baseQuery(accessGroup: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }

    static func sharedAccessGroup() -> String? {
        let configuredPrefix = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String
        let prefix = configuredPrefix?.isEmpty == false ? configuredPrefix! : "V6PB5KA8AG."
        return "\(prefix)com.local.DeepSeekUsageMonitor.shared"
    }
}
