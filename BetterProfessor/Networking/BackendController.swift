//
//  BackendController.swift
//  BetterProfessor
//
//  Created by Bhawnish Kumar on 6/22/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import Foundation
import CoreData
import UIKit

enum State {
        case unregistered
        case loggedIn(User)
        case sessionExpired(User)
    }

protocol UpdateProjectDelegate {
    var studentNames: [String] { get set }
}
enum NetworkError: Error {
    case noIdentifier, otherError, noData, noDecode, noEncode, noRep
}

enum NetworkError2: Error {
    case failedSignUp, failedSignIn, noData, badData
    case notSignedIn, failedFetch, badURL
}
class BackendController: UpdateProjectDelegate {
    var students: [StudentRepresentation] = []
    var studentNames: [String] = []
    var instructorName: String?
    var departmentName: String?
    typealias getImageCompletion = (Result<UIImage, NetworkError2>) -> Void

    private let baseURL = URL(string: "https://betterprofessordb.herokuapp.com")!
    
    static let shared = BackendController()
    typealias CompletionHandler = (Result<Bool, NetworkError>) -> Void
    private var encoder = JSONEncoder()
    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    var dataLoader: DataLoader?
    var token: Token?
    var instructorStudent: [Student] = []
    var cache = Cache<Int64, Student>()
    
    let bgContext = CoreDataStack.shared.container.newBackgroundContext()
    let operationQueue = OperationQueue()
    // this will check if the user is signed in
    var isSignedIn: Bool {
     
        return token != nil
        
    }
    
    var userID: Int64? {
        didSet {
            loadInstructorStudent()
        }
    }
    var deleteStudent: Bool?
    func signOut() {
        // All we check to see if we're logged in is whether or not we have a token.
        // Therefore all we need to do to log out, is get rid of our token.
        self.token = nil
        // As we've added userID and Posts, clear those out on signOut as well
        self.userID = nil
        
        self.instructorStudent = []
        students.removeAll()
        for student in instructorStudent {
            CoreDataStack.shared.mainContext.delete(student)
            do {
                try CoreDataStack.shared.mainContext.save()
            } catch {
                CoreDataStack.shared.mainContext.reset()
                NSLog("Error saving object : \(error)")
            }
        }
        
    }
    
    init(dataLoader: DataLoader = URLSession.shared) {
        self.dataLoader = dataLoader
        
    }
    
    func signUp(username: String, password: String, department: String, completion: @escaping (Bool, URLResponse?, Error?) -> Void) {
        
        // this is where i am assigning the required parameters to the User.swift
        let newUser = User(username: username, password: password, subject: department)
        instructorName = newUser.username
        departmentName = newUser.subject
        let requestURL = baseURL.appendingPathComponent(EndPoints.register.rawValue)
        var request = URLRequest(url: requestURL)
        request.httpMethod = Method.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            
            // Try to encode the newly created user into the request body.
            let jsonData = try encoder.encode(newUser)
            request.httpBody = jsonData
        } catch {
            NSLog("Error encoding newly created user: \(error)")
            return
        }
        // here i am using the customized data loader from the DataLoader file!
        dataLoader?.loadData(from: request) { _, response, error in
            
            if let error = error {
                NSLog("Error sending sign up parameters to server : \(error)")
                completion(false, nil, error)
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode == 500 {
                NSLog("User already exists in the database. Therefore user data was sent successfully to database.")
                completion(false, response, nil)
                return
            }
            // We'll only get down here if everything went right
            completion(true, nil, nil)
        }
    }
    
    func signIn(username: String, password: String, completion: @escaping (Bool) -> Void) {
        
        let requestURL = baseURL.appendingPathComponent(EndPoints.login.rawValue)
        var request = URLRequest(url: requestURL)
        request.httpMethod = Method.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Try to create a JSON from the passaed in parameters, and embedding it into requestHTTPBody.
            let dictionary = ["username": username, "password": password]
            let jsonData = try jsonFromDict(dictionary: dictionary)
            request.httpBody = jsonData
        } catch {
            NSLog("Error in getting JSON Data: \(error)")
            return
        }
        dataLoader?.loadData(from: request, completion: { data, response, error in
            if let error = error {
                NSLog("Error in loading data: \(error)")
                completion(self.isSignedIn)
         
                return
            }
            
            guard let data = data else {
                NSLog("Invalid data received while loggin in.")
                completion(self.isSignedIn)
                
                return
            }
            self.bgContext.perform {
                do {
                    let decodedUser = try self.decoder.decode(User.self, from: data)
                    self.instructorName = decodedUser.username
                    self.departmentName = decodedUser.subject
                    self.userID = decodedUser.id
                    
                    NSLog("⭐️ \(String(describing: self.userID))")
                    let tokenResult = try self.decoder.decode(Token.self, from: data)
                   
                    self.token = tokenResult
                    guard let savedToken = self.token else { return }
                
                    NSLog("✅ \(String(describing: self.token))")
                
                    completion(self.isSignedIn)
                
                } catch {
                    NSLog("Error in catching the token: \(error)")
                    completion(self.isSignedIn)
                 
                }
            }
        })
    }
    
    private func loadInstructorStudent(completion: @escaping (Bool, Error?) -> Void = { _, _ in}) {
        guard let token = token, let id = userID else {
            completion(false, ProfessorError.noAuth("UserID hasn't been assigned"))
            return
        }
        
        let requestURL = baseURL.appendingPathComponent("\(EndPoints.students.rawValue)").appendingPathComponent("\(id)/students")
        var request = URLRequest(url: requestURL)
        request.httpMethod = Method.get.rawValue
        request.setValue(token.token, forHTTPHeaderField: "authorization")
        
        dataLoader?.loadData(from: request) { data, _, error in
            if let error = error {
                NSLog("Error fetching logged in user's course : \(error)")
                completion(false, error)
                return
            }
            
            guard let data = data else {
                completion(false, ProfessorError.badData("Received bad data when fetching logged in user's student array."))
                return
            }
            // changed
            let fetchRequest: NSFetchRequest<Student> = Student.fetchRequest()
            
            let handleFetchedStudent = BlockOperation {
                do {
                    let decodedStudent = try self.decoder.decode([StudentRepresentation].self, from: data)
                    // Check if the user has no student. And if so return right here.
                    if decodedStudent.isEmpty {
                        NSLog("User has no Student in the database.")
                        completion(true, nil)
                        return
                    }
                    // If the decoded student array isn't empty
                    for student in decodedStudent {
                        guard let studentId = student.id else { return }
                        // swiftlint:disable all
                        let nsID = NSNumber(integerLiteral: Int(studentId))
                        // swiftlint:enable all
                        fetchRequest.predicate = NSPredicate(format: "id == %@", nsID)
                        // If fetch request finds a student, add it to the array and update it in core data
                        let foundStudent = try self.bgContext.fetch(fetchRequest).first
                        if let foundStudent = foundStudent {
                            self.update(student: foundStudent, with: student)
                            // Check if student has already been added.
                            if self.instructorStudent.first(where: { $0 == foundStudent }) != nil {
                                NSLog("Student already added to user's course.")
                            } else {
                                self.instructorStudent.append(foundStudent)
                            }
                        } else {
                            //                             If the student isn't in core data, add it.
                            if let newStudent = Student(representation: student, context: self.bgContext) {
                                if self.instructorStudent.first(where: { $0 == newStudent }) != nil {
                                    NSLog("Student already added to user's course.")
                                } else {
                                    self.instructorStudent.append(newStudent)
                                }
                            }
                            
                        }
                    }
                } catch {
                    do {
                        let error = try self.decoder.decode(Dictionary<String, String>.self, from: data)
                        NSLog("Error: \(error)")
                    } catch {
                        
                        NSLog("Error Decoding Student, Fetching from Coredata: \(error)")
                        completion(false, error)
                    }
                }
            }
            
            let handleSaving = BlockOperation {
                // After going through the entire array, try to save context.
                // Make sure to do this in a separate do try catch so we know where things fail
                let handleSaving = BlockOperation {
                    do {
                        // After going through the entire array, try to save context.
                        // Make sure to do this in a separate do try catch so we know where things fail
                        try CoreDataStack.shared.save(context: self.bgContext)
                        completion(false, nil)
                    } catch {
                        NSLog("Error saving context. \(error)")
                        completion(false, error)
                    }
                }
                self.operationQueue.addOperations([handleSaving], waitUntilFinished: true)
            }
            handleSaving.addDependency(handleFetchedStudent)
            self.operationQueue.addOperations([handleFetchedStudent, handleSaving], waitUntilFinished: true)
        }
    }
    
    func forceLoadInstructorStudents(completion: @escaping (Bool, Error?) -> Void) {
        loadInstructorStudent(completion: { isEmpty, error in
            completion(isEmpty, error)
        })
    }
    private func saveStudent(by userID: Int64, from representation: StudentRepresentation) throws {
        if let newStudent = Student(representation: representation, context: bgContext) {
            let handleSaving = BlockOperation {
                do {
                    // After going through the entire array, try to save context.
                    // Make sure to do this in a separate do try catch so we know where things fail
                    try CoreDataStack.shared.save(context: self.bgContext)
                } catch {
                    NSLog("Error saving context.\(error)")
                }
            }
            operationQueue.addOperations([handleSaving], waitUntilFinished: false)
            cache.cache(value: newStudent, for: userID)
        }
    }
    // MARK: - Syncin/Load existing Student Instructions
    /*
     All that needs to be done to sync database to local store is call syncStudent.
     This method takes care of not allowing for duplicates, and updates existing students.
     - Call this method after user successfully logs in to populate the table for the user.
     */
    
    func syncStudents(completion: @escaping (Error?) -> Void) {
        var representations: [StudentRepresentation] = []
        do {
            try fetchAllStudents { users, error in
                if let error = error {
                    NSLog("Error fetching all posts to sync : \(error)")
                    completion(error)
                    return
                }

                guard let fetchedusers = users else {
                    completion(ProfessorError.badData("Posts array couldn't be unwrapped"))
                    return
                }
                representations = fetchedusers

                // Use this context to initialize new posts into core data.
                self.bgContext.perform {
                    for user in representations {
                        // First if it's in the cache
                       
                        guard let id = user.id else { return }

                        if self.cache.value(for: id) != nil {
                            let cachedPost = self.cache.value(for: id)!
                            self.update(student: cachedPost, with: user)
                        } else {
                            do {
                                try self.saveStudent(by: id, from: user)
                            } catch {
                                completion(error)
                                return
                            }
                        }
                        self.studentNames.append(user.name)
                    }
                }// context.perform
                completion(nil)
            }// Fetch closure

        } catch {
            completion(error)
        }
    }
    
    func fetchAllStudents(completion: @escaping ([StudentRepresentation]?, Error?) -> Void) throws {

        // If there's no token, user isn't authorized. Throw custom error.
        guard let token = token,
              let id = userID else {
            throw ProfessorError.noAuth("No token in controller. User isn't logged in.")
        }

        let requestURL = baseURL.appendingPathComponent(EndPoints.students.rawValue).appendingPathComponent("\(id)/students")
        var request = URLRequest(url: requestURL)
        request.httpMethod = Method.get.rawValue
        request.setValue(token.token, forHTTPHeaderField: "Authorization")

        dataLoader?.loadData(from: request, completion: { data, response, error in
            // Always log the status code response from server.
            if let response = response as? HTTPURLResponse {
                NSLog("Server responded with: \(response.statusCode)")
            }

            if let error = error {
                NSLog("Error fetching all existing posts from server : \(error)")
                completion(nil, error)
                return
            }

            // use badData when unwrapping data from server.
            guard let data = data else {
                completion(nil, ProfessorError.badData("Bad data received from server"))
                return
            }

            do {
                var posts = try self.decoder.decode([StudentRepresentation].self, from: data)
                self.students = posts
                completion(posts, nil)
            } catch {
                NSLog("Couldn't decode array of posts from server: \(error)")
                completion(nil, error)
            }
        })
    }
    func getImage(at urlString: String, completion: @escaping getImageCompletion) {
        guard let imageURL = URL(string: urlString) else {
            return completion(.failure(.badURL))
        }
        
        URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let error = error {
                print("Failed to fetch animal names with error \(error.localizedDescription)")
                completion(.failure(.failedFetch))
                return
            }
            guard let response = response as? HTTPURLResponse,
                response.statusCode == 200
                else {
                    print(#file, #function, #line, "fetch animal bas response ")
                    completion(.failure(.failedFetch))
                    return
            }
            guard let data = data,
                let image = UIImage(data: data)
                else {
                    return completion(.failure(.badData))
            }
            completion(.success(image))
            
        }
        .resume()
    }
    
    func createStudentForInstructor(name: String, email: String, subject: String, completion: @escaping (Bool, Error?) -> Void) {
        let attributedString = NSMutableAttributedString(string:name)
        let attrs = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 15)]
        let boldString = NSMutableAttributedString(string: name, attributes:attrs)
        attributedString.append(boldString)
        guard let token = token,
            let id = self.userID else { return }
        let requestURL = baseURL.appendingPathComponent(EndPoints.students.rawValue).appendingPathComponent("\(id)/students")
        var request = URLRequest(url: requestURL)
        request.httpMethod = Method.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.token, forHTTPHeaderField: "authorization")
        
        do {
            let dictionary: [String: Any] = ["name": name,
                                             "email": email,
                                             "subject": subject,
                                             "teacher_id": "\(id)"]
            let jsonBody = try jsonFromDict(dictionary: dictionary)
            request.httpBody = jsonBody
        } catch {
            completion(false, error)
        }
        
        dataLoader?.loadData(from: request, completion: { _, _, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            completion(true, nil)
        })
    }
    
    func deleteEntryFromServe(student: Student, completion: @escaping CompletionHandler = { _ in }) {
        guard let id = userID,
            let token = token else {
                completion(.failure(.noIdentifier))
                return
        }
        let requestURL = URLComponents(string: "https://betterprofessordb.herokuapp.com/api/users/teacher/\(id)/students/\(student.id)")!
        var request = URLRequest(url: requestURL.url!)
        request.httpMethod = Method.delete.rawValue
        request.setValue(token.token, forHTTPHeaderField: "Authorization")
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("Error in getting data: \(error)")
                completion(.failure(.noData))
            }
            
            
            completion(.success(true))
        }.resume()
        
    }
    
    func deleteStudent(student: Student, completion: @escaping (Bool?, Error?) -> Void) {
        guard let id = userID,
            let token = token else {
                completion(nil, ProfessorError.noAuth("User not logged in."))
                return
        }

        // Our only DELETE endpoint utilizes query parameters.
        // Must use a new URL to construct commponents

        let requestURL = URLComponents(string: "https://betterprofessordb.herokuapp.com/api/users/teacher/\(id)/students/\(student.id)")!
       

        var request = URLRequest(url: requestURL.url!)
        request.httpMethod = Method.delete.rawValue
        request.setValue(token.token, forHTTPHeaderField: "Authorization")

        dataLoader?.loadData(from: request, completion: { data, _, error in
            if let error = error {
                NSLog("Error from server when attempting to delete. : \(error)")
                completion(nil, error)
                return
            }

            guard let data = data else {
                NSLog("Error unwrapping data sent form server: \(ProfessorError.badData("Bad data received from server after deleting post."))")
                completion(nil, ProfessorError.badData("Bad data from server when deleting."))
                return
            }

            var success: Bool = false

            do {
                let response = try self.decoder.decode(Int.self, from: data)
                success = response == 1 ? true : false
                if success { self.bgContext.delete(student) }
//                if success { CoreDataStack.shared.mainContext.delete(post) }
                completion(success, nil)
            } catch {
                NSLog("Error decoding response from server after deleting: \(error)")
                completion(nil, error)
                return
            }

        })
    }
    
    private func populateCache() {
        // First get all existing students saved to coreData and store them in the Cache
        let fetchRequest: NSFetchRequest<Student> = Student.fetchRequest()
        // Do this synchronously in the background queue, so that it can't be used until cache is fully populated
        bgContext.performAndWait {
            var fetchResult: [Student] = []
            do {
                fetchResult = try bgContext.fetch(fetchRequest)
            } catch {
                NSLog("Couldn't fetch existing core data student: \(error)")
            }
            for student in fetchResult {
                cache.cache(value: student, for: student.id)
            }
        }
    }
    
    private func jsonFromDict(dictionary: Dictionary<String, Any>) throws -> Data? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
            return jsonData
        } catch {
            NSLog("Error Creating JSON from Dictionary. \(error)")
            throw error
        }
    }
    
    private func jsonFromUsername(username: String) throws -> Data? {
        var dic: [String: String] = [:]
        dic["username"] = username
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            return jsonData
        } catch {
            NSLog("Error Creating JSON From username dictionary. \(error)")
            throw error
        }
    }
    
    private func update(student: Student, with rep: StudentRepresentation) {
        student.name = rep.name
        student.email = rep.email
        student.subject = rep.subject
    }
    
    private enum ProfessorError: Error {
        case noAuth(String)
        case badData(String)
    }
    
    private enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
    
    private enum EndPoints: String {
        case register = "api/auth/register"
        case login = "api/auth/login"
        case students = "/api/users/teacher/"
        case delete =  "/teacher/:id/students/"
    }
    
    func injectToken(_ token: String) {
        let token = Token(token: token)
        self.token = token
    }
}

extension BackendController {
    func fetchAllProjects(completion: @escaping ([Project]?, Error?) -> Void) {
        guard let token = token,
            let userID = self.userID else { return }
        
        let projectURL = baseURL.appendingPathComponent("/api/users/teacher").appendingPathComponent("\(userID)").appendingPathComponent("/students/projects")
        print(projectURL)
        var request = URLRequest(url: projectURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.token, forHTTPHeaderField: "authorization")
        
        dataLoader?.loadData(from: request, completion: { data, _, error in
            if let error = error {
                return completion(nil, error)
            }
            
            guard let data = data else {
                return completion(nil, ProfessorError.badData("No data was returned"))
            }
            print(data)
         
            let project = [Project].self
         
            do {
                let projects = try self.decoder.decode(project, from: data)
                print(projects)
                return completion(projects, nil)
            } catch {
                return completion(nil, ProfessorError.badData("Could not decode data"))
            }
        })
    }
    
    func createProject(name: String, studentID: String, projectType: String, dueDate: Date, description: String, completed: Bool, completion: @escaping (Bool, Error?) -> Void) {
        guard let token = token,
            let userID = self.userID else { return }
        
        let projectURL = baseURL.appendingPathComponent("/api/users/teacher").appendingPathComponent("\(userID)").appendingPathComponent("/students/projects")
        
        var request = URLRequest(url: projectURL)
        request.httpMethod = Method.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.token, forHTTPHeaderField: "authorization")
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: dueDate)
            let dictionary: [String: Any] = ["teacher_id": "\(userID)",
                "project_name": name,
                "due_date": dateString,
                "student_id": studentID,
                "project_type": projectType,
                "desc": description,
                "completed": completed]
            let jsonBody = try jsonFromDict(dictionary: dictionary)
          
            request.httpBody = jsonBody
        } catch {
            completion(false, error)
        }
        
        dataLoader?.loadData(from: request, completion: { _, _, error in
            if let error = error {
                return completion(false, error)
            }
            
            completion(true, nil)
        })
    }
    
    func updateProject(project: Project, name: String, studentID: String, projectType: String, dueDate: Date, description: String, completed: Bool, completion: @escaping (Bool, Error?) -> Void) {
        guard let token = token,
            let userID = self.userID else { return }
        
        let projectURL = baseURL.appendingPathComponent("/api/users/teacher/\(userID)/students/projects/\(project.projectID)")
        var request = URLRequest(url: projectURL)
        request.httpMethod = Method.put.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token.token, forHTTPHeaderField: "authorization")
        
        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let dateString = dateFormatter.string(from: dueDate)
            let dictionary: [String: Any] = ["teacher_id": "\(userID)",
                "project_name": name,
                "student_id": studentID,
                "project_type": projectType,
                "due_date": dateString,
                "desc": description,
                "completed": completed]
            let jsonBody = try jsonFromDict(dictionary: dictionary)
            request.httpBody = jsonBody
        } catch {
            completion(false, error)
        }
        
        dataLoader?.loadData(from: request, completion: { _, _, error in
            if let error = error {
                return completion(false, error)
            }
            
            completion(true, nil)
        })
    }
    
    
    
    func deleteProject(project: Project, completion: @escaping CompletionHandler = { _ in }) {
        guard let id = userID,
            let token = token else {
            completion(.failure(.noIdentifier))
                return
        }
        
        let requestURL = URLComponents(string: "https://betterprofessordb.herokuapp.com/api/users/teacher/\(id)/students/projects/\(project.projectID)")!
        
        var request = URLRequest(url: requestURL.url!)
        request.httpMethod = Method.delete.rawValue
        request.setValue(token.token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("Error in getting data: \(error)")
                completion(.failure(.noData))
            }
        
            
            completion(.success(true))
        }.resume()
    }
}
