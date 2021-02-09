//
//  PhotoController.swift
//  BetterProfessor
//
//  Created by Bharat Kumar on 12/1/20.
//  Copyright © 2020 Bhawnish Kumar. All rights reserved.
//

import Foundation

class PhotoController: Codable {
    var photos: [Photo] = []
    
    func create(data: Data) {
        let newPhoto = Photo(imageData: data)
        self.photos.append(newPhoto)
    }
    
    var photosURL: URL? {
        get {
            let fileManager = FileManager.default // This is just efficiency. This variable is the same as repeating FileManager.default every time it's used.
            guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {return nil} // Get docmuments Directory
            let plistFile = documentsDir.appendingPathComponent("Photos.plist") // Use the NSURL's append method on the documents url.
            
            return plistFile // Return this resulting plist file location. Things will go here.
        }
    }
    
    // PropertyListEncoder
    
    func saveToPersistentStore() {
        
        guard let fileURL = photosURL else { return } // Unwrap our URL
        let propertyList = PropertyListEncoder() // Initialize PListEncoder
        
        do { // Do catch wrapper as methods throw errors.
            let photoData = try propertyList.encode(photos) // Encode our array into a variable.
            try photoData.write(to: fileURL) // Write encoded data to our unwrapped url.
            
        }catch {
            print("Error encoding Photos: \(error)")
        }
    }
    
    func loadFromPersistentStore() {
        guard let fileURL = photosURL else {return} // Unwrap our URL again
        let propertyList = PropertyListDecoder() // Initialize a decoder instance.
        
        do { // Do catch wrapper as methods throw errors.
            let data = try Data(contentsOf: fileURL) // Try to store the data from our unwrapped URL into a variable.
            let decodedPhotos = try propertyList.decode([Photo].self , from: data ) // Try to decode data from our stored data, into an array of Photo properties.
            photos = decodedPhotos // Update our Photos array to what we loaded.
        } catch {
            print("Error decoding Photos: \(error)")
        }
    }
}
