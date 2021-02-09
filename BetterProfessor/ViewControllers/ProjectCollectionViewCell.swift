//
//  ProjectCollectionViewCell.swift
//  BetterProfessor
//
//  Created by Hunter Oppel on 6/24/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
protocol ProjectCollectionCellDelegate: class {
    func delete(cell: ProjectCollectionViewCell)
}
class ProjectCollectionViewCell: UICollectionViewCell {
    var project: Project? {
        didSet {
            updateViews()
        }
    }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    @IBOutlet private weak var highlightIndicator: UIView!
    @IBOutlet private var projectNameLabel: UILabel!
    @IBOutlet private var projectTypeLabel: UILabel!
    @IBOutlet private var completedButton: UIButton!
    @IBOutlet private var dueDateLabel: UILabel!
    @IBOutlet private weak var selectIndicator: UIButton!
 
    @IBOutlet weak var deleteButtonBackgroundView: UIVisualEffectView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    
    weak var delegate: ProjectCollectionCellDelegate?
    var detailDelegate: ProjectDetailViewController?
    var isEditing: Bool = false {
        didSet {
            deleteButtonBackgroundView.isHidden = !isEditing
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
       
    }
   
    
    private func updateViews() {
        guard let project = project else { return }
        self.deleteButtonBackgroundView.layer.cornerRadius = self.deleteButtonBackgroundView.bounds.width / 2.0
        self.deleteButtonBackgroundView.layer.masksToBounds = true
        self.deleteButtonBackgroundView.isHidden = !isEditing
        let dateString = dateFormatter.string(from: project.dueDate)
        projectNameLabel.text = project.projectName
        projectTypeLabel.text = project.projectType
        dueDateLabel.text = dateString
        descriptionLabel.text = project.description
        switch project.completed {
        case true:
            completedButton.isSelected = true
        case false:
            completedButton.isSelected = false
        }
        
        self.contentView.layer.cornerRadius = 6
        self.contentView.layer.borderWidth = 1.0
        self.contentView.layer.borderColor = UIColor.clear.cgColor
        self.contentView.layer.masksToBounds = true
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 0.5
        self.layer.masksToBounds = true
        self.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.contentView.layer.cornerRadius).cgPath
    }
    @IBAction func deleteButtonTapped(_ sender: Any) {
        guard let project = project else { return }
        delegate?.delete(cell: self)
        print("delete tapped")
    }
}
