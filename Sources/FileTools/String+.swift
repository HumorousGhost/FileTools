//
//  File.swift
//  
//
//  Created by Liqun Zhang on 2023/5/20.
//

import Foundation

extension String {
    var pathExtension: String {
        (self as NSString).pathExtension
    }
    
    var deletePathExtension: String {
        (self as NSString).deletingPathExtension
    }
}
