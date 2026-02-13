//
//  KeychainHelper.swift
//  MusePro
//
//  Created by Omer Karisman on 13.02.24.
//

import Foundation

final class KeychainHelper {
    
    static let standard = KeychainHelper()
    let defaultAccount: String = "com.musepro.app"
    
    private init() {}
    
    func save(_ data: Data, key: String, account: String? = nil) {
        let account = account ?? defaultAccount
        // Create query
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: key,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        // Add data in query to keychain
        let status = SecItemAdd(query, nil)
        
        
        if status == errSecDuplicateItem {
            // Item already exist, thus update it.
            let query = [
                kSecAttrService: key,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword,
            ] as CFDictionary
            
            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            
            // Update existing item
            SecItemUpdate(query, attributesToUpdate)
        } else if status != errSecSuccess {
            // Print out the error
            print("Error: \(status)")
        }
        
    }
    
    func read(key: String, account: String? = nil) -> Data? {
        let account = account ?? defaultAccount

        let query = [
            kSecAttrService: key,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return (result as? Data)
    }
    
    func delete(key: String, account: String? = nil) {
        let account = account ?? defaultAccount

        let query = [
            kSecAttrService: key,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            ] as CFDictionary
        
        // Delete item from keychain
        SecItemDelete(query)
    }
    
    func save<T>(_ item: T, key: String, account: String? = nil) where T : Codable {
        let account = account ?? defaultAccount

        do {
            // Encode as JSON data and save in keychain
            let data = try JSONEncoder().encode(item)
            save(data, key: key, account: account)
            
        } catch {
            assertionFailure("Fail to encode item for keychain: \(error)")
        }
    }
    
    func read<T>(key: String, account: String? = nil, type: T.Type) -> T? where T : Codable {
        let account = account ?? defaultAccount

        // Read item data from keychain
        guard let data = read(key: key, account: account) else {
            return nil
        }
        
        // Decode JSON data to object
        do {
            let item = try JSONDecoder().decode(type, from: data)
            return item
        } catch {
            assertionFailure("Fail to decode item for keychain: \(error)")
            return nil
        }
    }
}
