
import XCTest
@testable import CaptureTheFlag

class ServerAccessTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let ws = WebSocketRequestResponse()
        let serverAccess = ServerAccess(requestResponse: ws)
        let exp = expectation(description: "wait")
        serverAccess.initaiteConnection(username: "Ethan", password: "Ethan123", callback: {(error) in
            if error != nil {
                print(error!)
            } else {
                serverAccess.createGame(key: "12345", gameName: "test", callback: {(error) in
                    if error != nil {
                        print(error!)
                    } else {
                        serverAccess.joinGame(key: "12345", playerName: "Ethan", callback: {(error) in
                            if error != nil {
                                print(error!)
                            } else {
                                serverAccess.joinTeam(teamId: 1, callback: {(error) in
                                    if error != nil {
                                        print(error!)
                                    } else {
                                        serverAccess.nextGameState(callback: {(error) in
                                            if error != nil {
                                                print(error!)
                                            } else {
                                                serverAccess.testGetPlayerTeamsFlags(callback: {(players, flags, teams, error) in
                                                    print("THIS ISSS GETTTTING CALLLLED")
                                                    if error != nil {
                                                        print(error!)
                                                    } else {
                                                        print(players)
                                                        print()
                                                        print(flags)
                                                        print()
                                                        print(teams)
                                                    }
                                                    exp.fulfill()
                                                })
                                            }
                                        })
                                    }
                                })
                                
                            }
                        })
                    }
                })
            }
        })
        
        
        
        
        waitForExpectations(timeout: 100, handler: nil)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
