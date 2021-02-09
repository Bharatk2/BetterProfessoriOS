//
//  ReminderDetailViewController.swift
//  BetterProfessor
//
//  Created by Bhawnish Kumar on 6/25/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
import CoreData
protocol DatePickerDelegate {
    func pickerDateChosen(_ date: Date)
}
class ReminderDetailViewController: UIViewController, UITextViewDelegate, NSFetchedResultsControllerDelegate {
    
    var studentDelegate: UpdateProjectDelegate?
    
    var timerModelDelegate: TimerModelDelegate?
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var dateTimePicker: UIDatePicker!
    @IBOutlet var studentNameTextField: UITextField!
    @IBOutlet var reminderTextView: UITextView!
    @IBOutlet var saveButton: UIButton!

    var reminderDelegate: ReminderTableViewController?
    var typePicker = UIPickerView()
    var typeData: [String] = ["Select Students"]
    var delegate: DatePickerDelegate?
    var timer: StudentTimer?
    func updateViews() {
        
        let studentImage = UIImage(systemName: "chevron.down")
        guard let studentImg = studentImage else { return }
        addRightImageTo(txtField: studentNameTextField, andImage: studentImg)
        setSegmentControlAndDatePicker(timerType: timer?.timerType)
        guard let timer = timer else { return }
        
        // These lines won't execute it timer == nil
        studentNameTextField.text = timer.name
        reminderTextView.text = timer.noteText
        dateTimePicker.date = timer.dateTime ?? Date()
     
    }
    
    func addRightImageTo(txtField: UITextField, andImage img: UIImage) {
        let rightImageView = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: img.size.width, height: img.size.height))
        rightImageView.image = img
        txtField.rightView = rightImageView
    
        txtField.rightViewMode = .always
    }
    

    private func showAlert() {
        let alert = UIAlertController(title: "Save Unsuccesfull", message: "Please fill out the textfields", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)

        alert.addAction(okAction)

        present(alert, animated: true, completion: nil)
    }
    
    private func showAlert1() {
        let alert = UIAlertController(title: "Student Error", message: "Please fill out the textfield manually", preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)

        alert.addAction(okAction)

        present(alert, animated: true, completion: nil)
    }

    func setSegmentControlAndDatePicker(timerType: TimerType? = nil) {

        let defaultTimerInt = UserDefaults.standard.integer(forKey: .defaultTimerFormat)
        segmentedControl.selectedSegmentIndex = defaultTimerInt
        var timerTypeToUse = TimerType(rawValue: defaultTimerInt)
        
        if let timerType = timerType {
            timerTypeToUse = timerType
        }
        
        switch timerTypeToUse {
        case .date:
            segmentedControl?.selectedSegmentIndex = TimerType.date.rawValue
            dateTimePicker.datePickerMode = .date
        case .time:
            segmentedControl?.selectedSegmentIndex = TimerType.time.rawValue
            dateTimePicker.datePickerMode = .countDownTimer
        case .both:
            fallthrough
        default:
            segmentedControl?.selectedSegmentIndex = TimerType.both.rawValue
            dateTimePicker.datePickerMode = .dateAndTime
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
     
   
        typePicker.tag = 1

        // So textFieldShouldReturn will fire
        saveButton.layer.cornerRadius = 12 
        studentNameTextField.delegate = self
        reminderTextView.delegate = self
        updateViews()
        reminderTextView.layer.borderWidth = 1
        reminderTextView.layer.borderColor = UIColor.lightGray.cgColor
        studentNameTextField.layer.cornerRadius = 12
        reminderTextView.layer.cornerRadius = 12
        self.view.backgroundColor = UIColor(patternImage: imageView.image!)
        
        
        
    }
    
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named:"old-black-background-grunge-texture-dark-wallpaper-blackboard-chalkboard-concrete")
        iv.contentMode = .scaleAspectFill
        return iv
    }()

    private func fetchStudents() {
        BackendController.shared.syncStudents { error in
            DispatchQueue.main.async {
                if let error = error {
                    NSLog("Error trying to fetch student: \(error)")
                } else {
                    self.view.reloadInputViews()
                }
            }
        }
    }
    @IBAction func saveReminderTapped(_ sender: UIButton) {
        guard studentNameTextField.text != nil else { return }
        guard let noteText = reminderTextView.text, !noteText.isEmpty else {
            showAlert()
            return }
        var events: [String] = []
        if let event1 = studentNameTextField.text,
            !event1.isEmpty {
            events.append(event1)
        }

        var timerType = TimerType.time
        switch segmentedControl.selectedSegmentIndex{
        case 0:
            timerType = .date
        case 1:
            timerType = .time
        case 2:
            timerType = .both
        default:
            break
        }
        // .date returns the new date with the current time (GMT)
        var timerDate = dateTimePicker.date
        if timerType == .time {
            // For time, you need to read countDownDuration instead
            let seconds = dateTimePicker.countDownDuration
            print("seconds = \(seconds)")
            timerDate = Date().addingTimeInterval(seconds)
        }
        print(timerDate)
        
        if timer == nil {
            // Create timer
            timerModelDelegate?.create(name: studentNameTextField.text ?? "",
                                       dateTime: timerDate,
                                       timerType: timerType,
                                       active: true,
                                       tag: reminderTextView.text ?? "")
        } else {
            // Timer exists, update it
            timerModelDelegate?.update(timer: timer!,
                                       name: studentNameTextField.text ?? "" ,
                                       dateTime: timerDate,
                                       timerType: timerType,
                                       active: true,
                                       tag: reminderTextView.text ?? "")

        }

        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func segmentedController(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex{
        case 0:
            dateTimePicker.datePickerMode = .date
        case 1:
            dateTimePicker.datePickerMode = .countDownTimer
            
        case 2:
            dateTimePicker.datePickerMode =  .dateAndTime
        default:
            break
        }
    }

    func timerTypeForSegmentedControl() -> TimerType {
        let timerType = TimerType(rawValue: segmentedControl.selectedSegmentIndex)
        return timerType ?? .both
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
extension ReminderDetailViewController: UITextFieldDelegate {
    // Called on 'Return' pressed. Return false to ignore.
    // The return true part of this only tells the text field whether or not it is allowed to return.
    // You have to manually tell the text field to dismiss the keyboard (or what ever its first responder is)
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let empty = (textField.text?.count == 0)

        switch textField {
        case studentNameTextField:
            if !empty { reminderTextView.becomeFirstResponder() }
        case reminderTextView:
            if empty { break } // Stay here until something is entered.
            fallthrough
        default:
            // Loose the keyboard
            textField.resignFirstResponder()
        }
        return true
    }
}




