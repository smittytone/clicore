/*
    clicore
    cli.swift

    Copyright © 2025 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

import Foundation


public struct Cli {

    public static let CtrlCExitCode: Int32 = 130
    public static let CtrlCMessage: String = "\(Stdio.ShellCursor.Return)\(Stdio.ShellCursor.Clearline)"


    /**
     Locate combined args (eg. -lj) and convert into separate args
     for later processing by the host app.

     - Parameters:
        - args The arguments from the command line.

     - Returns: Regular args plus converted ones.
     */
    public static func unify(args: [String]) -> [String] {

        var newArgs: [String] = []

        for arg in args {
            // Look for compound flags, ie. a single dash followed by
            // more than one flag identifier
            if arg.prefix(1) == "-" && arg.prefix(2) != "--" {
                if arg.count > 2 {
                    // arg is of form '-mfs'
                    for subArg in arg {
                        // Check for and ignore interior dashes
                        // eg. in `-mf-l`
                        if subArg == "-" {
                            continue
                        }

                        // Retain the flag as a standard arg for subsequent processing
                        newArgs.append("-\(subArg)")
                    }

                    continue
                }
            }

            // FROM 0.2.0
            // Handle combined args with assignments
            if arg.contains("=") {
                // Argument contains an assignment
                let parts = arg.components(separatedBy: "=")
                if arg.count > 2 {
                    // arg is of form '-m=something'
                    for subArg in parts {
                        // Add the elements of the combined arg as separate args
                        newArgs.append(subArg)
                    }

                    continue
                }
            }

            // It's an ordinary arg, so retain it
            newArgs.append(arg)
        }

        return newArgs
    }


    /**
    Get the value of a named shell environment variable.

    - Parameters:
       - envVar The environment variable, eg. `TERM`.

    - Returns: The environment variable's value as a string,
               or an empty string on error/absence.
     */
    public static func getEnvVar(_ envVar: String) -> String {

        guard let rawValue = getenv(envVar) else { return "" }
        return String(utf8String: rawValue) ?? ""
    }
}
