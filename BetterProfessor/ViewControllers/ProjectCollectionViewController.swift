//
//  ProjectCollectionViewController.swift
//  BetterProfessor
//
//  Created by Hunter Oppel on 6/24/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class SectionHeader: UIView {
    @IBOutlet weak var sectionHeaderlabel: UILabel!
    
 static let identifier = "SectionHeaderView"
    
}
class ProjectCollectionViewController: UICollectionViewController {

   
    @IBOutlet weak var addBarButtonItem: UIBarButtonItem!
    private let reuseIdentifier = "ProjectCell"
    struct Storyboard {
    static let sectionHeaderView = "SectionHeaderView"
    }
    var student: Student?
    private var projects = [Project]()
    var projectsHeadings: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        
        navigationItem.rightBarButtonItem = editButtonItem
        
        self.collectionView.backgroundColor = UIColor(patternImage: imageView.image!)
        fetchProjects()
        self.collectionView.reloadData()
    }
    


    private func updateViews() {
        collectionView.reloadData()
    }
    
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named:"old-black-background-grunge-texture-dark-wallpaper-blackboard-chalkboard-concrete")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
     func fetchProjects() {
        guard let student = student else { return }

        BackendController.shared.fetchAllProjects { projects, error in
            if let error = error {
                NSLog("Failed to fetch projects with error: \(error)")
                return
            }

            guard let projects = projects else {
                NSLog("No projects found")
                return
            }

            // We only want to display projects associated with the particular student so I filter it here
            for project in projects {
                if project.studentName == student.name {
                    self.projects.append(project)
                    self.projectsHeadings.append(project.projectType)
                }
            }

            DispatchQueue.main.async {
                self.updateViews()
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewProjectSegue" {
            guard let detailVC = segue.destination as? ProjectDetailViewController,
                let cell = sender as? ProjectCollectionViewCell,
                let indexPath = collectionView.indexPath(for: cell) else { return }

            detailVC.project = self.projects[indexPath.row]
            detailVC.student = self.student
            detailVC.delegate = self
            
        } else if segue.identifier == "AddProjectSegue" {
            guard let detailVC = segue.destination as? ProjectDetailViewController else { return }

            detailVC.student = self.student
            detailVC.delegate = self
        }
    }

    // MARK: UICollectionViewDataSource


  
}

extension ProjectCollectionViewController: UICollectionViewDelegateFlowLayout {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return projects.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ProjectCollectionViewCell else { fatalError() }
        cell.detailDelegate?.tableDelegate = self
        cell.project = projects[indexPath.row]
        cell.descriptionLabel.numberOfLines = 2
        cell.descriptionLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
        cell.delegate = self
       
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
      let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right + 10)) / 2
      return CGSize(width: itemSize, height: itemSize)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        addBarButtonItem.isEnabled = !editing
        if let indexPaths = collectionView?.indexPathsForVisibleItems {
            for indexPath in indexPaths {
                if let cell = collectionView.cellForItem(at: indexPath) as? ProjectCollectionViewCell {
                    cell.isEditing = editing
                    
                }
            }
        }
    }
}

extension ProjectCollectionViewController: ProjectDetailDelegate {
    func didCreateProject() {
        projects = []
        self.fetchProjects()
        collectionView.reloadInputViews()
    }
}

extension ProjectCollectionViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        let label = UILabel()
        label.text = "There is no Projects\n "
        label.font = label.font.withSize(100)
        
        
        let attrs = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)]
        return NSAttributedString(string: label.text!, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        UIImage.SymbolConfiguration(pointSize: 104, weight: .ultraLight, scale: .large)
        return UIImage(named: "icons8-audit-48")
    }
    
   
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        UIColor.tertiarySystemFill
    }
}
extension ProjectCollectionViewController: ProjectCollectionCellDelegate {
    func delete(cell: ProjectCollectionViewCell) {
        if let indexPath = collectionView?.indexPath(for: cell) {
            let project = projects[indexPath.item]
            self.projects.remove(at: indexPath.item)
            self.collectionView.deleteItems(at: [indexPath])
            
            BackendController.shared.deleteProject(project: project) { result in
                guard let _ = try? result.get() else {
                    return
                       
                }
                
                DispatchQueue.main.async {
                   
                    
                    self.updateViews()
                }
               
                
            }
        }
    }
    
    
}
