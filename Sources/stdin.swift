/*
    clicore
    stdin.swift

    Copyright © 2026 Tony Smith. All rights reserved.

    MIT License
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sub-license, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

import Foundation


/*
 Base STDIB library for use in my CLI applications.

 Data values are a mix of enums and structs, accessed via the `Stdin` namespace.

 Functions are static and so are likewise accessed via the `Stdin` namespace.
 */
public struct Stdin {

    public static func getCharacter(_ prompt: String, _ choices: String = "YN") -> String? {

        guard !prompt.isEmpty else { return nil }
        guard !choices.isEmpty else { return nil }

        // Assemble the choice display
        var choiceText = "["
        for choice in choices {
            choiceText += String(choice)
            if choice != choices.last {
                choiceText += "/"
            } else {
                choiceText += "]+ENTER "
            }
        }

        // Display the prompt plus options
        Stdio.write(message: "\(prompt) \(choiceText)", to: Stdio.ShellRoutes.Output)

        // Get the input
        let inputValue = UInt32(getchar())
        if let inputThing = UnicodeScalar(inputValue) {
            let inputCharacter = Character(inputThing)
            for choice in choices {
                if inputCharacter == choice {
                    return String(choice)
                }
            }
        }

        return  nil
    }
}
