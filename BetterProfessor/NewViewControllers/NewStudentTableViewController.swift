//
//  NewStudentTableViewController.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/8/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

protocol ProjectCellDelegate {
    func performSegueProject(for student: Student)
}
class NewStudentTableViewController: UIViewController  {
    
   
    var temporaryStudent: Student?
 
    var photoController = PhotoController()
    var studentFetchedResultsController: NSFetchedResultsController<Student>!
    private func setUpFetchResultController(with predicate: NSPredicate = NSPredicate(value: true)) {
        self.studentFetchedResultsController = nil
        let fetchRequest: NSFetchRequest<Student> = Student.fetchRequest()
        fetchRequest.predicate = predicate
        let context = CoreDataStack.shared.mainContext
        //        context.reset()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        do {
            try frc.performFetch()
        } catch {
            print("Error performing initial fetch inside fetchedResultsController: \(error)")
        }
        self.studentFetchedResultsController = frc
    }
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var professorNameLabel: UILabel!
    @IBOutlet weak var departmentLabel: UILabel!
    @IBOutlet weak var instructorImageButton: UIButton!
    @IBOutlet weak var instructorImage: UIImageView!
    @IBOutlet weak var studentBackground: UIView!
    
    @IBOutlet weak var tableView: UITableView!
    let pickerController = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.delegate = self
        searchBar(searchBar, textDidChange: "")
//        setUpFetchResultController()
        studentFetchedResultsController.delegate = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.delegate = self
        tableView.dataSource = self
        updateViews()
     
        fetchStudents()
        
        pickerController.delegate = self
        self.tableView.backgroundColor = .clear
        self.view.backgroundColor = UIColor(patternImage: imageView.image!)
    }
    
    let imageView : UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named:"old-black-background-grunge-texture-dark-wallpaper-blackboard-chalkboard-concrete")
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private func createStudent() {
        let alert = UIAlertController(title: "Create Student", message: nil, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        let createAction = UIAlertAction(title: "Create", style: .default) { (action: UIAlertAction ) in
            guard let name = alert.textFields?[0].text,
                  let email = alert.textFields?[1].text,
                  let subject = alert.textFields?[2].text else { return }
            
            BackendController.shared.createStudentForInstructor(name: name, email: email, subject: subject) { result, error in
                if let error = error {
                    NSLog("ERROR: \(error)")
                    return
                }
                
                if result {
                    DispatchQueue.main.async {
                        self.fetchStudents()
                        NSLog("Created Student ⭐️")
                    }
                }
            }
        }
        
        alert.addTextField { (nameTextField) in
            nameTextField.placeholder = "Student Name"
            
        }
        alert.addTextField { (emailTextField) in
            emailTextField.placeholder = "Student Email"
        }
        alert.addTextField { (subjectTextField) in
            subjectTextField.placeholder = "Student Subject"
        }
        
        alert.addAction(cancelAction)
        alert.addAction(createAction)
        present(alert, animated: true, completion: nil)
    }
    
   
    func updateViews() {
        
        professorNameLabel.text = BackendController.shared.instructorName
        
    }
   
    private func fetchStudents() {
        BackendController.shared.syncStudents { error in
            DispatchQueue.main.async {
                if let error = error {
                    NSLog("Error trying to fetch student: \(error)")
                } else {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func fetchStudents1() {
        BackendController.shared.forceLoadInstructorStudents { result, error in
            if let error = error {
                NSLog("ERROR: \(error)")
                return
            }
            
            if result {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @IBAction func creatingStudent(_ sender: UIBarButtonItem) {
     
        createStudent()
    }
    
    @IBAction func signOutTapped(_ sender: Any) {
        BackendController.shared.signOut()
        let loginController = SignUpLogInViewController()
        present(loginController, animated: true, completion: nil)
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "ProjectCollectionSegue2":
            guard let collectionVC = segue.destination as? ProjectCollectionViewController,
                  let indexPath = tableView.indexPathForSelectedRow else { return }
            let student = studentFetchedResultsController.object(at: indexPath)
            collectionVC.student = student
            
        case "viewReminder2":
            guard let collectionVC = segue.destination as? ReminderTableViewController,
                  let indexPath = tableView.indexPathForSelectedRow else { return }
            collectionVC.delegateTable = self
        case "unwindLogOutSegue":
            guard let detailVC = segue.destination as? SignUpLogInViewController else { return }
            if detailVC == detailVC {
                
                BackendController.shared.signOut()
            }
        default:
            break
        }
    }

    
}

extension NewStudentTableViewController: UITableViewDelegate, UITableViewDataSource, MyCustomCellDelegator {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentFetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewStudentCell", for: indexPath) as? NewStudentTableViewCell else { return UITableViewCell() }
        
        cell.projectDelegate = self
        cell.photoDelegate = self
        cell.student = studentFetchedResultsController.object(at: indexPath)
        cell.tableDelegater = self
        cell.projectLabel.layer.cornerRadius = 12
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       let label = UILabel()
        label.font = UIFont(name: "Avenir Next", size: 16)
        label.textColor = UIColor.black
        label.text = "Students"
        self.view.addSubview(label)
        return label.text
    }
    
    func callSegueFromCell(myData dataobject: AnyObject) {

            print(dataobject)
            self.performSegue(withIdentifier: "ProjectCollectionSegue2", sender: dataobject )
    
        }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            // TODO: expected to decode Int but found dictionary instead.
            let student = studentFetchedResultsController.object(at: indexPath)
            BackendController.shared.deleteEntryFromServe(student: student) { result  in
                guard let _ = try? result.get() else {
                    return
                }
                DispatchQueue.main.async {
                    CoreDataStack.shared.mainContext.delete(student)
                    
                    do {
                        try CoreDataStack.shared.mainContext.save()
                    } catch {
                        CoreDataStack.shared.mainContext.reset()
                        NSLog("Error saving object : \(error)")
                    }
                }
            }
        }
    }
    
    func buttonTapped(_ sender: UITableViewCell) {
        
        performSegue(withIdentifier: "ProjectCollectionSegue2", sender: UITableViewCell())
    }
    
}
extension NewStudentTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImagePickerDelegate {
    func pickImage(for student: Student) {
        let imagePicker = UIImagePickerController()
        self.temporaryStudent = student
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        self.temporaryStudent?.imageData = image.pngData()
       try? CoreDataStack.shared.save()
        self.tableView.reloadData()
        self.dismiss(animated: true, completion: nil)
        self.temporaryStudent = nil
    }
    
   
    
}

extension NewStudentTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                  let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            break
        }
    }
}
extension NewStudentTableViewController: UISearchBarDelegate, UISearchDisplayDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            var predicate: NSPredicate = NSPredicate()
            predicate = NSPredicate(format: "name contains[c] '\(searchText)'")
            setUpFetchResultController(with: predicate)
        } else {
            setUpFetchResultController()
        }
        tableView.reloadData()
    }
}
extension NewStudentTableViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        
        let label = UILabel()
        label.text = "There is no Students\n"
        label.font = UIFont(name: "Avenit Next", size: 40)
        
        
        let attrs = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .headline)]
        return NSAttributedString(string: label.text!, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        UIImage.SymbolConfiguration(pointSize: 104, weight: .ultraLight, scale: .large)
        return UIImage(named: "book-2")
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        UIColor.tertiarySystemFill
    }
}

extension NewStudentTableViewController: ProjectCellDelegate {
    func performSegueProject(for student: Student) {
        self.temporaryStudent = student
        performSegue(withIdentifier: "ProjectCollectionSegue2", sender: self)
    }
    
    
}

