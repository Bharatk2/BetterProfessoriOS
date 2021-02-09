//
//  ProjectDetailViewController.swift
//  BetterProfessor
//
//  Created by Hunter Oppel on 6/25/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
import MessageUI
protocol ProjectDetailDelegate {
    func didCreateProject() -> Void
}



class ProjectDetailViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet var sendEmailButton: UIButton!
    @IBOutlet var projectNameTextField: UITextField!
    @IBOutlet var saveProjectButton: UIButton!
    @IBOutlet var projectTypeTextField: UITextField!
    @IBOutlet var completedButton: UIButton!
    @IBOutlet var dueDatePicker: UIDatePicker!
    @IBOutlet var notesTextView: UITextView!
    @IBOutlet var projectNameLabel: UILabel!
     @IBOutlet var projectTypeLabel: UILabel!
     @IBOutlet var completedLabel: UILabel!
     @IBOutlet var dueDateLabel: UILabel!
     @IBOutlet var notesLabel: UILabel!
     @IBOutlet var sendEmailLabel: UILabel!
    @IBOutlet weak var completedStackView: UIStackView!
    
    var project: Project?
    var updateProjectDelegate: UpdateProjectDelegate?
    var student: Student?
    var delegate: ProjectDetailDelegate?
    var tableDelegate: ProjectCollectionViewController?
    var typePicker = UIPickerView()
    var typeData = ["Choose a Project Type", "Meeting", "College/University", "Software", "Other"]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notesTextView.layer.cornerRadius = 12
        if project != nil {
            self.updateViews()
        }
        projectTypeTextField.text = typeData[0]
        typePicker.backgroundColor = UIColor(patternImage: imageView.image!)
       
        typePicker.delegate = self
        typePicker.dataSource = self
        typePicker.tag = 1
        projectTypeTextField.inputView = typePicker
        updateTap()
        notesTextView.layer.borderWidth = 1
        notesTextView.layer.borderColor = UIColor.blue.cgColor
        saveProjectButton.layer.cornerRadius = 12
        dismissPickerView()
//        strokeAttributes()
        self.view.backgroundColor = UIColor(patternImage: imageView.image!)
        if projectTypeTextField.text == typeData[4] {
          createOtherTextField()
        }
        
    }
    
    func createOtherTextField() {
        let specificTextField = UITextField()
        specificTextField.placeholder = "Specify the project type"
        specificTextField.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(specificTextField)
        
        // constraints
        specificTextField.topAnchor.constraint(equalTo: projectTypeTextField.bottomAnchor, constant: 5).isActive = true
        specificTextField.leadingAnchor.constraint(equalTo: projectTypeTextField.leadingAnchor).isActive = true
        specificTextField.trailingAnchor.constraint(equalTo: projectTypeTextField.trailingAnchor).isActive = true
        specificTextField.bottomAnchor.constraint(equalTo: completedStackView.topAnchor, constant: 5).isActive = true
    }
    
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named:"old-black-background-grunge-texture-dark-wallpaper-blackboard-chalkboard-concrete")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    func strokeAttributes() {
        let strokeTextAttributes: [NSAttributedString.Key: Any] = [
            .strokeColor: UIColor.black,
            .foregroundColor: UIColor.white,
            .strokeWidth: -2.8,
            ]

        projectNameLabel.attributedText = NSAttributedString(string: "Project Name:", attributes: strokeTextAttributes)
        projectTypeLabel.attributedText = NSAttributedString(string: "Project Type:", attributes: strokeTextAttributes)
        completedLabel.attributedText = NSAttributedString(string: "Completed?:", attributes: strokeTextAttributes)
        dueDateLabel.attributedText = NSAttributedString(string: "Due Date:", attributes: strokeTextAttributes)
        notesLabel.attributedText = NSAttributedString(string: "Notes Label", attributes: strokeTextAttributes)
        sendEmailLabel.attributedText = NSAttributedString(string: "Send an Email:", attributes: strokeTextAttributes)
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

    private func updateViews() {
        guard let project = project else { return }

        projectNameTextField.text = project.projectName
        projectTypeTextField.text = project.projectType
        dueDatePicker.date = project.dueDate
        notesTextView.text = project.description

        switch project.completed {
        case true:
            completedButton.isSelected = true
        case false:
            completedButton.isSelected = false
        }
    }

    @IBAction func toggleCompleteState(_ sender: Any) {
        completedButton.isSelected.toggle()
    }

    @IBAction func toggleEmailState(_ sender: Any) {
        sendEmailButton.isSelected.toggle()
    }

    @IBAction func saveProject(_ sender: Any) {
        guard let projectName = projectNameTextField.text,
            !projectName.isEmpty,
            let projectType = projectTypeTextField.text,
            !projectType.isEmpty,
            let notes = notesTextView.text,
            let student = student else { return }
        
        if project == nil  {
            createProject(projectName: projectName, projectType: projectType, notes: notes, student: student)
        } else {
            updateProject(project: project!, projectName: projectName, projectType: projectType, notes: notes, student: student)
        }
    }

    private func createProject(projectName: String, projectType: String, notes: String, student: Student) {
        // swiftlint:disable:next all
        BackendController.shared.createProject(name: projectName, studentID: "\(student.id)", projectType: projectType, dueDate: dueDatePicker.date, description: notes, completed: completedButton.isSelected) { result, error in
            if let error = error {
                NSLog("Failed to create project with error: \(error)")
                return
            }

            if result {
                NSLog("Successfully created project 🙌")
            }

            DispatchQueue.main.async {
                self.delegate?.didCreateProject()
            }
        }

        if sendEmailButton.isSelected {
            guard let projectName = projectNameTextField.text,
               let notes = notesTextView.text else { return }
            if MFMailComposeViewController.canSendMail() {
                     let mail: MFMailComposeViewController = MFMailComposeViewController()
                     mail.mailComposeDelegate = self
            
                mail.setToRecipients(nil)
                mail.setSubject("Your \(projectName) is due")
                mail.setMessageBody("\(notes)", isHTML: false)

                     self.present(mail, animated: true, completion: nil)
                 } else {
                     let alert = UIAlertController(title: "Accounts", message: "Please log into your email", preferredStyle: .alert)
                     let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)

                     alert.addAction(okAction)
                     self.present(alert, animated: true, completion: nil)
                 }
        }
        navigationController?.popViewController(animated: true)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }


    private func updateProject(project: Project, projectName: String, projectType: String, notes: String, student: Student) {
        // swiftlint:disable:next all
 
            BackendController.shared.updateProject(project: project, name: projectName, studentID: "\(student.id)", projectType: projectType, dueDate: self.dueDatePicker.date, description: notes, completed: self.completedButton.isSelected) { result, error in
                if let error = error {
                    NSLog("Failed to update project with error: \(error)")
                    return
                }

                if result {
                    NSLog("Successfully updated project 🙌")
                }

                DispatchQueue.main.async {
                    self.tableDelegate?.fetchProjects()
                    
                }
            }
            self.tableDelegate?.reloadInputViews()
            self.navigationController?.popViewController(animated: true)
        
        
    }
}

extension ProjectDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return typeData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return typeData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: typeData[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        return  projectTypeTextField.text = typeData[row]
    }
    
    func dismissPickerView() {
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(self.dismissKeyboard))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        projectTypeTextField.inputAccessoryView = toolBar
        
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
        
    }
    
    
}
