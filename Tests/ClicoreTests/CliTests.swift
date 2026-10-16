//
//  Test.swift
//  Clicore
//
//  Created by Tony Smith on 29/12/2025.
//

import Testing
import Clicore


struct CliTest {

    @Test func testUnifyEqualsArgsOneGood() async throws {

        let args = Cli.unify(args: ["-m=something"], false)
        #expect(args.count == 2 && args[0] == "-m" && args[1] == "something")
    }


    @Test func testUnifyEqualsArgsTwoGood() async throws {

        let args = Cli.unify(args: ["-m=something", "-d=everything"], false)
        #expect(args.count == 4 && args[0] == "-m" && args[1] == "something" && args[2] == "-d" && args[3] == "everything")
    }


    @Test func testUnifyEqualsArgsMixedGood() async throws {

        let args = Cli.unify(args: ["-v", "wall0p", "-m=something"], false)
        #expect(args.count == 4 && args[2] == "-m" && args[3] == "something")
    }


    @Test func testUnifyCombinedArgsGood() async throws {

        let args = Cli.unify(args: ["-vkj"], false)
        #expect(args.count == 3 && args[0] == "-v" && args[1] == "-k" && args[2] == "-j")
    }


    @Test func testUnifyCombinedAndEqualsArgsGood() async throws {

        let args = Cli.unify(args: ["-vkj", "-m=something"], false)
        #expect(args.count == 5 && args[0] == "-v" && args[1] == "-k" && args[2] == "-j" && args[3] == "-m" && args[4] == "something")
    }


    @Test func testUnifyCombinedAndEqualsArgsGood2() async throws {

        let args = Cli.unify(args: ["-m=something", "-vkj"], false)
        #expect(args.count == 5 && args[2] == "-v" && args[3] == "-k" && args[4] == "-j" && args[0] == "-m" && args[1] == "something")
    }


    @Test func testUnifyEmptyArgs() {

        let args = Cli.unify(args: [])
        #expect(args.isEmpty)
    }


    @Test func testUnifyPlainArgs() {

        let args = Cli.unify(args: ["foo", "bar"], false)
        #expect(args == ["foo", "bar"])
    }


    @Test func testUnifyLongFormArgs() {

        let args = Cli.unify(args: ["--verbose", "--output"], false)
        #expect(args == ["--verbose", "--output"])
    }


    @Test func testUnifyMultipleArgs() {

        let args = Cli.unify(args: ["-hj", "--verbose", "-m=something", "--output"], false)
        #expect(args == ["-h", "-j", "--verbose", "-m", "something", "--output"])
    }


    @Test func testUnifySingleShortFlag() {

        let args = Cli.unify(args: ["-v"], false)
        #expect(args == ["-v"])
    }


    @Test func testUnifyCombinedArgsWithInteriorDash() {

        let args = Cli.unify(args: ["-mf-l"], false)
        #expect(args == ["-m", "-f", "-l"])
    }


    @Test func testUnifyEqualsArgWithMultipleEquals() {

        let args = Cli.unify(args: ["-m=a=b"], false)
        #expect(args == ["-m", "a=b"])
    }


    @Test func testUnifyEqualsArgWithMultipleEqualsNoFinal() {

        let args = Cli.unify(args: ["-m=a="], false)
        #expect(args == ["-m", "a="])
    }


    @Test func testGetEnvVarKnown() {

        let value = Cli.getEnvVar("PATH")
        #expect(!value.isEmpty)
    }


    @Test func testGetEnvVarUnknown() {

        let value = Cli.getEnvVar("CLICORE_NONEXISTENT_VAR_XYZ")
        #expect(value.isEmpty)
    }


    @Test func testUnifyEqualsArgWithMultipleEqualsAndPriorArgs() {

        let args = Cli.unify(args: ["-v", "-m=a=b"], false)
        #expect(args == ["-v", "-m", "a=b"])
    }


    @Test func testUnifyDropFirstArg() {

        let args = Cli.unify(args: ["clicore", "-v", "-m=a=b"])
        #expect(args == ["-v", "-m", "a=b"])
    }
}
