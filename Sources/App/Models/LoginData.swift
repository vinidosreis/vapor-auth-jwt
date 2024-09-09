//
//  File.swift
//  
//
//  Created by Vinícius dos Reis on 02/09/24.
//

import Vapor

struct LoginData: Content {
    var username: String
    var password: String
}
