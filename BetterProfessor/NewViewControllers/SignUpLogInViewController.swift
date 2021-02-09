//
//  SignUpLogInViewController.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/7/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
protocol NameAndDepartment {
    var nameField: String? { get set }
    var departmentField: String? { get set }
}
class SignUpLogInViewController: UIViewController, UITextFieldDelegate, NameAndDepartment {
    var nameField: String?
    
    var departmentField: String?
    
    var imageLogo = UIImageView()
    @IBOutlet var segmentControl : HBSegmentedControl!
    @IBOutlet weak var userNameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var departmentTextField: UITextField!
    @IBOutlet weak var LogInSignUpButton: UIButton!
    @IBOutlet weak var confirmPasswordLabel: UILabel!
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var departmentLabel: UILabel!
    var typePicker = UIPickerView()
    var typeData = ["Choose a Department", "Computers/Tech", "University/College", "Online Instructor", "High School", "Other"]
    override func viewDidLoad() {
        super.viewDidLoad()

        dismissPickerView()
        nameField = userNameTextField.text
        departmentField = departmentTextField.text
        typePicker.delegate = self
        typePicker.dataSource = self
        typePicker.tag = 1
        passwordTextField.delegate = self
        passwordTextField.tag = 0
        userNameTextField.delegate = self
        userNameTextField.tag = 0
        confirmPasswordTextField.delegate = self
        confirmPasswordTextField.tag = 0
        emailTextField.delegate = self
        emailTextField.tag = 0
        departmentTextField.delegate = self
        departmentTextField.tag = 0
        
        departmentTextField.inputView = typePicker
        segmentControl.items = ["Log In", "Sign Up",]
        segmentControl.font = UIFont(name: "Zapfino", size: 14)
        segmentControl.font = UIFont.boldSystemFont(ofSize: 14)
        segmentControl.borderColor = UIColor(white: 1.0, alpha: 0.3)
        segmentControl.selectedIndex = 1
        segmentControl.padding = 4
        updateViews()
        
        updateTap()

        view.backgroundColor = UIColor(patternImage: UIImage(named: "old-black-background-grunge-texture-dark-wallpaper-blackboard-chalkboard-concrete")!)

        //now add your new view as subview to the existing one
      
      
        LogInSignUpButton.layer.cornerRadius = 12
        segmentControl.addTarget(self, action: #selector(SignUpLogInViewController.updateViews), for: .valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.view.reloadInputViews()
        // Do any additional setup after loading the view.
    }
    
    fileprivate func isLoggedIn() -> Bool {
        
        return UserDefaults.standard.isLoggedIn()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc private func updateViews() {
        UIView.animate(withDuration: 0.2) {
            switch self.segmentControl.selectedIndex {
            
            case 0:
                self.confirmPasswordLabel.isHidden = true
                self.confirmPasswordTextField.isHidden = true
                self.emailLabel.isHidden = true
                self.emailTextField.isHidden = true
                self.departmentLabel.isHidden = true
                self.departmentTextField.isHidden = true
                
                self.LogInSignUpButton.setTitle("Log In", for: .normal)
            case 1:
                self.confirmPasswordLabel.isHidden = false
                self.confirmPasswordTextField.isHidden = false
                self.emailLabel.isHidden = false
                self.emailTextField.isHidden = false
                self.departmentLabel.isHidden = false
                self.departmentTextField.isHidden = false
                
                
                self.LogInSignUpButton.setTitle("Sign Up", for: .normal)
            default:
                break
            }
        }
        
    }
    @IBAction func loginButtonTapped(_ sender: Any) {
        switch segmentControl.selectedIndex {
        case 0:
            
            logIn()
            
        default:
            signUp()
        }
    }
    @IBAction func unwindLoginSegue(segue: UIStoryboardSegue) {
        BackendController.shared.signOut()
    }
    func updateTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    @objc func handleTapGesture(_ tapGesture: UITapGestureRecognizer) {
        print("tap")
        view.endEditing(true)
        switch(tapGesture.state) {
        case .ended:
            print("tapped again")
        default:
            print("Handled other states: \(tapGesture.state)")
        }
    }
    
    private func signUp() {
        activityIndicator.startAnimating()
     
        guard let username = userNameTextField.text,
              !username.isEmpty,
              let password = passwordTextField.text,
              let confirmPassword = confirmPasswordTextField.text,
              password == confirmPassword,
              !password.isEmpty,
              let department = departmentTextField.text,
              !department.isEmpty else {
            self.showAlertMessage(title: "ERROR", message: "Failed to sign up", actiontitle: "OK")
            self.activityIndicator.stopAnimating()
            return
        }
        
        BackendController.shared.signUp(username: username, password: password, department: department) { result, _, error in
            defer {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlertMessage(title: "ERROR", message: "Failed to sign up", actiontitle: "OK")
                    NSLog("⚠️ ERROR: \(error)")
                    return
                }
            }
            
            if result {
                DispatchQueue.main.async {
                    self.showAlertMessage(title: "Success", message: "You have been successfully signed up", actiontitle: "OK")
                    self.logIn()
                }
            }
        }
    }
    
    func squashAlert() {
    
        self.imageLogo.center = CGPoint(x: self.view.center.x, y: -self.imageLogo.bounds.size.height)
        self.imageLogo.image = UIImage(named: "LogoBetter")
        let animationBlock = {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.4) {
                self.imageLogo.center = self.view.center
            }
            UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.2) {
                self.imageLogo.transform = CGAffineTransform(scaleX: 1.7, y: 0.6) // scalex is going to make bigger .7 of one and y is to squash to .6
            }
//            0.0 are the percentages you want it to increase
            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.2) {
                self.imageLogo.transform = CGAffineTransform(scaleX: 0.6, y: 1.7)

            }
//            You want to count thhe pi to comnplete as long you are creating the addkeyframes.
            UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.16) {
                self.imageLogo.transform = CGAffineTransform(scaleX: 1.11, y: 0.9)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.85, relativeDuration: 0.15) {
                self.imageLogo.transform = .identity
            }
        }
        UIView.animateKeyframes(withDuration: 1.5, delay: 0, options: [], animations: animationBlock, completion: nil)
    }
    
    private func logIn() {
        
        activityIndicator.startAnimating()

        guard let username = userNameTextField.text,
              !username.isEmpty,
              let password = passwordTextField.text,
              !password.isEmpty else {
            self.activityIndicator.stopAnimating()
            return
        }
        
        BackendController.shared.signIn(username: username, password: password) { result in
            defer {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
            }
            if BackendController.shared.isSignedIn {
                DispatchQueue.main.async {
                    if result {
                    
                        self.performSegue(withIdentifier: "StudentViewSegue", sender: self)
                        
                    } else {
                        self.showAlertMessage(title: "ERROR", message: "Failed to log in", actiontitle: "OK")
                        return
                    }
                }
            }
        }
        
    }
    
    func showAlertMessage(title: String, message: String, actiontitle: String) {
        let endAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let endAction = UIAlertAction(title: actiontitle, style: .default) { (action: UIAlertAction ) in
        }
        endAlert.addAction(endAction)
        present(endAlert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Try to find next responder
        if let nextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField {
            nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            textField.resignFirstResponder()
        }
        // Do not add a line break
        return false
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    //    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //        guard let detailVC = segue.destination as? NewStudentTableViewController else {return}
    //
    //        if segue.identifier == "StudentViewSegue" {
    //            print("StudentViewSegue called")
    //
    //
    //
    //        }
    //    }
    
    
}

extension SignUpLogInViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return typeData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return typeData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        return  departmentTextField.text = typeData[row]
    }
    
    func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.dismissKeyboard))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        departmentTextField.inputAccessoryView = toolBar 
        
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
        
    }
    
    
}
