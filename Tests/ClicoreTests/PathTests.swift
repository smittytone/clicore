//
//  Test.swift
//  Clicore
//
//  Created by Tony Smith on 29/12/2025.
//

import Testing
import Clicore
import Foundation


struct PathTest {

    // MARK: - GetFullPath()

    @Test func testGetFullPathGoodDots() async throws {

        let path = "../example"
        let aPath = Path.getFullPath(path)
        #expect(!aPath.contains(".."))
    }


    @Test func testGetGoodPathGoodDot() async throws {

        let path = "./example/../../test"
        let aPath = Path.getFullPath(path)
        #expect(!aPath.contains(".") && !aPath.contains(".."))
    }


    // MARK: - ProcessRelativePath()

    @Test func testProcessRelativePath() async throws {

        let path = "/example/test/folder/../../../"
        let aPath = Path.processRelativePath(path)
        if ProcessInfo.processInfo.processName == "xctest" {
            // Xcode CMD-U path
            #expect(aPath == "/tmp")
        } else {
            // CLI `swift test` path -- update for YOUR environment
            #expect(aPath == "/Users/smitty/GitHub/clicore")
        }
    }


    // MARK: - DoesPathReferenceDirectory()

    @Test func testDoesPathReferenceDirectoryWithDir() async throws {

        let path = "/"
        #expect(Path.doesPathReferenceDirectory(path))
    }


    @Test func testDoesPathReferenceDirectoryWithFile() async throws {

        let path = "/tmp/test"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            #expect(!Path.doesPathReferenceDirectory(path))
        } catch {
            #expect(Bool(false))
        }
    }


    // MARK: - getFileContents()

    @Test func testDoesGetFileContentsValidFile() async throws {

        let path = "/tmp/test"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            let readback = Path.getFileContents(path)
            #expect(readback.count == 4)
        } catch {
            #expect(Bool(false))
        }
    }


    @Test func testDoesGetFileContentsNonexistentFile() async throws {

        let path = "/tmp/testz"
        let readback = Path.getFileContents(path)
        #expect(readback.isEmpty)
    }


    @Test func testDoesGetFileContentsDir() async throws {

        let path = "/tmp"
        let readback = Path.getFileContents(path)
        #expect(readback.isEmpty)
    }

}
