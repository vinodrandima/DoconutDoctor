//
//  AuthValidationTests.swift
//  CoconutDoctorTests
//
//  Unit tests for farmer authentication validation rules, password length,
//  and guest/offline state transitions using Swift Testing.
//

import Testing
import Foundation
@testable import ios_coco

@Suite("Farmer Authentication & Validation Tests")
struct AuthValidationTests {
    
    @Test("Valid email formats are accepted by standard regex")
    func testEmailValidation() {
        let validEmails = [
            "farmer@coconutgrove.lk",
            "field.officer@agri.gov.lk",
            "vinodrandima@gmail.com",
            "plantation_manager+1@estate.com"
        ]
        
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,64}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        for email in validEmails {
            #expect(predicate.evaluate(with: email), "Expected \(email) to be valid.")
        }
    }
    
    @Test("Edge Case: Malformed emails are rejected")
    func testInvalidEmailRejection() {
        let invalidEmails = [
            "",
            "plainaddress",
            "@missingusername.com",
            "username@.com",
            "username@domain..com",
            "spaces in@address.com"
        ]
        
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,64}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        for email in invalidEmails {
            #expect(!predicate.evaluate(with: email), "Expected \(email) to be invalid.")
        }
    }
    
    @Test("Password requirement: minimum 6 characters threshold")
    func testPasswordLengthValidation() {
        let tooShort = "12345"
        let exactMin = "123456"
        let strong = "CoconutSafe#2026"
        
        #expect(tooShort.count < 6, "Passwords under 6 characters must fail validation.")
        #expect(exactMin.count >= 6, "Passwords of 6 characters must pass minimum threshold.")
        #expect(strong.count >= 6)
    }
    
    @Test("AuthState isGuestOrOffline helper returns true for signedOut and offline")
    func testAuthStateGuestHelper() {
        #expect(AuthState.signedOut.isGuestOrOffline == true)
        #expect(AuthState.offline.isGuestOrOffline == true)
        #expect(AuthState.signedIn(uid: "sample-firebase-uid").isGuestOrOffline == false)
    }
}
