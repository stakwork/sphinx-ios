//
//  sphinxOnionPlaintextMessagesTests.swift
//  sphinxTests
//
//  Created by James Carucci on 12/6/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import XCTest
@testable import sphinx

final class sphinxOnionPlaintextMessagesTests: XCTestCase {
    let som = SphinxOnionManager.sharedInstance

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sphinxOnionAddContactTests().establish_self_contact()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        som.
        XCTAssert(false)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

}
