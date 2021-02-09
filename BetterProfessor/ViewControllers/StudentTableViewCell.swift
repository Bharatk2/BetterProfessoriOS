//
//  StudentTableViewCell.swift
//  BetterProfessor
//
//  Created by Bhawnish Kumar on 6/23/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit

class StudentTableViewCell: UITableViewCell, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var photoImage: UIImageView!
    
    @IBOutlet weak var chooseButton: UIButton!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var subectLabel: UILabel!
    @IBOutlet weak var backgroundUIView: UIView!
    
    var photoDelegate: ImagePickerDelegate?
    var projectDelegate: ProjectCellDelegate?
    var myImage: UIImage?
    var takePicture: (() -> Void)?
    var student: Student? {
        didSet {
            updateViews()
        }
    }
    
    override func awakeFromNib() {
        photoImage.makeRounded()
        
    }
    
    private func updateViews() {
        guard let student = student else { return }
        nameLabel.text = student.name
        emailLabel.text = student.email
        subectLabel.text = student.subject
        if let data = student.imageData {
        photoImage.image = UIImage(data: data)
        } else {
            photoImage.image = UIImage(systemName: "camera")
        }
    }
    
  
    
    @IBAction func chooseButtonTapped(_ sender: Any) {
        guard let student = student else { return }
        photoDelegate?.pickImage(for: student)
        print("picked image")
    }
    
}
extension UIImageView {

    func makeRounded() {

        self.layer.borderWidth = 1
                self.layer.masksToBounds = false
                self.layer.borderColor = UIColor.black.cgColor
                self.layer.cornerRadius = self.frame.height / 2
                self.clipsToBounds = true
    }
}
