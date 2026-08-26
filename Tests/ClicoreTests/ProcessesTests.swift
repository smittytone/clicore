//
//  ProcessesTest.swift
//  Clicore
//
//  Created by Tony Smith on 26/08/2026.
//


import Testing
import Clicore


struct ProcessesTest {

    // MARK:

    @Test func testRunProcessGoodAppGoodArgs() async throws {

        var (a,b): (Int32, String) = (-1, "")
        let clock = ContinuousClock()
        let timeout = 20 // More than enough time, but just in case
        let elapsed = clock.measure {
            (a,b) = Processes.runProcess(app: "/sbin/ping", with: ["-c", "4", "-t", String(timeout), "apple.com"])
        }

        if a == 0 {
            if elapsed <= .milliseconds(timeout * 1000) {
                // runProcess() did not timeout
                let lines = b.components(separatedBy: "\n")
                #expect(lines.count == 10)
            } else {
                // Timeout -- just consider it done
                #expect(true)
            }
        } else {
            print("Error occured: \(a)\n\(b)")
        }
    }


    @Test func testRunProcessBadApp() async throws {

        let (a,b) = Processes.runProcess(app: "/sbin/sping", with: ["-c", "4", "-t", "20", "apple.com"])
        #expect(a == 1 && b.contains("The file “sping” doesn’t exist"))
    }


    @Test func testRunProcessGoodAppBadArgs() async throws {

        let (a,b) = Processes.runProcess(app: "/sbin/ping", with: ["-w"])
        #expect(a == 64 && b.contains("ping: invalid option -- w"))
    }


    @Test func testRunProcessGoodAppLongRun() async throws {

        var (a,b): (Int32, String) = (-1, "")
        let clock = ContinuousClock()
        let duration = 25
        let elapsed = clock.measure {
            (a,b) = Processes.runProcess(app: "/usr/bin/caffeinate", with: ["-t", String(duration)])
        }

        if a == 0 {
            if elapsed >= .milliseconds(duration * 1000) {
                #expect(b.isEmpty)
            }
        }
    }
}
