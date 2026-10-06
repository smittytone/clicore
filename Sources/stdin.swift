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

    /**
     Gets a character from `STDIN` after the `ENTER` key has been pressed.

     - Parameters:
        - prompt:        Text to present to the user.
        - choices:       String containing all the valid keypresses. Used to display a list of
                         options immediately after the prompt. Default: "YN".
        - caseSensitive: Should the case of the entered character be checked? Default: `false`.

     - Returns: The entered key as a string, or `nil` on error (from the tty or a mis-key).
     */
    public static func getCharacter(_ prompt: String, _ choices: String = "YN", _ caseSensitive: Bool = false) -> String? {

        guard !prompt.isEmpty else { return nil }
        guard !choices.isEmpty else { return nil }

        // Assemble the choice display
        let choiceText = assembleChoices(choices)

        // Display the prompt plus options
        Stdio.write(message: "\(prompt) \(choiceText) ", to: Stdio.ShellRoutes.Output)

        // Get the input
        let inputValue = UInt32(getchar())
        if let inputThing = UnicodeScalar(inputValue) {
            let entry = Character(inputThing)
            for choice in choices {
                if caseSensitive && entry == choice {
                    return String(choice)
                } else if !caseSensitive && entry.lowercased() == choice.lowercased() {
                    return String(choice)
                }
            }
        }

        return  nil
    }


    /**
     Gets a key press from `STDIN` by first putting it it into raw mode (restores on exit).

     - Examples"
        - `getKey("Enter your choice", "AB")` will present to the useer:
           Enter your choice [A/B]

     - Parameters:
        - prompt:  Text to present to the user.
        - choices: String containing all the valid keypresses. Used to display a list of
                   options immediately after the prompt. Default: "YN".

     - Returns: The entered key as a string, or `nil` on error (from the tty or a mis-key).
     */
    public static func getKey(_ prompt: String, _ choices: String = "YN") -> String? {

        guard !prompt.isEmpty else { return nil }
        guard !choices.isEmpty else { return nil }

        var originalTermios = termios()
        let fileHandle = Stdio.ShellRoutes.Input.fileDescriptor

        defer {
            // Reset to disable raw mode on exit
            _ = tcsetattr(fileHandle, TCSAFLUSH, &originalTermios)
        }

        guard tcgetattr(fileHandle, &originalTermios) != -1 else { return nil }
        var raw = originalTermios

#if os(Linux) || os(FreeBSD)
        raw.c_iflag &= ~UInt32(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
        raw.c_oflag &= ~UInt32(OPOST)
        raw.c_cflag |= UInt32(CS8)
        raw.c_lflag &= ~UInt32(ECHO | ICANON | IEXTEN | ISIG)
#else
        raw.c_iflag &= ~UInt(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
        raw.c_oflag &= ~UInt(OPOST)
        raw.c_cflag |= UInt(CS8)
        raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
#endif
        // VMIN = 16
        raw.c_cc.16 = 1

        guard tcsetattr(fileHandle, Int32(TCSAFLUSH), &raw) >= 0 else { return nil }

        // Assemble the choice display
        let choiceText = assembleChoices(choices, false)

        // Display the prompt plus options
        Stdio.write(message: "\(prompt) \(choiceText) ", to: Stdio.ShellRoutes.Output)  // Should be err???

        // Get the input -- this waits for a keypress
        // NOTE Does not accept complex characters like emoji
        var byte: UInt8 = 0
        read(fileHandle, &byte, 1)

        // Process the input
        let entry = Character(UnicodeScalar(byte))
        for choice in choices {
            if entry.lowercased() == choice.lowercased() {
                Stdio.write(message: "\n", to: Stdio.ShellRoutes.Output)
                return String(choice)
            }
        }

        Stdio.write(message: "\n", to: Stdio.ShellRoutes.Output)
        return nil
    }


    private static func assembleChoices(_ choices: String, _ addEnter: Bool = true) -> String {

        // Assemble the choice display
        var choiceText = "["
        for choice in choices {
            choiceText += String(choice)
            if choice != choices.last {
                choiceText += "/"
            } else {
                choiceText += "]\(addEnter ? "+ENTER" : "")"
            }
        }

        return choiceText
    }
}
