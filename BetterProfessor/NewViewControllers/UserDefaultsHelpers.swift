//
//  UserDefaultsHelpers.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/23/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import Foundation

extension UserDefaults {
    func setIsLoggenIn(value: Bool) {
        set(value, forKey: "userID")
        synchronize()
        
    }
    
    func isLoggedIn() -> Bool {
        return bool(forKey: "userID")
    }
    func setCurrentLoginID(_ struserid: String) {
        UserDefaults.standard.set(struserid, forKey:"userID")
    }
    
    func loggedUserId() -> String {
        let str = UserDefaults.standard.object(forKey: "userID") as? String
        return str == nil ? "" : str!
    }
}
