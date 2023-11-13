//
//  sphinxTests.swift
//  sphinxTests
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import XCTest
@testable import sphinx

class sphinxTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}


class sphinxOnionMessageTests: XCTestCase {
    var sphinxOnionManager = SphinxOnionManager.sharedInstance
    let test_mnemonic1 = "artist globe myself huge wing drive bright build agree fork media gentle"
    let test_mnemonic1_expected_seed = "dea65b969cd1b0926889f35699586ff7e19469c64e7a944d0c6b68342158a1a8"
    let test_mnemonic1_expected_okKey = "03a898d978e42c9feaa25ca103d70b27a2a83472b3b00cd11bbf2a9b3be14460f4"
    let test_mnemonic1_expected_xpub = "tpubDAGRb7j9yEF51RrPBjxYk6inEyxzX9oZEqRfWGGtnhEaux2xsma2eQFNBYeRgEHLC5pc4Cif4KPJXXRqS1aTErvhvTiZGaGggq9UoTZdEsH"
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_seed_generation(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1) else{
            XCTFail("Key generation has failed (test_seed_generation)")
            return
        }
        XCTAssert(seed == test_mnemonic1_expected_seed)
    }
    
    func test_ok_key_generation(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
          let ok_key = sphinxOnionManager.getAccountOnlyKeysendPubkey(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_ok_key_generation)")
            return
      }
        XCTAssert(ok_key == test_mnemonic1_expected_okKey)
    }
    
    func test_xpub_generation(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
          let xpub = sphinxOnionManager.getAccountXpub(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_ok_key_generation)")
            return
      }
        XCTAssert(xpub == test_mnemonic1_expected_xpub)
    }
    
    func test_connect_to_mqtt_broker(){
        guard let seed = sphinxOnionManager.getAccountSeed(mnemonic: test_mnemonic1),
          let xpub = sphinxOnionManager.getAccountXpub(seed: seed) else{
              XCTFail("failure to properly generate seed & then ok key (test_connect_to_mqtt_broker)")
            return
      }
        let success = sphinxOnionManager.connectToBroker(seed: seed, xpub: xpub)
        XCTAssert(success == true, "Failed to connect to test broker :/")
    }

}
