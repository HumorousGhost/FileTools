//
//  File.swift
//  
//
//  Created by Liqun Zhang on 2023/5/20.
//

import Foundation

public class FileBase {
    var url: URL
    var size: Double
    var date: Double
    
    init(url: URL, size: Double, date: Double) {
        self.url = url
        self.size = size
        self.date = date
    }
}
