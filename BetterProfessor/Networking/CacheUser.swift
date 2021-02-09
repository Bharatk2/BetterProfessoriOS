//
//  CacheUser.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/26/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import Foundation

class CacheUser: NSObject {
    let TAG = "CacheUser"
    public enum Keys: String {
        case ID, USER_NAME, LAST_NAME, EMAIL, NUMBER, AUTH_TOKEN, USER_IMAGE, USER_ID, ORGANIZATION_NAME, MASCOT, ORGANIZATION_ID, EMO_ON, MDD_ON, ORG_TYPE, ORGANIZATION_TYPE_ID, ORGANIZATION_TYPE_NAME, ORGANIZATION_TYPE_MASCOT, IS_PREMIUM, EIGHT_M_ON, CURRENT_ORGANIZATION
    }
    
    static var cacheUser: CacheUser!
    private var user: User!
    
    static func getInstance() -> CacheUser {
        if cacheUser == nil {
            cacheUser = CacheUser()
        }
        return cacheUser
    }
    private func getDefaults() -> UserDefaults {
        return UserDefaults.init()
    }
    
    func saveUser(_ user: User, token: String?) {
        var token = token ?? ""
        self.user = user
        saveInteger(.ID, user.id!)
        saveString(.USER_NAME, user.username)
        saveString(.AUTH_TOKEN, token)
        saveString(.ORG_TYPE, user.subject!)
    }
    
    func getAuthToken() -> String {
        return getString(.AUTH_TOKEN)
    }
    func getString(_ key: Keys) -> String {
        let value = getDefaults().string(forKey: key.rawValue)
        if value != nil {
            return value!
        }
        return ""
    }
    
    func saveString(_ key: Keys, _ value: String) {
        getDefaults().setValue(value, forKey: key.rawValue)
    }
    
    func saveInteger(_ key: Keys, _ value: Int64) {
        getDefaults().setValue(value, forKey: key.rawValue)
    }
    
    func hasKey(_ key: Keys) -> Bool {
        let obj = getDefaults().object(forKey: key.rawValue)
        if obj == nil {
            return false
        } else {
            return true
        }
    }
}
