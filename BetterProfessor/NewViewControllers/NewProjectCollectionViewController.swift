//
//  NewProjectCollectionViewController.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/12/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
import CoreData
private let reuseIdentifier = "Cell"

class NewProjectCollectionViewController: UICollectionViewController {
    
    private let reuseIdentifier = "ProjectCell"

    var student: Student?
    private var projects = [Project]()
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchProjects()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    private func updateViews() {
        collectionView.reloadData()
    }
    
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
               }
           }

           DispatchQueue.main.async {
               self.updateViews()
           }
       }
   }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource




 

}

extension NewProjectCollectionViewController: UICollectionViewDelegateFlowLayout {
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return projects.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as? ProjectCollectionViewCell else { fatalError() }
 
    cell.project = projects[indexPath.item]
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let itemSize = (collectionView.frame.width - (collectionView.contentInset.left + collectionView.contentInset.right + 10)) / 2
    return CGSize(width: itemSize, height: itemSize)
  }
}

//extension NewProjectCollectionViewController: PinterestLayoutDelegate {
//    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
//        return projects[indexPath.row]
//    }
//    
//    
//}

extension NewProjectCollectionViewController: ProjectDetailDelegate {
    func didCreateProject() {
        projects = []
        self.fetchProjects()
    }
}
