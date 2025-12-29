//
//  Test.swift
//  Clicore
//
//  Created by Tony Smith on 29/12/2025.
//

import Testing
import Clicore


struct StdioTest {

    // MARK: ShellColour
    
    @Test func testShellColourForeground() async throws {

        Stdio.ShellColour.allCases.forEach {
            #expect($0.foreground() == "\u{001B}[\(30 + $0.rawValue)m")
        }
    }


    @Test func testShellColourBackground() async throws {

        Stdio.ShellColour.allCases.forEach {
            #expect($0.background() == "\u{001B}[\(40 + $0.rawValue)m")
        }
    }


    @Test func testShellColourGoodRawValue() async throws {

        #expect(Stdio.ShellColour(rawValue: 3) == .yellow)
    }


    @Test func testShellColourBadRawValue() async throws {

        #expect(Stdio.ShellColour(rawValue: 666) == nil)
    }


    // MARK: ShellStyle

    @Test func testShellStyleOn() async throws {

        Stdio.ShellStyle.allCases.forEach {
            #expect($0.on() == "\u{001B}[\($0.rawValue)m")
        }
    }


    @Test func testShellStyleOff() async throws {

        Stdio.ShellStyle.allCases.forEach {
            #expect($0.off() == "\u{001B}[\(20 + $0.rawValue)m")
        }
    }


    @Test func testShellStyleGoodRawValue() async throws {

        #expect(Stdio.ShellStyle(rawValue: 1) == .bold)
    }


    @Test func testShellStyleBadRawValue() async throws {

        #expect(Stdio.ShellStyle(rawValue: 666) == nil)
    }


    // MARK: ShellCursor

    @Test func testShellCursorUpGood() async throws {

        let up = Stdio.ShellCursor.up(lines: 4)
        #expect(up == "\u{001B}[4A")
    }


    @Test func testShellCursorDownGood() async throws {

        let down = Stdio.ShellCursor.down(lines: 11)
        #expect(down == "\u{001B}[11B")
    }


    @Test func testShellCursorRightBad() async throws {

        let right = Stdio.ShellCursor.right(columns: -4)
        #expect(right == "")
    }


    @Test func testShellCursorClsGood() async throws {

        let cls = Stdio.ShellCursor.cls()
        #expect(cls == "\u{001B}[2J\u{001B}[H")
    }


    @Test func textShellCursorToColumnGood() async throws {

        let col = Stdio.ShellCursor.to(column: 3)
        #expect(col == "\u{001B}[3G")
    }


    @Test func textShellCursorToColumnBad() async throws {

        let col = Stdio.ShellCursor.to(column: -4)
        #expect(col == "\u{001B}[0G")
    }

}
