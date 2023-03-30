//
//  Encoding.swift
//  SDKTests
//
//  Created by Christoph Scherbeck on 17.03.23.
//

import XCTest
@testable import SDK

final class Encoding: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    
    func test_Decoding() throws {
        let testByteArray = Data ([127, 151, 20, 0, 57, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 81, 200, 132, 75, 174, 135, 97, 180, 36, 143])
        let sut = Decoder().ValidateMessage(of: testByteArray)
        XCTAssertEqual(sut, [151, 20, 0, 57, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 81, 200, 132, 75, 174, 135, 97, 180, 36])
    }
    
    func test_GetPosition() throws {
        
        let positionMessage = Data([127, 151, 20, 0, 57, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 81, 200, 132, 75, 174, 135, 97, 180, 36, 143])
        let sut = TraceletResponse().GetPositionResponse(from: positionMessage)
        XCTAssertEqual(sut.xCoord ,2.0)
        XCTAssertEqual(sut.yCoord ,5.7)
        XCTAssertEqual(sut.zCoord ,1.0)
        XCTAssertEqual(sut.covYy ,0.0)
        XCTAssertEqual(sut.covXy ,0.0)
        XCTAssertEqual(sut.covXx ,0.0)
        XCTAssertEqual(sut.siteID ,"0x517e")
        XCTAssertEqual(sut.signature ,"2644846116545987784")
        
    }
    
    
    // Test Description:
    // Take custom position message without start/end byte and encode it
    // take encoded message and decode it
    // Test passed when :decoded bytes == inital custom message
    func test_Encoder() throws {
        
        let inputMessageWithoutStartEndByte = [UInt8] ([151, 20, 0, 57, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 81, 200, 132, 75, 174, 135, 97, 180, 36])
        let encbytes = Encoder.encodeBytes(inputMessageWithoutStartEndByte)
        let decbytes = Decoder().ValidateMessage(of: encbytes)
        XCTAssertEqual([UInt8](decbytes) ,inputMessageWithoutStartEndByte)
        
    }

}
