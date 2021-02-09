//
//  ImageModel.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/1/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import Foundation
import UIKit

//final class ImageModel {
//    enum GetImageResult {
//        case SuccessFulWithImage(UIImage)
//        case failure(String)
//    }
//    private let apiController: BackendController
//    
//    init(apiController: BackendController = BackendController()) {
//        self.apiController = apiController
//    }
//    
//    private func getImage(for student: Student, completion: @escaping (GetImageResult) -> Void) {
//        apiController.getImage(at: student.img_url ?? "") { result in
//            DispatchQueue.main.async {
//            do {
//                let image = try result.get()
//                completion(.SuccessFulWithImage(image))
//            } catch {
//                completion(.failure("Unable to fetch image : \(student.name)"))
//                }
//            }
//        }
//    }
//    
//}
