/*
    clicore
    path.swift

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


// MARK: - Path Processing Functions

public struct Path {

    /**
     Convert a partial path to an absolute path.

     - Parameters:
        - relativePath The partial path.

     - Returns: The generated absolute path.
     */
    public static func getFullPath(_ relativePath: String) -> String {

        // Standardise the path as best as we can (this covers most cases)
        var absolutePath = relativePath.standardizedPath

        // Check for a unresolved relative path -- and if it is one, resolve it
        // NOTE This includes raw filenames
        if absolutePath.contains("..") || !absolutePath.hasPrefix("/") {
            absolutePath = processRelativePath(absolutePath)
        }

        // Return the absolute path
        return absolutePath
    }


    /**
     Add the the current working directory to the supplied relative path - and then resolve it.

     - Parameters:
        - relativePath The partial path.

     - Returns: The generated absolute path.
     */
    public static func processRelativePath(_ relativePath: String) -> String {

        let absolutePath = FileManager.default.currentDirectoryPath + "/" + relativePath
        return absolutePath.standardizedPath
    }


    /**
     Check if a path references a directory.

     - Parameters:
        - absolutePath An absolute path to a file or directory.

     - Returns: `true` if the path references an existing directory, otherwise `false`.
     */
    public static func doesPathReferenceDirectory(_ absolutePath: String) -> Bool {

        let fileURL = URL(fileURLWithPath: absolutePath)
        guard let value = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]) else { return false }
        return value.isDirectory ?? false
    }


    /**
     Load a named file's contents into Data.

     DEPRECATED

     - Parameters:
        - filePath: An absolute path to a file.

     - Returns: The file data, or an empty array on error.
     */
    public static func getFileContents(_ filepath: String) -> ArraySlice<UInt8> {

        let fileURL = URL(fileURLWithPath: filepath, isDirectory: false)
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return data.byteSlice
    }


    /**
     Load a named file's contents into Data.

     - Parameters:
        - filePath: An absolute path to a file.

     - Returns: The file data, or an empty array on error.
     */
    public static func getFileContent(_ filePath: String) -> Result<ArraySlice<UInt8>, PathError> {

        guard doesPathReferenceDirectory(filePath) else {
            return .failure(PathError(code: .missingFile))
        }

        let fileURL: URL
        if #available(macOS 13, *) {
            fileURL = URL(filePath: filePath, directoryHint: .notDirectory)
        } else {
            fileURL = URL(fileURLWithPath: filePath, isDirectory: false)
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return .success(data.byteSlice)
        } catch {
            return .failure(PathError(code: .badFileRead, text: error.localizedDescription))
        }
    }
}


/*
 Parent for errors encountered during path operations.
 */
public struct PathError: Error, LocalizedError {

    public var code: PathErrorKind                      = .noError
    public var text: String?                            = nil
    public var errorDescription: String? {
        switch self.code {
            case .noError:
                return nil
            case .missingFile:
                return "File doesn’t exist"
            case .badFileRead:
                if let message = text {
                    return "Could not read file: \(message)"
                }

                return "Could not read file: unknown error"
            case .fileAlreadyExists:
                return "File already exists"
        }
    }
}


/*
 Word file processing error codes.
 NOTE We require raw values for these, for output as stderr codes.
*/
public enum PathErrorKind: Int, Error {

    case noError                                    = 0
    case missingFile                                = 1
    case badFileRead                                = 2
    case fileAlreadyExists                          = 12
}


/*
 This extension property is required by the path functions.
 */
public extension Data {

    // Return data as an array of bytes
    var bytes: [UInt8] {
        return [UInt8](self)
    }


    // Return data as a slice of array of bytes
    var byteSlice: ArraySlice<UInt8> {
        return self.bytes[...]
    }
}


/*
 This extension property is required by the path functions.
 */
public extension String {

    // Return string after path standardisation to expand `~`
    var standardizedPath: String {
        return (self as NSString).standardizingPath
    }
}
