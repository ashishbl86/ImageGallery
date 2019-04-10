//
//  Document.swift
//  ImageGallery_Persistent
//
//  Created by Ashish Bansal on 10/04/19.
//  Copyright © 2019 Ashish Bansal. All rights reserved.
//

import UIKit

class Document: UIDocument {
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
    }
}

