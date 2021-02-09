//
//  NewStudentTableViewCell.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/10/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
protocol MyCustomCellDelegator {
    func callSegueFromCell(myData dataobject: AnyObject)
}

protocol ImagePickerDelegate {
    func pickImage(for student: Student)
}
class NewStudentTableViewCell: UITableViewCell {
   
    

    @IBOutlet weak var projectLabel: UILabel!
    @IBOutlet weak var studentBackground: UIView!
    @IBOutlet weak var studentNameLabel: UILabel!
    @IBOutlet weak var emailAddressLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var studentImage: UIImageView!
    @IBOutlet weak var projectsButton: UIButton!
    @IBOutlet weak var studentBackgroundView2: UIView!
    var projectDelegate: ProjectCellDelegate?
    var tableDelegater: NewStudentTableViewController?
    var photoDelegate: ImagePickerDelegate?
    var myImage: UIImage?
    var student: Student? {
        didSet {
            updateViews()
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        projectLabel.layer.cornerRadius = 12
        studentBackgroundView2.layer.cornerRadius = 12
        studentBackground.layer.cornerRadius = 12
        studentImage.makeRounded()
        saveStudentPhoto()
        // Initialization code
    }
    
    private func saveStudentPhoto() {
        
        studentImage.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickingImage))
        studentImage.addGestureRecognizer(tapGesture)
    }
   
    @objc func pickingImage() {
        guard let student = student else { return }
        photoDelegate?.pickImage(for: student)
    }

    private func updateViews() {
        guard let student = student else { return }
        studentNameLabel.text = student.name
        emailAddressLabel.text = student.email
        subjectLabel.text = student.subject
        if let data = student.imageData {
            studentImage.layer.borderColor = CGColor(red: 0.1, green: 2.0, blue: 3.0, alpha: 0.8)
            studentImage.image = UIImage(data: data)
            studentImage.contentMode = .scaleAspectFill
        } else {
            studentImage.layer.borderColor = .none
            studentImage.image = UIImage(systemName: "camera")
            
        }
    }

    
}


