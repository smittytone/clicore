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


public struct Processes {


    // MARK: - Process Handling Functions

    /**
     Generic pre-Swift Concurrency macOS process creation and run function.

     Works on macOS and Linux.

     - Parameters:
        - app:  The location of the app.
        - with: Array of arguments to pass to the app.
        - in:   Directory in which to run the app. This is not recommended 
                to be used on Linux builds due to issues with the Linux version 
                of Swift's Foundation library.

     - Returns: A tuple containing an error code (or zero for no error) and either
                the STD OUT output on success, or STD ERR output on error.
     */
    public static func runProcess(app path: String, with args: [String], in directory: URL? = nil) -> (Int32, String) {

        let task = Process()
        task.qualityOfService = .userInitiated
        task.executableURL = URL(fileURLWithPath: path)

        // FROM 0.7.0 -- support the addition of a target directory
        if let dir = directory {
            task.currentDirectoryURL = dir
        }

        if args.count > 0 {
            task.arguments = args
        }

        // Pipe out the output to avoid putting it in the log
        let stdOutPipe = Pipe()
        let stdErrPipe = Pipe()

        // Hook up the outputs
        task.standardOutput = stdOutPipe
        task.standardError = stdErrPipe

        do {
            try task.run()
        } catch {
            // NOTE Have to pass `1` as a literal here
            return (1, error.localizedDescription)
        }

        var errorData = Data()
        var outputData = Data()
        let group = DispatchGroup()
        DispatchQueue.global().async(group: group) {
            if let data = try? stdErrPipe.fileHandleForReading.readToEnd() { 
                errorData = data 
            }
        }

        if let data = try? stdOutPipe.fileHandleForReading.readToEnd() {
            outputData = data
        }

        group.wait()
        task.waitUntilExit()

        let outputText = String(decoding: outputData, as: UTF8.self)
        let errorText = String(decoding: errorData, as: UTF8.self)

        // Task completed successfully so return the standard output
        // TODO `outputText` will be empty if the called tool doesn't issue
        //      to `stdout` but only to `stderr`. `errorText` may be empty too.
        if task.terminationStatus == 0 {
            return (task.terminationStatus, !outputText.isEmpty ? outputText : errorText)
        }

        // Task reported an error, so pass it back with any error message
        return (task.terminationStatus, errorText)
    }


    /**
     Swift Concurrency version of `runProcess()` to be used in async-await contexts.

     Works on macOS and Linux: each pipe's `readabilityHandler` callbacks are bridged 
     into an `AsyncStream`, so no thread is blocked while the process runs.

     - Parameters:
        - app:  The location of the app.
        - with: Array of arguments to pass to the app.
        - in:   Directory in which to run the app. This is not recommended 
                to be used on Linux builds due to issues with the Linux version 
                of Swift's Foundation library.

     - Returns: A tuple containing an error code (or zero for no error), 
                the STD OUT output and the STD ERR output.
     */
    public static func runProcessAsync(app path: String, with args: [String], in directory: URL? = nil) async -> (Int32, String, String) {

        let task = Process()
        task.qualityOfService = .userInitiated
        task.executableURL = URL(fileURLWithPath: path)
        task.standardOutput = Pipe()
        task.standardError = Pipe()

        if args.count > 0 { task.arguments = args } 
        if let dir = directory {
            task.currentDirectoryURL = dir
        }

        // The stream buffers the exit status, so it can't be missed if the process exits
        // before we start waiting. Set the handler before `run()` for the same reason
        let (exitStream, exitContinuation) = AsyncStream<Int32>.makeStream()
        task.terminationHandler = { process in
            exitContinuation.yield(process.terminationStatus)
            exitContinuation.finish()
        }

        do {
            try task.run()
        } catch {
            // Don't start reading: the pipes' write ends are still open in this process,
            // so EOF would never arrive
            return (1, "", error.localizedDescription)
        }

        // Drain both pipes while waiting for exit, so the child can never block on a full pipe
        async let stdOutText = readText(from: task.standardOutput.fileHandleForReading)
        async let stdErrText = readText(from: task.standardError.fileHandleForReading)

        var status: Int32 = 1
        for await exitStatus in exitStream {
            status = exitStatus
        }

        return (status, await stdOutText, await stdErrText)
    }


    /**
     Read a file handle to EOF on a dedicated thread, and decode the result as UTF-8.

     The blocking read runs on its own `Thread`, not on the Swift Concurrency thread pool,
     so the pool is never starved. Decoding once at the end, rather than per chunk, means
     multi-byte characters split across reads are not lost.

     - Parameters:
        - from: The source file handle.

     - Returns: The decoded text.
     */
    private static func readText(from handle: FileHandle) async -> String {

        await withCheckedContinuation { continuation in
            Thread {
                let data = (try? handle.readToEnd()) ?? Data()
                continuation.resume(returning: String(decoding: data, as: UTF8.self))
            }.start()
        }
    }


#if os(macOS)
    // NOTE This section is macOS only because it currently depends upon `FileHandle.bytes` which
    //      is not yet available from the version of Foundation shipping with Swift on Linux.


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
    public static func runProcessAsyncOLD(app path: String, with args: [String], in directory: URL? = nil) async -> (Int32, String, String) {

        let task = Process()
        task.qualityOfService = .userInitiated
        task.executableURL = URL(fileURLWithPath: path)
        if args.count > 0 { task.arguments = args }

        // FROM 0.7.0
        // Support the addition of a target directory
        if let dir = directory {
            task.currentDirectoryURL = dir
        }
        
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
    private static func readAllChunks(from handle: FileHandle, into append: @escaping (String) async -> Void) async throws {
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
}
