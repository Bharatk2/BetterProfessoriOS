//
//  NewLogInVIewController.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/2/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit

class NewLogInVIewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 5
        signUpButton.layer.cornerRadius = 5
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
