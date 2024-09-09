//
//  File.swift
//  
//
//  Created by Vinícius dos Reis on 02/09/24.
//

import JWT

struct JWTClaims: JWTPayload {
    
    var username: String
    var exp: ExpirationClaim

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
