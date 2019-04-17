//
//  Document.swift
//  ImageGallery_Persistent
//
//  Created by Ashish Bansal on 10/04/19.
//  Copyright © 2019 Ashish Bansal. All rights reserved.
//

import UIKit

class ImageGalleryDocument: UIDocument {
    
    var galleryImageInfo = [ImageInfo]()
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        let jsonData = try! JSONEncoder().encode(galleryImageInfo)
        return jsonData
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        let documentDatatype = type(of: galleryImageInfo)
        if let contents = contents as? Data, !contents.isEmpty
        {
            galleryImageInfo = try! JSONDecoder().decode(documentDatatype, from: contents)
        }
    }
}

