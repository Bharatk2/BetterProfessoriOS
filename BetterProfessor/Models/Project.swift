import Foundation

struct Project: Codable {
    let projectID: Int
    let projectName: String
    let dueDate: Date
    let studentId: Int
    let studentName: String
    let projectType: String
    let description: String
    let completed: Bool

    enum CodingKeys: String, CodingKey {
        case projectID = "id"
        case projectName
        case dueDate
        case studentId
        case studentName = "name"
        case projectType
        case description = "desc"
        case completed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.projectID = try container.decode(Int.self, forKey: .projectID)
        self.projectName = try container.decode(String.self, forKey: .projectName)
        self.studentId = try container.decode(Int.self, forKey: .studentId)
        self.studentName = try container.decode(String.self, forKey: .studentName)
        self.projectType = try container.decode(String.self, forKey: .projectType)
        self.description = try container.decode(String.self, forKey: .description)

        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let dateString = try container.decode(String.self, forKey: .dueDate)
        self.dueDate = formatter.date(from: dateString) ?? Date()

        self.completed = try container.decode(Bool.self, forKey: .completed)
      
    }
    
    
}
