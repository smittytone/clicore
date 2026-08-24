/*
    clicore
    processes.swift

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



// MARK: - Process Handling Functions

/**
 Generic pre-Swift Concurrency macOS process creation and run function.

 - Parameters:
    - app:  The location of the app.
    - with: Array of arguments to pass to the app.

 - Returns: A tuple containing an error code (or zero for no error) and either
            the STD OUT output on success, or STD ERR output on error.
 */
public func runProcess(app path: String, with args: [String]) -> (Int32, String) {

    let task = Process()
    task.qualityOfService = .userInitiated
    task.executableURL = URL(fileURLWithPath: path)
    if args.count > 0 { task.arguments = args }
    // FROM 0.5.1 -- use an app-specific queue rather than main
    let stdioQueue = DispatchQueue(label: "com.clicore.queue")

    // Pipe out the output to avoid putting it in the log
    let stdOutPipe = Pipe()
    let stdErrPipe = Pipe()
    var outputText = ""
    var errorText = ""

    let stdOutHandle = stdOutPipe.fileHandleForReading
    stdOutHandle.readabilityHandler = { fileHandle in
        // If there's available output to the redirected file handle,
        // get it and store it for processing later
        let data = fileHandle.availableData
        if let output = String(data: data, encoding: .utf8) {
            stdioQueue.async {
                outputText += output
            }
        }
    }

    let stdErrHandle = stdErrPipe.fileHandleForReading
    stdErrHandle.readabilityHandler = { fileHandle in
        // If there's available output to the redirected file handle,
        // get it and store it for processing later
        let data = fileHandle.availableData
        if let output = String(data: data, encoding: .utf8) {
            stdioQueue.async {
                errorText += output
            }
        }
    }

    // Hook up the outputs
    task.standardOutput = stdOutPipe
    task.standardError = stdErrPipe

    do {
        try task.run()
    } catch {
        return (1, error.localizedDescription)
    }

    // Block until the task has completed (short tasks ONLY)
    task.waitUntilExit()

    // Clear the 'data available' handlers
    // NOTE This seems to fix garbled data issues
    stdOutHandle.readabilityHandler = nil
    stdErrHandle.readabilityHandler = nil

    // Task completed successfully so return the standard output
    // TODO `outputText` will be empty if the called tool doesn't issue
    //      to `stdout` but only to `stderr`, so we will need to allow
    //      for this in future.
    if task.terminationStatus == 0 {
        return (0, outputText)
    }

    // Task reported an error, so pass it back with any error message
    return (task.terminationStatus, errorText)
}


#if os(macOS)
/**
 Swift Concurrency version of `runProcess()` to be used in async-await contexts.

 - Requires: macOS 12+

 - Parameters:
    - app:  The location of the app.
    - with: Array of arguments to pass to the app.

 - Returns: A tuple containing an error code (or zero for no error) and either
            the STD OUT output on success, or STD ERR output on error.
 */

@available(macOS 12.0, *)
public func runProcessAsync(app path: String, with args: [String]) async -> (Int32, String, String) {

    let task = Process()
    task.qualityOfService = .userInitiated
    task.executableURL = URL(fileURLWithPath: path)
    if args.count > 0 { task.arguments = args }

    let stdOutCollector = ChunkOutputCollector()
    let stdErrCollector = ChunkOutputCollector()
    let stdOutPipe = Pipe()
    let stdErrPipe = Pipe()
    let stdOutHandle = stdOutPipe.fileHandleForReading
    let stdErrHandle = stdErrPipe.fileHandleForReading
    task.standardOutput = stdOutPipe
    task.standardError = stdErrPipe

    // Kick off chunk-based readers as concurrent tasks
    let stdOutTask = Task {
        try await readAllChunks(from: stdOutHandle) {
            await stdOutCollector.appendOutput($0)
        }
    }

    let stdErrTask = Task {
        try await readAllChunks(from: stdErrHandle) {
            await stdErrCollector.appendOutput($0)
        }
    }

    do {
        try task.run()
    } catch {
        stdOutTask.cancel()
        stdErrTask.cancel()
        return (1, "", error.localizedDescription)
    }

    // Wait for the process to exit off the main actor
    await withCheckedContinuation { continuation in
        task.terminationHandler = { _ in
            continuation.resume()
        }
    }

    // Let the readers drain any remaining buffered data, then stop them
    _ = try? await stdOutTask.value
    _ = try? await stdErrTask.value

    return (task.terminationStatus, await stdOutCollector.text, await stdErrCollector.text)
}


/**
 Swift Concurrency-oriented actor structure that asynchronously collates substrings
 (chunks) into a final string.

 It is expected that `ChunkOutputCollector` is instanced within `runProcessAsync()` and
 its `appendOutput()` called from within an async-await closure.

 - Requires: macOS 12+

 */
@available(macOS 12.0, *)
actor ChunkOutputCollector {

    private(set) var text = ""

    func appendOutput(_ chunk: String) {
        text += chunk
    }
}


/**
 Swift Concurrency-oriented function to extract asynchronously collated substrings from STDIO
 filehandles and collate them into a single string for subsequent processing.

 It is expected that `readAllChunks()` is called from within `runProcessAsync()`.

 - Requires: macOS 12+

 - Parameters:
    - from: The source file handle.
    - into: An await-async closure that asynchronously collates a received byte-sequence as
            a string into a larger string. See `ChunkOutputCollector` and `runProcessAsync()`.
 */
@available(macOS 12.0, *)
private func readAllChunks(from handle: FileHandle, into append: @escaping (String) async -> Void) async throws {
    var buffer = [UInt8]()
    for try await byte in handle.bytes {
        buffer.append(byte)
        if let str = String(bytes: buffer, encoding: .utf8) {
            await append(str)
            buffer.removeAll(keepingCapacity: true)
        }
    }

    // Flush any trailing bytes that never formed a complete String
    if !buffer.isEmpty, let str = String(bytes: buffer, encoding: .utf8) {
        await append(str)
    }
}
#endif
