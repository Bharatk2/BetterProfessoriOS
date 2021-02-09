//
//  AppDelegate.swift
//  BetterProfessor
//
//  Created by Bhawnish Kumar on 6/22/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
   var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        window = UIWindow(frame: UIScreen.main.bounds)
//        let students = UIStoryboard(name: "Main", bundle: nil)
//        let loginStory = UIStoryboard(name: "Login", bundle: nil)
//        if let navVC = students.instantiateInitialViewController() as? UINavigationController,
//        
//           let studentVC = navVC.viewControllers.first as? StudentTableViewController {
//        // if auth token nil
//            // perforn studentvc segue to login
//            if  UserDefaults.standard.isLoggedIn() {
//       
//                window?.rootViewController = studentVC
//                window?.makeKeyAndVisible()
//            }else {
//            let loginVC = students.instantiateInitialViewController() as! SignUpLogInViewController
//            window?.rootViewController = loginVC
//                window?.makeKeyAndVisible()
//            
//            }
//            let loginVC = students.instantiateInitialViewController() as! SignUpLogInViewController
//            window?.rootViewController = loginVC
//                window?.makeKeyAndVisible()
//            
//        }
        return true
    
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

}
