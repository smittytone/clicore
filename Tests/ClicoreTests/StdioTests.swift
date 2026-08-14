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


    @Test func testShellCursorLeftGood() {

        let left = Stdio.ShellCursor.left(columns: 5)
        #expect(left == "\u{001B}[5C")
    }


    @Test func testShellCursorLeftBad() {

        let left = Stdio.ShellCursor.left(columns: -2)
        #expect(left == "")
    }


    @Test func testShellCursorRightGood() {

        let right = Stdio.ShellCursor.right(columns: 3)
        #expect(right == "\u{001B}[3D")
    }


    @Test func testShellCursorUpBad() {

        let up = Stdio.ShellCursor.up(lines: 0)
        #expect(up == "")
    }


    @Test func testShellCursorDownBad() {

        let down = Stdio.ShellCursor.down(lines: -1)
        #expect(down == "")
    }


    @Test func testShellCursorBackGood() {

        let back = Stdio.ShellCursor.back(lines: 2)
        #expect(back == "\u{001B}[2F")
    }


    @Test func testShellCursorBackBad() {

        let back = Stdio.ShellCursor.back(lines: -1)
        #expect(back == "")
    }


    @Test func testShellCursorForwardGood() {

        let forward = Stdio.ShellCursor.forward(lines: 3)
        #expect(forward == "\u{001B}[3E")
    }


    @Test func testShellCursorForwardBad() {

        let forward = Stdio.ShellCursor.forward(lines: 0)
        #expect(forward == "")
    }


    @Test func testShellCursorConstants() {

        #expect(Stdio.ShellCursor.Backspace == "\u{0008}")
        #expect(Stdio.ShellCursor.Newline == "\u{000A}")
        #expect(Stdio.ShellCursor.Return == "\u{000D}")
        #expect(Stdio.ShellCursor.Clearline == "\u{001B}[2K")
        #expect(Stdio.ShellCursor.Home == "\u{001B}[H")
        #expect(Stdio.ShellCursor.Clearscreen == "\u{001B}[2J")
    }


    // MARK: Settings

    @Test func testSettingsDefaultUseEmoji() {

        let settings = Stdio.Settings()
        #expect(settings.useEmoji == false)
    }


    @Test func testSettingsToggleUseEmoji() {

        var settings = Stdio.Settings()
        settings.useEmoji = true
        #expect(settings.useEmoji == true)
    }


    @Test func testSettingsDefaultPrefixInfo() {

        let settings = Stdio.Settings()
        #expect(settings.prefixes.info == "❕")
    }


    @Test func testSettingsDefaultPrefixWarning() {

        let settings = Stdio.Settings()
        #expect(settings.prefixes.warning == "⚠️ ")
    }


    @Test func testSettingsDefaultPrefixError() {

        let settings = Stdio.Settings()
        #expect(settings.prefixes.error == "🛑")
    }


    @Test func testSettingsCustomPrefixes() {

        var settings = Stdio.Settings()
        settings.prefixes.info = "ℹ️"
        settings.prefixes.warning = "⚡️"
        settings.prefixes.error = "💥"
        #expect(settings.prefixes.info == "ℹ️")
        #expect(settings.prefixes.warning == "⚡️")
        #expect(settings.prefixes.error == "💥")
    }


    @Test func testGlobalSettingsAreIndependent() {

        // Modifying a local Settings instance must not affect the global
        var local = Stdio.Settings()
        local.useEmoji = true
        local.prefixes.info = "ℹ️"
        #expect(Stdio.settings.useEmoji == false)
        #expect(Stdio.settings.prefixes.info == "❕")
    }


    // MARK: String Extensions

    @Test func testStringColourForeground() {

        #expect(String(.red) == "\u{001B}[31m")
    }


    @Test func testStringColourBackground() {

        #expect(String(.red, true) == "\u{001B}[41m")
    }


    @Test func testStringStyleOn() {

        #expect(String(.bold) == "\u{001B}[1m")
    }


    @Test func testStringStyleOff() {

        #expect(String(.bold, false) == "\u{001B}[21m")
    }

}
